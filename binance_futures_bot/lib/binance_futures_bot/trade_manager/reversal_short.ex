defmodule BinanceFuturesBot.TradeManager.ReversalShort do
  require Logger

  alias BinanceFuturesBot.TradeManager.State

  def run(%State{trade_in_progress?: true} = state) do
    {{:ok, "TRADE_IN_PROGRESS"}, state}
  end

  def run(%State{} = state) do
    Logger.info("TRIGGERED REVERSAL SHORT #{inspect state}")
  end
end
