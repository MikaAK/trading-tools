defmodule BinanceFuturesBot.TradeManager.State do
  alias BinanceFuturesBot.TradeManager.State

  defstruct [
    :symbol,
    :entry,
    :final_stop,
    :first_avg,
    :second_avg,
    api_opts: [],
    trade_in_progress?: false
  ]

  def seed_from_binance(symbol, opts) do
    case BinanceApi.futures_open_orders_by_symbol(symbol, opts) do
      {:ok, [order]} -> create_state_from_order(order)
      _ -> %State{}
    end
  end

  defp create_state_from_order(order) do
    IO.inspect order
    %State{}
  end
end
