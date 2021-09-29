defmodule BinanceFuturesBot.TradeManager.TradeServer.OrderManager do
  require Logger

  alias BinanceFuturesBot.TradeManager.TradeServer.State

  @fill_retry_delay 1_500

  def filled?(%{"status" => "FILLED"}), do: true
  def filled?(_), do: false

  def close_all_positions_and_orders(%State{} = state) do
    with :ok <- close_all_open_orders(state),
         {:ok, open_position_ids} <- close_all_positions(state) do
      open_position_length = length(open_position_ids)

      if open_position_length > 0 do
        Logger.info("Closed #{open_position_length} open positions")
      end

      State.reset(state)
    else
      {:error, e} ->
        Logger.info("Error closing positions #{inspect e}")

        state

      e -> e
    end
  end

  def close_all_open_orders(%State{symbol: symbol, api_module: api_module, api_opts: api_opts}) do
    with {:ok, _} <- api_module.futures_cancel_open_orders(symbol, api_opts) do
      :ok
    end
  end

  def close_all_positions(%State{api_module: api_module, api_opts: api_opts} = state) do
    with {:ok, all_orders} <- api_module.futures_all_orders(api_opts) do
      all_orders
        |> reject_invalid_and_sort_orders
        |> filter_since_opened_trade
        |> Stream.filter(&filled?/1)
        |> close_positions(state)
    end
  end

  defp close_positions(active_positions, %State{} = state) do
    active_positions
      |> Enum.map(fn order ->
        with {:ok, order} <- limit_close_order(state, order),
             {:ok, _state} <- wait_for_fill_or_cancel(state, order) do
          {:ok, order}
        else
          {:error, :could_not_fill} -> market_close_order(state, order)
        end
      end)
      |> Enum.reduce({:ok, []}, fn
        ({:ok, order}, {:ok, acc}) -> {:ok, [order["order_id"] | acc]}
        ({:error, _} = e, _) -> e
      end)
  end

  defp limit_close_order(
    %State{symbol: symbol, api_module: api_module, api_opts: api_opts, side: side},
    order
  ) do
    order = order["avg_price"]
      |> BinanceApi.Order.Builder.limit(order["executed_qty"], symbol, opposing_side(side))
      |> BinanceApi.Order.Builder.reduce_only

    api_module.futures_place_order(order, api_opts)
  end

  defp market_close_order(
    %State{symbol: symbol, api_module: api_module, api_opts: api_opts, side: side},
    order
  ) do
    order = order["executed_qty"]
      |> BinanceApi.Order.Builder.market(symbol, opposing_side(side))
      |> BinanceApi.Order.Builder.reduce_only

    api_module.futures_place_order(order, api_opts)
  end

  def create_necessary_orders(state) do
    case place_order_and_wait_for_fill(state) do
      {:ok, state} -> place_supporting_orders(state)
      {:error, :could_not_fill} ->
        Logger.warn("[TradeServer.OrderManager] Couldn't get a fill and canceled order")

        {:error, :can_not_place_trade}

      {:error, e} ->
        Logger.warn("[TradeServer.OrderManager] Error placing order #{inspect e}")

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
  } = state) do
    opposing_side = opposing_side(side)
    quantity = amount_to_quantity(entry_price, amount, leverage)

    with {:ok, take_profit_order} <- place_take_profit_order(api_module, api_opts, take_profit_price, quantity, symbol, opposing_side),
         {:ok, stop_order} <- place_stop_order(api_module, api_opts, stop_price, quantity, symbol, opposing_side) do
      {:ok, %{state | order_position: %{state.order_position | stop_order: stop_order, take_profit_order: take_profit_order}}}
    else
      {:error, e} ->
        Logger.error("[TradeServer.OrderManager] Error placing supporting orders #{inspect e}")

        {:ok, close_all_positions_and_orders(state)}
    end
  end

  defp place_take_profit_order(api_module, api_opts, take_profit_price, quantity, symbol, opposing_side) do
    take_profit_price
      |> BinanceApi.Order.Builder.take_profit(quantity, symbol, opposing_side)
      |> api_module.futures_place_order(api_opts)
  end

  defp place_stop_order(api_module, api_opts, stop_price, quantity, symbol, opposing_side) do
    stop_price
      |> BinanceApi.Order.Builder.stop(quantity, symbol, opposing_side)
      |> api_module.futures_place_order(api_opts)
  end

  defp opposing_side("BUY"), do: "SELL"
  defp opposing_side("SELL"), do: "BUY"

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
      (%{"orig_type" => "STOP"} = order, acc_position) ->
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
  } = state) do
    order_params = create_order_params(side, symbol, entry_price, amount, leverage)

    with {:ok, order} <- api_module.futures_place_order(order_params, api_opts),
         {:error, :could_not_fill} <- wait_for_fill_or_cancel(state, order),
         {:ok, _} <- api_module.futures_cancel_order(symbol, order["order_id"], api_opts) do
      {:error, :could_not_fill}
    end
  end

  defp create_order_params(side, symbol, price, amount, leverage) do
    BinanceApi.Order.Builder.limit(
      price,
      amount_to_quantity(price, amount, leverage),
      symbol,
      side
    )
  end

  defp amount_to_quantity(price, amount, leverage), do: Float.round(amount * leverage / price, 3)

  defp wait_for_fill_or_cancel(state, order, retries \\ 5)

  defp wait_for_fill_or_cancel(_state, _order, 0) do
    {:error, :could_not_fill}
  end

  defp wait_for_fill_or_cancel(
    %State{api_module: api_module, api_opts: api_opts, symbol: symbol} = state,
    order,
    retries
  ) do
    case api_module.futures_find_order(symbol, order["order_id"], api_opts) do
      {:ok, %{"status" => "FILLED"}} ->
        Logger.debug("[TradeServer.OrderManager] Order filled #{order["order_id"]}")

        {:ok, %{state | order_position: %{(state.order_position || %State.OrderPosition{}) | entry_order: order}}}

      {:ok, %{"status" => status}} when status in ["PARTIALLY_FILLED", "NEW"] and retries > 0 ->
        Logger.debug("[TradeServer.OrderManager] Order #{order["order_id"]} not filled yet, retries remaining: #{retries - 1}")

        Process.sleep(@fill_retry_delay)
        wait_for_fill_or_cancel(state, order, retries - 1)

      {:error, e} when retries > 0 ->
        Logger.error("[TradeServer.OrderManager] Error waiting for fill check #{inspect e}")

        Process.sleep(@fill_retry_delay)
        wait_for_fill_or_cancel(state, order, retries - 1)

      e -> e
    end
  end
end
