defmodule StockChartVisualizer.DatasetDownloader do
  require Logger

  alias NimbleCSV.RFC4180, as: CSV

  @dataset_path "#{:code.priv_dir(:stock_chart_visualizer)}/datasets"

  def csv_path(symbol), do: "#{@dataset_path}/#{symbol}.csv"

  def load(symbol, start_year \\ 1995) do
    ConCache.get_or_store(:dataset_cache, symbol, fn ->
      with {:ok, csv_string} <- load_csv(symbol, start_year) do
        csv = CSV.parse_string(csv_string)

        {:ok, deserialize_csv(csv)}
      end
    end)
  end

  def load_csv(symbol, start_year) do
    with {:error, %{code: :not_found}} <- load_csv_file(csv_path(symbol)),
         {:ok, csv_string} <- load_csv_from_url(symbol, start_year),
         :ok <- write_file(csv_path(symbol), csv_string) do
      {:ok, csv_string}
    end
  end

  defp load_csv_file(csv_path) do
    case File.read(csv_path) do
      {:error, :enoent} -> {:error, %{code: :not_found}}
      {:ok, csv_string} ->
        Logger.debug("Found existing file for symbol at #{csv_path}")

        {:ok, csv_string}
    end
  end

  defp load_csv_from_url(symbol, start_year) do
    Logger.debug("Requesting #{symbol} data from #{start_year}")

    res = :get
      |> Finch.build(build_url(symbol, start_year))
      |> Finch.request(StockChartVisualizer.Finch)


    case res do
      {:ok, %Finch.Response{body: body, status: 200}} -> {:ok, body}
      {:ok, res} -> {:error, %{code: :internal_server_error, details: res, message: "Unknown error"}}
      {:error, e} -> {:error, %{code: :internal_server_error, details: e, message: "Unknown error"}}
    end
  end

  defp build_url(symbol, start_year) do
    start_period = get_start_period(start_year)
    now = DateTime.to_unix(DateTime.utc_now())

    "https://query1.finance.yahoo.com/v7/finance/download/#{symbol}?period1=#{start_period}&period2=#{now}&interval=1d&events=history&includeAdjustedClose=true"
  end

  defp get_start_period(start_year) do
    start_year
      |> NaiveDateTime.new(1, 1, 0, 0, 0, 0)
      |> elem(1)
      |> DateTime.from_naive!("America/New_York", Tzdata.TimeZoneDatabase)
      |> DateTime.to_unix
  end

  defp write_file(path, contents) do
    with {:error, :enoent} <- File.write(path, contents),
         :ok <- File.mkdir_p(String.replace(path, ~r/[^\/]+$/, "")),
         :ok <- File.touch(path) do
      Logger.debug("Writing stock data #{path}")

      File.write(path, contents)
    end
  end

  defp deserialize_csv(csv) do
    Enum.map(csv, fn [date, open, high, low, close, adj_close, volume] ->
      %{
        date: Date.from_iso8601!(date),
        open: parse_float(open),
        high: parse_float(high),
        low: parse_float(low),
        close: parse_float(close),
        adj_close: parse_float(adj_close),
        volume: volume
      }
    end)
  end

  defp parse_float(float), do: float |> Float.parse |> elem(0)
end
