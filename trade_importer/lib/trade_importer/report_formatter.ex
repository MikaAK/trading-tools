defmodule TradeImporter.ReportFormatter do
  def format_for_eyes(data) do
    Enum.flat_map(data, fn
      {_trade_sym, %{completed: [], opened: []}} -> []

      {_trade_sym, %{completed: completed_trades, opened: []}} ->
        Enum.map(completed_trades, &TradeImporter.Entry.deserialize_completed_trade/1)

      {_trade_sym, %{completed: [], opened: opened_trades}} ->
        Enum.map(opened_trades, &TradeImporter.Entry.deserialize_opened_trade/1)

      {_trade_sym, %{completed: completed_trades, opened: opened_trades}} ->
        Enum.map(completed_trades, &TradeImporter.Entry.deserialize_completed_trade/1) ++
        Enum.map(opened_trades, &TradeImporter.Entry.deserialize_opened_trade/1)
    end)
  end
end
