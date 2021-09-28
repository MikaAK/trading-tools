defmodule BinanceFuturesBot.TradeManager.TradeServer.State do
  alias BinanceFuturesBot.TradeManager.TradeServer.State

  @enforce_keys [:symbol, :name]
  defstruct [
    :symbol,
    :name,
    :side,
    :entry_price,
    :final_stop,
    :first_avg,
    :second_avg,
    :take_profit_price,
    :trade_started_at,
    :filled?,
    :order_position,
    api_module: BinanceApi,
    api_opts: [],
    trade_max: 100,
    leverage: 100,
    trade_in_progress?: false,
    taken_first_avg?: false,
    taken_second_avg?: false
  ]

  defmodule OrderPosition do
    defstruct [
      :entry_order,
      :stop_order, :take_profit_order,
      :first_avg_order, :second_avg_order
    ]
  end

  def reset(%State{} = state) do
    %{state |
      entry_price: nil,
      final_stop: nil,
      first_avg: nil,
      second_avg: nil,
      take_profit_price: nil,
      order_position: nil,
      trade_started_at: nil,
      trade_in_progress?: false,
      taken_first_avg?: false,
      taken_second_avg?: false
    }
  end
end
