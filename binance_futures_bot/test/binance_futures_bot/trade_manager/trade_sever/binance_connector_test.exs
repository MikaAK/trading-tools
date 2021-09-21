defmodule BinanceFuturesBot.TradeManager.TradeServer.BinanceConnectorTest do
  use ExUnit.Case, async: true

  alias BinanceFuturesBot.TradeManager.TradeServer.{State, BinanceConnector}
  alias BinanceFuturesBot.Support.OrderGenerator

  @symbol "BTCUSDT"

  defmodule MockBinanceApiLongAllOrders do
    @price 10_000
    @quantity 0.01 # $100

    def entry_order do
      OrderGenerator.opened_position_order("BUY", "FILLED", @quantity, @price)
    end

    def first_avg_order do
      OrderGenerator.open_limit_order("BUY", @quantity * 0.25, @price * (1 - 0.1))
    end

    def second_avg_order do
      OrderGenerator.open_limit_order("BUY", @quantity * 0.75, @price * (1 - 0.2))
    end

    def stop_order do
      OrderGenerator.open_stop_market_order("SELL", "NEW", @quantity, @price * (1 - 0.25))
    end

    def take_profit_order do
      OrderGenerator.open_take_profit_order("SELL", "NEW", @quantity, @price * 1.25)
    end

    def futures_all_orders(_ \\ []) do
      {:ok, Enum.reverse([
        entry_order(),
        first_avg_order(), second_avg_order(),
        stop_order(), take_profit_order()
      ])}
    end
  end

  defmodule MockBinanceApiTwoAvgAllOrders do
    @price 10_000
    @quantity 0.01 # $100

    def entry_order(quantity \\ @quantity) do
      OrderGenerator.opened_position_order("BUY", "FILLED", quantity, @price)
    end

    def first_avg_order(quantity \\ @quantity) do
      OrderGenerator.opened_position_order("BUY", "FILLED", quantity * 0.25, @price * (1 - 0.1))
    end

    def second_avg_order(quantity \\ @quantity) do
      OrderGenerator.opened_position_order("BUY", "FILLED", quantity * 0.75, @price * (1 - 0.2))
    end

    def stop_order(quantity \\ @quantity) do
      OrderGenerator.open_stop_market_order("SELL", "NEW", quantity, @price * (1 - 0.25))
    end

    def take_profit_order(status, quantity \\ @quantity) do
      OrderGenerator.open_take_profit_order("SELL", status, quantity, @price * 1.25)
    end

    def futures_all_orders(_ \\ []) do
      {:ok, Enum.reverse([
        entry_order(10),
        first_avg_order(20), second_avg_order(10),
        stop_order(30), take_profit_order("FILLED", 200),

        entry_order(),
        first_avg_order(), second_avg_order(),
        stop_order(), take_profit_order("NEW")
      ])}
    end
  end

  defmodule MockBinanceApiOneAvgAllOrders do
    @price 10_000
    @quantity 0.01 # $100

    def entry_order do
      OrderGenerator.opened_position_order("BUY", "FILLED", @quantity, @price)
    end

    def first_avg_order do
      OrderGenerator.opened_position_order("BUY", "FILLED", @quantity * 0.25, @price * (1 - 0.1))
    end

    def second_avg_order do
      OrderGenerator.open_limit_order("BUY", @quantity * 0.75, @price * (1 - 0.2))
    end

    def stop_order do
      OrderGenerator.open_stop_market_order("SELL", "NEW", @quantity, @price * (1 - 0.25))
    end

    def take_profit_order do
      OrderGenerator.open_take_profit_order("SELL", "NEW", @quantity, @price * 1.25)
    end

    def futures_all_orders(_ \\ []) do
      {:ok, Enum.reverse([
        entry_order(),
        first_avg_order(), second_avg_order(),
        stop_order(), take_profit_order()
      ])}
    end
  end

  describe "&seed_from_api/3" do
    test "uses api module to get all open order and all orders to create position and entry seed" do
      state = BinanceConnector.seed_from_api(:test, "BTCUSDT", api_module: MockBinanceApiLongAllOrders)

      assert %State{
        order_position: %State.OrderPosition{} = position,
        entry_price: 10_000.00,
        filled?: true,
        final_stop: 7_500.00,
        first_avg: 9_000.00,
        second_avg: 8_000.00,
        take_profit_price: 12_500.00,
        taken_first_avg?: false,
        taken_second_avg?: false,
        trade_in_progress?: true
      } = state

      assert order_equal?(position.entry_order, MockBinanceApiLongAllOrders.entry_order())
      assert order_equal?(position.first_avg_order, MockBinanceApiLongAllOrders.first_avg_order())
      assert order_equal?(position.stop_order, MockBinanceApiLongAllOrders.stop_order())

      assert order_equal?(
        position.second_avg_order,
        MockBinanceApiLongAllOrders.second_avg_order()
      )

      assert order_equal?(
        position.take_profit_order,
        MockBinanceApiLongAllOrders.take_profit_order()
      )
    end

    test "returns proper results for when one average is taken" do
      state = BinanceConnector.seed_from_api(:test, "BTCUSDT", api_module: MockBinanceApiOneAvgAllOrders)

      assert %State{
        order_position: %State.OrderPosition{} = position,
        entry_price: 10_000.00,
        filled?: true,
        final_stop: 7_500.00,
        first_avg: 9_000.00,
        second_avg: 8_000.00,
        take_profit_price: 12_500.00,
        taken_first_avg?: true,
        taken_second_avg?: false,
        trade_in_progress?: true
      } = state

      assert order_equal?(position.stop_order, MockBinanceApiOneAvgAllOrders.stop_order())
      assert order_equal?(position.entry_order, MockBinanceApiOneAvgAllOrders.entry_order())

      assert order_equal?(
        position.first_avg_order,
        MockBinanceApiOneAvgAllOrders.first_avg_order()
      )

      assert order_equal?(
        position.second_avg_order,
        MockBinanceApiOneAvgAllOrders.second_avg_order()
      )

      assert order_equal?(
        position.take_profit_order,
        MockBinanceApiOneAvgAllOrders.take_profit_order()
      )
    end

    test "properly filters a long order list" do
      state = BinanceConnector.seed_from_api(:test, "BTCUSDT", api_module: MockBinanceApiTwoAvgAllOrders)

      assert %State{
        order_position: %State.OrderPosition{} = position,
        entry_price: 10_000.00,
        filled?: true,
        final_stop: 7_500.00,
        first_avg: 9_000.00,
        second_avg: 8_000.00,
        take_profit_price: 12_500.00,
        taken_first_avg?: true,
        taken_second_avg?: true,
        trade_in_progress?: true
      } = state

      assert order_equal?(position.entry_order, MockBinanceApiTwoAvgAllOrders.entry_order())
      assert order_equal?(position.stop_order, MockBinanceApiTwoAvgAllOrders.stop_order())

      assert order_equal?(
        position.first_avg_order,
        MockBinanceApiTwoAvgAllOrders.first_avg_order()
      )

      assert order_equal?(
        position.second_avg_order,
        MockBinanceApiTwoAvgAllOrders.second_avg_order()
      )

      assert order_equal?(
        position.take_profit_order,
        MockBinanceApiTwoAvgAllOrders.take_profit_order("NEW")
      )
    end
  end

  describe "&checkup_on_trade/1" do
    test "uses api_module to checkup on trade and update state if needed" do
      state = %State{
        name: :mika_btc_usdt,
        symbol: @symbol,
        api_module: MockBinanceApiOneAvgAllOrders,
        entry_price: 10_000.00,
        filled?: true,
        final_stop: 7_500.00,
        first_avg: 9_000.00,
        second_avg: 8_000.00,
        take_profit_price: 12_500.00,
        taken_first_avg?: false,
        taken_second_avg?: false,
        trade_in_progress?: true,
        order_position: %State.OrderPosition{
          stop_order: MockBinanceApiOneAvgAllOrders.stop_order(),
          entry_order: MockBinanceApiOneAvgAllOrders.entry_order(),
          first_avg_order: %{MockBinanceApiOneAvgAllOrders.first_avg_order() | "status" => "NEW"},
          second_avg_order: MockBinanceApiOneAvgAllOrders.second_avg_order(),
          take_profit_order: MockBinanceApiOneAvgAllOrders.take_profit_order()
        }
      }

      BinanceConnector.checkup_on_trade(state)
    end
  end

  defp order_equal?(order_a, order_b) do
    Map.delete(order_a, "time") === Map.delete(order_b, "time")
  end
end
