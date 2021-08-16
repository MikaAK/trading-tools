defmodule AiPredictor.MixProject do
  use Mix.Project

  def project do
    [
      app: :ai_predictor,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AiPredictor.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:erlport, "~> 0.10"},
      {:finch, "~> 0.8"},
      {:tzdata, "~> 1.1"},
      {:jason, "~> 1.1"},
      {:nimble_csv, "~> 1.1"},

      {:kino, "~> 0.3"},
      {:vega_lite, "~> 0.1"}
    ]
  end
end
