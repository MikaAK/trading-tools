defmodule BinanceFuturesBot.TradeManager.State do
  alias BinanceFuturesBot.TradeManager.State

  defstruct [
    :symbol,
    :entry_price,
    :final_stop,
    :first_avg,
    :second_avg,
    :take_profit_price,
    :trade_started_at,
    api_module: BinanceApi,
    api_opts: [],
    trade_max: 100,
    leverage: 100,
    trade_in_progress?: false,
    taken_first_avg?: false,
    taken_second_avg?: false
  ]

  def seed_from_binance(symbol, opts) do
    case BinanceApi.futures_open_orders_by_symbol(symbol, opts[:api_opts]) do
      {:ok, [order]} -> create_state_from_order(order)
      _ -> struct(%State{}, Keyword.take(opts, [:api_opts, :api_module, :trade_max]))
    end
  end

  defp create_state_from_order(order) do
    IO.inspect order
    %State{
      trade_in_progress?: true
    }
  end
end
