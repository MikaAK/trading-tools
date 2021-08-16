defmodule AiPredictor.PredictionSaver do
  @folder "#{:code.priv_dir(:ai_predictor)}/predictions"

  def find_prediction(symbol, prediction_date) do
    res = symbol
      |> get_file_name(prediction_date)
      |> File.read

    case res do
      {:ok, value} -> value |> Float.parse |> elem(0)
      {:error, _} -> nil
    end
  end

  def store_prediction(symbol, prediction, prediction_date) do
    symbol |> get_folder_path |> File.mkdir_p!

    symbol
      |> get_file_name(prediction_date)
      |> File.write!(Float.to_charlist(prediction))
  end

  defp get_folder_path(symbol) do
    "#{@folder}/#{String.upcase(symbol)}"
  end

  defp get_file_name(symbol, date) do
    "#{get_folder_path(symbol)}/#{Date.to_string(date)}"
  end
end
