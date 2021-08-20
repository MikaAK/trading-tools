Application.put_env(:hound, :driver, "chrome_driver")
Application.put_env(:hound, :browser, "chrome_headless")

Mix.install([:hound, :poolboy])

generation_symbols = ["SPY"]
start_year = 1995
today = Date.utc_today()

dates = for year <- start_year..today.year, month <- 1..12, day <- 1..(Date.new!(year, month, 1) |> Date.end_of_month |> Map.get(:day)) do
  Date.new!(year, month, day)
end

Application.ensure_all_started(:hound)

defmodule HoundSession do
  use GenServer

  alias Hound.Helpers.{Navigation, Screenshot}
  require Logger

  @path "../stock-dataset"

  def start_link(_ \\ []) do
    GenServer.start_link(HoundSession, nil, [])
  end

  def init(_) do
    {:ok, Hound.start_session()}
  end

  def navigate_and_capture(pid, symbol, date) do
    GenServer.call(pid, {:navigate_and_capture, symbol, date}, :infinity)
  end

  def handle_call({:navigate_and_capture, symbol, date}, _, session_id) do
    date_string = Date.to_iso8601(date)
    date_path = "#{@path}/#{symbol}/#{date_string}.png"

    if File.exists?(date_path) do
      Logger.debug("File exists for #{symbol} - #{date_string}")
    else
      save_screenshot_from_web(symbol, date_string, date_path)
    end

    {:reply, :ok, session_id}
  end

  defp save_screenshot_from_web(symbol, date_string, date_path) do
    File.mkdir_p!("#{@path}/#{symbol}")

    Logger.debug("Navigating to page for #{symbol} for #{date_string}")

    Navigation.navigate_to(stock_url(symbol, date_string))
    Screenshot.take_screenshot(date_path)
  end

  defp stock_url(symbol, <<year::binary-size(4), "-", month::binary-size(2), "-", day::binary-size(2)>>) do
    "http://localhost:4000/#{symbol}/#{year}/#{month}/#{day}"
  end
end

:poolboy.start_link(
  name: {:local, :hound_session},
  worker_module: HoundSession,
  size: 20
)

Enum.each(generation_symbols, fn symbol ->
  dates
    |> Stream.reject(&(Date.day_of_week(&1) in [6, 7]))
    |> Task.async_stream(fn date ->
      :poolboy.transaction(:hound_session, &HoundSession.navigate_and_capture(&1, symbol, date))
    end, max_concurrency: 20, timeout: :infinity)
    |> Stream.run
end)
