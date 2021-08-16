defmodule TradeImporter.MixProject do
  use Mix.Project

  def project do
    [
      app: :trade_importer,
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
      mod: {TradeImporter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_csv, "~> 1.0"},
      {:decimal, "~> 2.0"}
    ]
  end
end
