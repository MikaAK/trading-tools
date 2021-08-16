defmodule ElonBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :elon_bot,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      default_release: :elon_bot,
      releases: [
        elon_bot: [
          include_executables_for: [:unix],
          steps: [:assemble, :tar],
          applications: [elon_bot: :permanent, runtime_tools: :permanent]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ElonBot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.6"},
      {:jason, "~> 1.2"},
      {:html_entities, "~> 0.5"}
    ]
  end
end
