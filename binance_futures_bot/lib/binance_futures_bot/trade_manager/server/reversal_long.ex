defmodule BinanceFuturesBot.TradeManager.Server.ReversalLong do
  @moduledoc """
  This module encapsulates the strategy for when we want to
  reverse a falling chart and take a long position
  """

  require Logger

  alias BinanceFuturesBot.TradeManager.Server.State

  def run(%State{trade_in_progress?: true} = state) do
    Logger.info("Trade in progress")

    {{:ok, {:trade_in_progress, state}}, state}
  end

  def run(%State{
    trade_started_at: nil,
    symbol: symbol,
    api_module: api_module,
    api_opts: api_opts
  } = state) do
    Logger.info("Starting reversal long #{inspect state}")

    case api_module.futures_ticker_price(symbol, api_opts) do
      {:ok, %{"price" => price}} ->
        case setup_trade(state, String.to_float(price)) do
          {:ok, state} = res -> {res, state}
          {:error, _} = e -> {e, state}
        end

      {:error, e} = error ->
        Logger.error("Reversal long Error\n#{inspect e}")

        {error, state}
    end
  end

  def setup_trade(%State{leverage: leverage} = state, entry_price) do
    {:ok, %{state |
      entry_price: entry_price,
      final_stop: entry_price - percentage_with_leverage(entry_price, leverage, 0.25),
      first_avg: entry_price - percentage_with_leverage(entry_price, leverage, 0.10),
      second_avg: entry_price - percentage_with_leverage(entry_price, leverage, 0.20),
      take_profit_price: entry_price + percentage_with_leverage(entry_price, leverage, 0.15),
      trade_started_at: DateTime.utc_now(),
      trade_in_progress?: true
    }}
  end

  defp percentage_with_leverage(entry_price, leverage, percentage) do
    entry_price * percentage / leverage
  end
end
