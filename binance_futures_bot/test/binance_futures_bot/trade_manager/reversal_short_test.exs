defmodule BinanceFuturesBot.TradeManager.ReversalShortTest do
  use ExUnit.Case, async: true

  alias BinanceFuturesBot.TradeManager.{ReversalLong, State}

  describe "&run/1" do
    test "returns TRADE_IN_PROGRESS when trade started" do
      state = %State{trade_in_progress?: true}

      assert {{:ok, :trade_in_progress}, state} === ReversalLong.run(state)
    end
  end
end

