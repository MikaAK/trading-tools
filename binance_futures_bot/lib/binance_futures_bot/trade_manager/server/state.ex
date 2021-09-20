defmodule BinanceFuturesBot.TradeManager.Server.State do
  alias BinanceFuturesBot.TradeManager.Server.State

  @api_module_default BinanceApi

  @enforce_keys [:symbol, :name]
  defstruct [
    :symbol,
    :name,
    :entry_price,
    :final_stop,
    :first_avg,
    :second_avg,
    :take_profit_price,
    :trade_started_at,
    :filled?,
    :order_position,
    api_module: BinanceApi,
    api_opts: [],
    trade_max: 100,
    leverage: 100,
    trade_in_progress?: false,
    taken_first_avg?: false,
    taken_second_avg?: false
  ]

  defmodule OrderPosition do
    defstruct [
      :entry_order,
      :stop_order, :take_profit_order,
      :first_avg_order, :second_avg_order
    ]
  end

  def seed_from_binance(name, symbol, opts) do
    opts = opts
      |> Keyword.put_new(:api_opts, [])
      |> Keyword.put_new(:api_module, @api_module_default)

    api_module = opts[:api_module]
    new_state = struct(
      %State{name: name, symbol: symbol},
      Keyword.take(opts, [:api_opts, :api_module, :trade_max])
    )

    with {:ok, all_orders} <- api_module.futures_all_orders(),
         {:ok, current_position} <- determine_current_position(all_orders) do
      create_state_from_position(new_state, current_position)
    else
      _ -> new_state
    end
  end

  defp determine_current_position(all_orders) do
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
    Enum.reduce(current_position_orders, %OrderPosition{}, fn
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

  defp create_state_from_position(state, %OrderPosition{} = position) do
    %{state |
      order_position: position,
      trade_started_at: DateTime.from_unix!(position.entry_order["time"], :millisecond),
      entry_price: order_price(position.entry_order),
      filled?: order_filled?(position.entry_order),
      final_stop: order_price(position.stop_order),
      first_avg: order_price(position.first_avg_order),
      second_avg: order_price(position.second_avg_order),
      take_profit_price: order_price(position.take_profit_order),
      taken_first_avg?: order_filled?(position.first_avg_order),
      taken_second_avg?: order_filled?(position.second_avg_order),
      trade_in_progress?: true
    }
  end

  defp order_filled?(order), do: order["status"] === "FILLED"

  defp order_price(%{"avg_price" => avg_price, "price" => price}) do
    avg_price = to_float(avg_price)

    if avg_price == 0, do: to_float(price), else: avg_price
  end

  defp order_price(_) do
    0
  end

  defp to_float(float_str), do: float_str |> Float.parse |> elem(0)

  def reset_state(%State{} = state) do
    %{state |
      entry_price: nil,
      final_stop: nil,
      first_avg: nil,
      second_avg: nil,
      take_profit_price: nil,
      order_position: nil,
      trade_started_at: nil,
      trade_in_progress?: false,
      taken_first_avg?: false,
      taken_second_avg?: false
    }
  end
end
