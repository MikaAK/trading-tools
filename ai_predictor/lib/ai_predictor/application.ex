defmodule AiPredictor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @prediction_symbols ["EEM", "QQQ", "SPY", "NVDA", "TSLA", "AAPL", "JETS", "KBE", "PG", "JNJ", "DIS", "XOM", "KO", "VZ", "PFE", "PEP", "MCD"]

  def start(_type, _args) do
    children = [
      {Finch, name: AiPredictor.Finch}
      | prediction_servers()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AiPredictor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp prediction_servers do
    Enum.map(@prediction_symbols, &{AiPredictor.PredictionSaver.Server, &1})
  end
end
