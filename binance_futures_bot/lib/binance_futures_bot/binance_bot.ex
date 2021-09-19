defmodule BinanceFuturesBot.BinanceBot do
  @events [
    "BOLLINGER_CROSS_OVER",
    "BOLLINGER_CROSS_UNDER",
    "BOLLINGER_RETURN_LOWER",
    "BOLLINGER_RETURN_UPPER"
  ]

  def events, do: @events

  def handle_event(event_type, event_data) do

  end
end
