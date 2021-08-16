defmodule AiPredictor do
  def predict_tomorrows_close(symbol) do
    with {:ok, _} <- AiPredictor.DatasetDownloader.load(symbol),
         {:ok, pid} <- AiPredictor.Model.start_link() do
      AiPredictor.Model.predict_tomorrows_close(pid, symbol)
    end
  end
end
