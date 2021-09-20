defmodule BinanceFuturesBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      BinanceFuturesBotWeb.Telemetry,
      {Phoenix.PubSub, name: BinanceFuturesBot.PubSub},

      BinanceFuturesBotWeb.Endpoint,
    ] ++ trade_manager_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BinanceFuturesBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  if Mix.env() === :test do
    defp trade_manager_children, do: []
  else
    defp trade_manager_children, do: [{BinanceFuturesBot.TradeManager, name: :mika, symbol: "BTCUSDT"}]
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BinanceFuturesBotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
