defmodule StockChartVisualizer.SymbolCandle do
  @enforce_keys [:symbol, :date, :open, :close, :high, :low]
  defstruct @enforce_keys
end
