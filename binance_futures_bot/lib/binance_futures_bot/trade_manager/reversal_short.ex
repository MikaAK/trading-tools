defmodule BinanceFuturesBot.TradeManager.ReversalShort do
  @moduledoc """
  This module encapsulates the strategy for when we want to
  reverse a rising chart and take a short position
  """

  require Logger

  alias BinanceFuturesBot.TradeManager.State

  def run(%State{trade_in_progress?: true} = state) do
    {{:ok, :trade_in_progress}, state}
  end

  def run(%State{
    trade_started_at: nil,
    symbol: symbol,
    api_module: api_module,
    api_opts: api_opts
  } = state) do
    Logger.info("Starting reversal short #{inspect state}")

    case api_module.futures_ticker_price(symbol, api_opts) do
      {:ok, %{"price" => price}} ->
        state = setup_trade(state, String.to_float(price))

        {{:ok, state}, state}

      {:error, e} ->
        Logger.error("Reversal short Error\n#{inspect e}")

        {{:ok, state}, state}
    end
  end

  def setup_trade(%State{leverage: leverage} = state, entry_price) do
    %{state |
      entry_price: entry_price,
      final_stop: entry_price + percentage_with_leverage(entry_price, leverage, 0.25),
      first_avg: entry_price + percentage_with_leverage(entry_price, leverage, 0.10),
      second_avg: entry_price + percentage_with_leverage(entry_price, leverage, 0.20),
      take_profit_price: entry_price - percentage_with_leverage(entry_price, leverage, 0.15),
      trade_started_at: DateTime.utc_now(),
      trade_in_progress?: true
    }
  end

  defp percentage_with_leverage(entry_price, leverage, percentage) do
    entry_price * percentage / leverage
  end
end
