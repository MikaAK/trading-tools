defmodule BinanceFuturesBotWeb.WebhookController do
  use BinanceFuturesBotWeb, :controller

  require Logger

  action_fallback BinanceFuturesBotWeb.FallbackController

  def create(conn, %{"type" => "BOLLINGER_CROSS_UNDER"}) do
    Logger.info("Bollinger Cross-Under detected")

    conn
      |> put_status(200)
      |> text("ok")
  end

  def create(conn, %{"type" => "BOLLINGER_CROSS_OVER"}) do
    Logger.info("Bollinger Cross-Over detected")

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
