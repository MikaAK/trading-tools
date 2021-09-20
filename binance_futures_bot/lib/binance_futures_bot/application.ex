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

      {BinanceFuturesBot.TradeManager, name: :mika_btc_usdt, symbol: "BTCUSDT"}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BinanceFuturesBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BinanceFuturesBotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
