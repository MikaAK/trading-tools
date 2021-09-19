defmodule BinanceFuturesBot.BinanceBot do
  @events [
    "BOLLINGER_CROSS_OVER",
    "BOLLINGER_CROSS_UNDER",
    "BOLLINGER_RETURN_LOWER",
    "BOLLINGER_RETURN_UPPER"
  ]

  def events, do: @events

  def handle_event("BOLLINGER_CROSS_UNDER", event_data) do

  end

  def handle_event("BOLLINGER_CROSS_OVER", event_data) do

  end

  def handle_event("BOLLINGER_RETURN_LOWER", event_data) do

  end

  def handle_event("BOLLINGER_RETURN_UPPER", event_data) do

  end
end
