defmodule BinanceFuturesBot.TradeManager.TradeServer.ReversalShort do
  @moduledoc """
  This module encapsulates the strategy for when we want to
  reverse a rising chart and take a short position
  """

  require Logger

  alias BinanceFuturesBot.TradeManager.TradeServer.{State, OrderManager}

  def run(%State{trade_in_progress?: true} = state) do
    {{:ok, {:trade_in_progress, state}}, state}
  end

  def run(%State{
    trade_started_at: nil,
    symbol: symbol,
    api_module: api_module,
    api_opts: api_opts
  } = state) do
    Logger.info("Starting reversal short for #{state.name}")

    case api_module.futures_ticker_price(symbol, api_opts) do
      {:ok, %{"price" => price}} ->
        case setup_trade(state, String.to_float(price)) do
          {:ok, state} = res -> {res, state}
          {:error, _} = e -> {e, state}
        end

      {:error, e} = error ->
        Logger.error("Reversal short Error\n#{inspect e}")

        {error, state}
    end
  end

  def setup_trade(%State{leverage: leverage} = state, entry_price) do
    new_state = %{state |
      side: "SELL",
      entry_price: entry_price,
      final_stop: entry_price + percentage_with_leverage(entry_price, leverage, 0.20),
      first_avg: entry_price + percentage_with_leverage(entry_price, leverage, 0.10),
      second_avg: entry_price + percentage_with_leverage(entry_price, leverage, 0.20),
      take_profit_price: entry_price - percentage_with_leverage(entry_price, leverage, 0.25),
      trade_started_at: DateTime.utc_now(),
      trade_in_progress?: true
    }

    with {:error, :can_not_place_trade} <- OrderManager.create_necessary_orders(new_state) do
      {:ok, state}
    end
  end

  defp percentage_with_leverage(entry_price, leverage, percentage) do
    Float.round(entry_price * percentage / leverage, 2)
  end
end
