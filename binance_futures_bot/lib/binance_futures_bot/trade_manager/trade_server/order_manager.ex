defmodule BinanceFuturesBot.TradeManager.TradeServer.OrderManager do
  require Logger

  alias BinanceFuturesBot.TradeManager.TradeServer.State

  @fill_retry_delay 1_500

  def filled?(%{"status" => "FILLED"}), do: true
  def filled?(_), do: false

  def close_all_positions_and_orders(%State{} = state) do
    with {:ok, open_order_ids} <- close_all_open_orders(state),
         {:ok, open_position_ids} <- close_all_positions(state) do
      open_order_length = length(open_order_ids)
      open_position_length = length(open_position_ids)

      if open_position_length > 0 do
        Logger.info("Closed #{open_position_length} open positions")
      end

      if open_order_length > 0 do
        Logger.info("Closed #{open_order_length} open orders")
      end

      State.reset(state)
    else
      _ -> state
    end
  end

  def close_all_open_orders(%State{symbol: symbol, api_module: api_module, api_opts: api_opts}) do
    with {:ok, _} <- api_module.futures_cancel_open_orders(symbol, api_opts) do
      :ok
    end
  end

  def close_all_positions(%State{symbol: symbol, api_module: api_module, api_opts: api_opts}) do
    with {:ok, all_orders} <- api_module.futures_all_orders(api_opts) do
      open_position_ids = all_orders
        |> reject_invalid_and_sort_orders
        |> filter_since_opened_trade
        |> Stream.filter(&filled?/1)
        |> Enum.map(&(&1["order_id"]))

      api_module.futures_cancel_orders(symbol, open_position_ids, api_opts)
    end
  end

  def create_necessary_orders(state) do
    case place_order_and_wait_for_fill(state) do
      {:ok, state} -> place_supporting_orders(state)
      {:error, :could_not_fill} ->
        Logger.warn("[TradeServer.ReversalLong] Couldn't get a fill and canceled order")

        {:error, :can_not_place_trade}

      {:error, e} ->
        Logger.warn("[TradeServer.ReversalLong] Error placing order #{inspect e}")

        {:error, :can_not_place_trade}
    end
  end

  defp place_supporting_orders(%State{
    api_module: api_module,
    api_opts: api_opts,
    symbol: symbol,
    side: side,
    leverage: leverage,
    trade_max: amount,
    entry_price: entry_price,
    final_stop: stop_price,
    take_profit_price: take_profit_price
  }) do
    opposing_side = if side === "LONG", do: "SHORT", else: "LONG"
    quantity = amount_to_quantity(entry_price, amount, leverage)

    api_module.futures_place_orders([
      BinanceApi.Order.Builder.take_profit(take_profit_price, quantity, symbol, opposing_side),
      BinanceApi.Order.Builder.stop(stop_price, quantity, symbol, opposing_side),
    ], api_opts)
  end

  def determine_current_position(all_orders) do
    current_position_orders = all_orders
      |> reject_invalid_and_sort_orders
      |> filter_since_opened_trade

    if Enum.any?(current_position_orders) do
      {:ok, convert_orders_to_order_position(current_position_orders)}
    else
      {:error, :no_positions_open}
    end
  end

  defp convert_orders_to_order_position(current_position_orders) do
    Enum.reduce(current_position_orders, %State.OrderPosition{}, fn
      (%{"orig_type" => "STOP_MARKET"} = order, acc_position) ->
        %{acc_position | stop_order: order}

      (%{"orig_type" => "TAKE_PROFIT"} = order, acc_position) ->
        %{acc_position | take_profit_order: order}

      (%{"orig_type" => "LIMIT"} = order, %{entry_order: nil} = acc_position) ->
        %{acc_position | entry_order: order}

      (
        %{"orig_type" => "LIMIT", "side" => "SELL"} = order,
        %{first_avg_order: nil} = acc_position
      ) ->
        {first_avg_order, entry_order} = split_by_greater_order(acc_position.entry_order, order)

        %{acc_position | entry_order: entry_order, first_avg_order: first_avg_order}


      (
        %{"orig_type" => "LIMIT", "side" => "SELL"} = order,
        %{second_avg_order: nil} = acc_position
      ) ->
        {first_avg_order, entry_order} = split_by_greater_order(acc_position.entry_order, order)
        {second_avg_order, first_avg_order} = split_by_greater_order(acc_position.first_avg_order, first_avg_order)

        %{acc_position |
          entry_order: entry_order,
          first_avg_order: first_avg_order,
          second_avg_order: second_avg_order
        }

      (
        %{"orig_type" => "LIMIT", "side" => "BUY"} = order,
        %{first_avg_order: nil} = acc_position
      ) ->
        {entry_order, first_avg_order} = split_by_greater_order(acc_position.entry_order, order)

        %{acc_position | entry_order: entry_order, first_avg_order: first_avg_order}


      (
        %{"orig_type" => "LIMIT", "side" => "BUY"} = order,
        %{second_avg_order: nil} = acc_position
      ) ->
        {entry_order, first_avg_order} = split_by_greater_order(acc_position.entry_order, order)
        {first_avg_order, second_avg_order} = split_by_greater_order(acc_position.first_avg_order, first_avg_order)

        %{acc_position |
          entry_order: entry_order,
          first_avg_order: first_avg_order,
          second_avg_order: second_avg_order
        }

      (_, acc_position) -> acc_position
    end)
  end

  defp split_by_greater_order(order_a, order_b) do
    if order_price(order_a) > order_price(order_b) do
      {order_a, order_b}
    else
      {order_b, order_a}
    end
  end

  defp reject_invalid_and_sort_orders(all_orders) do
    all_orders
      |> Stream.reject(&(&1["status"] in ["CANCELED", "EXPIRED"]))
      |> Enum.sort_by(&(&1["time"]), :desc)
  end

  def filter_since_opened_trade(orders) do
    Enum.take_while(orders, &(not (&1["reduce_only"] and &1["status"] === "FILLED")))
  end

  def order_price(%{"avg_price" => avg_price, "price" => price}) do
    avg_price = to_float(avg_price)

    if avg_price == 0, do: to_float(price), else: avg_price
  end

  def order_price(_) do
    0
  end

  defp to_float(float_str), do: float_str |> Float.parse |> elem(0)

  defp place_order_and_wait_for_fill(%State{
    api_module: api_module,
    api_opts: api_opts,
    symbol: symbol,
    entry_price: entry_price,
    side: side,
    leverage: leverage,
    trade_max: amount
  }) do
    order_params = create_order_params(side, symbol, entry_price, amount, leverage)

    with {:ok, order} <- api_module.futures_place_order(order_params, api_opts),
         {:error, :could_not_fill} <- wait_for_fill_or_cancel(api_module, order),
         {:ok, _} <- api_module.cancel_order(order["order_id"], api_opts) do
      {:error, :could_not_fill}
    end
  end

  defp create_order_params(side, symbol, price, amount, leverage) do
    BinanceApi.Order.Builder.limit_order(
      price,
      amount_to_quantity(price, amount, leverage),
      symbol,
      side
    )
  end

  defp amount_to_quantity(price, amount, leverage), do: amount * leverage / price

  defp wait_for_fill_or_cancel(api_module, order, retries \\ 5)

  defp wait_for_fill_or_cancel(_api_module, _order, 0) do
    {:error, :could_not_fill}
  end

  defp wait_for_fill_or_cancel(api_module, order, retries) do
    case api_module.find_order(order) do
      {:ok, %{"status" => "FILLED"}} ->
        Logger.debug("[TradeServer.ReversalLong] Order filled #{order["order_id"]}")

        {:ok, order}

      {:ok, %{"status" => "NEW"}} when retries > 0 ->
        Logger.debug("[TradeServer.ReversalLong] Order #{order["order_id"]} not filled yet, retries remaining: #{retries - 1}")

        Process.sleep(@fill_retry_delay)
        wait_for_fill_or_cancel(order, retries - 1)

      {:error, e} when retries > 0 ->
        Logger.error("[TradeServer.ReversalLong] Error waiting for fill check #{inspect e}")

        Process.sleep(@fill_retry_delay)
        wait_for_fill_or_cancel(order, retries - 1)

      e -> e
    end
  end
end
