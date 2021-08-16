defmodule StockChartVisualizerWeb.PageController do
  use StockChartVisualizerWeb, :controller

  alias StockChartVisualizer.{SymbolCandle, DatasetDownloader}

  @date_format "%a, %B %d %Y"

  def show(conn, %{
    "symbol" => symbol,
    "year" => year,
    "month" => month,
    "day" => day
  }) do
    date = deserialize_date(year, month, day)

    with {:ok, data} <- DatasetDownloader.load(symbol) do
      render(conn, "show.html",
        symbol: symbol,
        date: Calendar.strftime(date, @date_format),
        candles: data_from_prior_month(symbol, data, date)
      )
    end
  end

  defp deserialize_date(year, month, day) do
    Date.new!(
      String.to_integer(year),
      String.to_integer(month),
      String.to_integer(day)
    )
  end

  defp data_from_prior_month(symbol, data, date) do
    start_date = Date.add(date, -39)

    data
      |> Stream.filter(&between_dates?(&1.date, start_date, date))
      |> Enum.to_list
      |> Enum.map(&%SymbolCandle{
        symbol: symbol,
        date: &1.date,
        open: &1.open,
        close: &1.close,
        high: &1.high,
        low: &1.low
      })
  end

  defp between_dates?(date, start_date, end_date) do
    Date.compare(date, start_date) in [:gt, :eq] and
    Date.compare(date, end_date) in [:lt, :eq]
  end
end
