defmodule BinanceFuturesBot.TradeManager.ReversalLong do
  require Logger

  alias BinanceFuturesBot.TradeManager.State

  def run(%State{trade_in_progress?: true} = state) do
    {{:ok, :trade_in_progress}, state}
  end

  def run(%State{} = state) do
    Logger.info("TRIGGERED REVERSAL LONG #{inspect state}")
  end
end
