defmodule BinanceFuturesBot.TradeManager.TradeServer.BinanceConnector do
  require Logger

  alias BinanceFuturesBot.TradeManager.TradeServer.{State, OrderManager}

  @api_module_default BinanceApi

  def seed_from_api(name, symbol, opts) do
    opts = opts
      |> Keyword.put_new(:api_opts, [])
      |> Keyword.put_new(:api_module, @api_module_default)

    api_module = opts[:api_module]

    new_state = struct(
      %State{name: name, symbol: symbol},
      Keyword.take(opts, [:api_opts, :api_module, :trade_max])
    )

    with {:ok, all_orders} <- api_module.futures_all_orders(opts[:api_opts]),
         {:ok, current_position} <- OrderManager.determine_current_position(all_orders) do
      create_state_from_position(new_state, current_position)
    else
      {:error, e} ->
        Logger.error("[TradeServer.State.seed_from_api] Error #{inspect e}")

        new_state
    end
  end

  defp create_state_from_position(state, %State.OrderPosition{} = position) do
    %{state |
      order_position: position,
      side: position.entry_order["side"],
      trade_started_at: DateTime.from_unix!(position.entry_order["time"], :millisecond),
      entry_price: OrderManager.order_price(position.entry_order),
      filled?: order_filled?(position.entry_order),
      final_stop: OrderManager.order_price(position.stop_order),
      first_avg: OrderManager.order_price(position.first_avg_order),
      second_avg: OrderManager.order_price(position.second_avg_order),
      take_profit_price: OrderManager.order_price(position.take_profit_order),
      taken_first_avg?: order_filled?(position.first_avg_order),
      taken_second_avg?: order_filled?(position.second_avg_order),
      trade_in_progress?: true
    }
  end

  defp order_filled?(order), do: order["status"] === "FILLED"

  def checkup_on_trade(%State{trade_in_progress?: false} = state) do
    # Logger.debug("[TradeServer.BinanceConnector] No trade in progress...")

    state
  end

  def checkup_on_trade(%State{api_module: api_module, api_opts: api_opts} = state) do
    case api_module.futures_all_orders(api_opts) do
      {:ok, all_orders} -> check_trades_completed(state, all_orders)

      {:error, e} ->
        Logger.error("[TradeServer.BinanceConnector] Error fetching orders for checkup #{inspect e}")

        state
    end
  end

  defp check_trades_completed(
    %State{order_position: %State.OrderPosition{} = order_position} = state,
    all_trades
  ) do
    updated_order_positions = maybe_update_position_orders(order_position, all_trades)
    new_state = create_state_from_position(state, updated_order_positions)

    if take_profit_or_stop_filled?(new_state) do
      OrderManager.close_all_positions_and_orders(new_state)
    else
      new_state
    end
  end

  defp take_profit_or_stop_filled?(state) do
    take_profit_filled? = OrderManager.filled?(state.order_position.take_profit_order)
    stop_filled? = OrderManager.filled?(state.order_position.stop_order)

    cond do
      take_profit_filled? -> Logger.info("Trade Won")
      stop_filled? -> Logger.info("Trade Stopped Out")
      true -> true
    end

    take_profit_filled? or stop_filled?
  end

  defp maybe_update_position_orders(order_positions, all_trades) do
    all_trades_by_id = Enum.into(all_trades, %{}, &{&1["order_id"], &1})

    order_positions
      |> maybe_update_order(:entry_order, all_trades_by_id)
      |> maybe_update_order(:first_avg_order, all_trades_by_id)
      |> maybe_update_order(:second_avg_order, all_trades_by_id)
      |> maybe_update_order(:stop_order, all_trades_by_id)
      |> maybe_update_order(:take_profit_order, all_trades_by_id)
  end

  defp maybe_update_order(order_positions, order_key, all_trades_by_id) do
    order_position = Map.get(order_positions, order_key)

    case all_trades_by_id[order_position["order_id"]] do
      ^order_position -> order_positions

      updated_order ->
        Logger.debug("[TradeServer.BinanceConnector] Position #{order_key} updated\n#{humanize_order(updated_order)}")

        Map.put(order_positions, order_key, updated_order)
    end
  end

  defp humanize_order(order) do
    """
    Order ID: #{order["order_id"]}
    Time: #{humanize_time(order["time"] || order["update_time"])}
    Type: #{order["type"]}
    Avg Fill Price: #{order["avg_price"]}
    Asked Price: #{order["price"]}
    Executed Quantity: #{order["executed_qty"]}
    Original Quantity: #{order["orig_qty"]}
    """
  end

  defp humanize_time(nil) do
    ""
  end

  defp humanize_time(unix_time) do
    Calendar.strftime(DateTime.from_unix!(unix_time, :millisecond), "%c")
  end
end
