defmodule BinanceFuturesBot.TradeManager.Server.State do
  alias BinanceFuturesBot.TradeManager.Server.State

  @enforce_keys [:symbol, :name]
  defstruct [
    :symbol,
    :name,
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

  def seed_from_binance(name, symbol, opts) do
    case BinanceApi.futures_open_orders_by_symbol(symbol, opts[:api_opts]) do
      {:ok, [order]} -> create_state_from_order(name, symbol, order)
      _ -> struct(%State{name: name, symbol: symbol}, Keyword.take(opts, [:api_opts, :api_module, :trade_max]))
    end
  end

  defp create_state_from_order(name, symbol, order) do
    IO.inspect order
    %State{
      name: name,
      symbol: symbol,
      trade_in_progress?: true
    }
  end

  def reset_state(%State{} = state) do
    %{state |
      entry_price: nil,
      final_stop: nil,
      first_avg: nil,
      second_avg: nil,
      take_profit_price: nil,
      trade_started_at: nil,
      trade_in_progress?: false,
      taken_first_avg?: false,
      taken_second_avg?: false
    }
  end
end
