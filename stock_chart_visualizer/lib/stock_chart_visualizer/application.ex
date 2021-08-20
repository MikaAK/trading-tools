defmodule StockChartVisualizer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Finch, name: StockChartVisualizer.Finch},
      # Start the Telemetry supervisor
      StockChartVisualizerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: StockChartVisualizer.PubSub},
      # Start the Endpoint (http/https)
      StockChartVisualizerWeb.Endpoint,

      {ConCache, [name: :dataset_cache, ttl_check_interval: false]}
      # Start a worker by calling: StockChartVisualizer.Worker.start_link(arg)
      # {StockChartVisualizer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StockChartVisualizer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    StockChartVisualizerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
