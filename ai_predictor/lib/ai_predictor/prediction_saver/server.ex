defmodule AiPredictor.PredictionSaver.Server do
  require Logger

  use Task, restart: :permanent

  alias AiPredictor.PredictionSaver

  @sleep_interval :timer.hours(8)
  @timezone "America/New_York"

  def start_link(symbol) do
    Task.start(fn ->
      symbol |> String.upcase() |> run()
    end)
  end

  def child_spec(symbol) do
    %{
      id: :"#{String.downcase(symbol)}_prediction_server",
      start: {PredictionSaver.Server, :start_link, [symbol]},
      restart: :permanent
    }
  end

  defp run(symbol) do
    Logger.debug("Running check for #{symbol}...")

    date = DateTime.now!(@timezone)

    cond do
      weekend?(date) ->
        Logger.info("Currently a weekend, running prediction for friday if necessary...")

        date = Date.beginning_of_week(date, :friday)

        predict_and_store_result(symbol, date)

      market_closed?(date) ->
        Logger.info("Market closed, running prediction for next day if necessary...")

        date = date |> DateTime.to_date() |> Date.add(1)

        predict_and_store_result(symbol, date)

      true ->
        Logger.info("Market still open, predicting todays result if necessary...")

        predict_and_store_result(symbol, DateTime.to_date(date))
    end

    Process.sleep(@sleep_interval)

    run(symbol)
  end

  defp weekend?(date) do
    day_of_week = date
      |> DateTime.to_date
      |> Date.day_of_week

    day_of_week in [6, 7]
  end

  defp market_closed?(date) do
    hour = date
      |> DateTime.to_time
      |> Map.get(:hour)

    ended? = hour > 16
    not_started? = hour < 9

    ended? or not_started?
  end

  defp predict_and_store_result(symbol, date) do
    if symbol |> PredictionSaver.find_prediction(date) |> is_nil do
      prediction = AiPredictor.predict_tomorrows_close(symbol)

      PredictionSaver.store_prediction(symbol, prediction, date)

      Logger.info("Prediction for #{symbol} stored...")
    else
      Logger.info("Prediction for #{symbol} already stored...")
    end
  end
end
