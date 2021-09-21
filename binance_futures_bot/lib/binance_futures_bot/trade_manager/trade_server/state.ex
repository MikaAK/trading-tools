defmodule BinanceFuturesBot.TradeManager.TradeServer.State do
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
end
