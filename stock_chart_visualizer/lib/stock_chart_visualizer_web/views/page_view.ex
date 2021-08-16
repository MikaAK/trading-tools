defmodule StockChartVisualizerWeb.PageView do
  use StockChartVisualizerWeb, :view

  alias StockChartVisualizer.SymbolCandle

  def javascript_candles(candles) do
    candles
      |> Enum.map(&serialize_to_chart_data/1)
      |> Jason.encode!()
      |> Phoenix.HTML.raw
  end

  defp serialize_to_chart_data(%SymbolCandle{
    date: date,
    open: open,
    close: close,
    high: high,
    low: low
  }) do
    [date, low, open, close, high]
  end
end
