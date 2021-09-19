defmodule BinanceFuturesBotWeb.WebhookController do
  use BinanceFuturesBotWeb, :controller

  require Logger

  alias BinanceFuturesBot.BinanceBot

  @handled_events BinanceBot.events()

  action_fallback BinanceFuturesBotWeb.FallbackController

  def create(conn, %{"type" => type} = params) when type in @handled_events do
    Logger.info("Webhook event #{type} detected")

    BinanceBot.handle_event(type, params)

    conn
      |> put_status(200)
      |> text("ok")
  end

  def create(conn, params) do
    Logger.info("Unhandled params #{inspect params}")

    conn
      |> put_status(200)
      |> text("ok")
  end
end
