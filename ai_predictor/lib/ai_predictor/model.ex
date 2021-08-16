defmodule AiPredictor.Model do
  @default_opts [
    path: "#{:code.priv_dir(:ai_predictor)}/python",
    python: 'python3'
  ]

  def start_link(opts \\ []) do
    opts = @default_opts |> Keyword.merge(opts) |> Keyword.update!(:path, &to_charlist/1)

    :python.start_link(python_path: opts[:path], python: opts[:python])
  end

  def predict_tomorrows_close(pid \\ @default_opts[:name], symbol) do
    res = pid
      |> :python.call(:arima_model, :predict, [symbol])
      |> to_string
      |> Float.parse
      |> elem(0)

    :python.stop(pid)

    res
  end
end
