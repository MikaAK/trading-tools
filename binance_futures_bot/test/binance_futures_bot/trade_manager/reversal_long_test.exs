defmodule BinanceFuturesBot.TradeManager.ReversalLongTest do
  use ExUnit.Case, async: true

  alias BinanceFuturesBotWeb.Support.DateTimeHelpers
  alias BinanceFuturesBot.TradeManager.{ReversalLong, State}

  @symbol "BTCUSDT"
  @entry_price 1_000.00

  defmodule BinanceApiMock do
    @entry_price 1_000.00

    def futures_ticker_price(_, _) do
      {:ok, %{"price" => to_string(@entry_price)}}
    end
  end

  describe "&run/1" do
    test "returns TRADE_IN_PROGRESS when trade started" do
      state = %State{trade_in_progress?: true}

      assert {{:ok, :trade_in_progress}, state} === ReversalLong.run(state)
    end

    test "calculates state for trade with the current ticker price" do
      state = %State{
        symbol: @symbol,
        api_module: BinanceApiMock,
        leverage: 10
      }

      assert {{:ok, %State{
        symbol: @symbol,
        entry_price: @entry_price,
        final_stop: 975.00,
        first_avg: 990.00,
        second_avg: 980.00,
        take_profit_price: 1015.00,
        trade_started_at: trade_started_at,
        trade_in_progress?: true
      }}, %State{}} = ReversalLong.run(state)

      assert DateTimeHelpers.within_second?(DateTime.utc_now(), trade_started_at)
    end
  end
end
