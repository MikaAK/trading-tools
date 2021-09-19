defmodule BinanceFuturesBotWeb.WebhookController do
  use BinanceFuturesBotWeb, :controller

  action_fallback BinanceFuturesBotWeb.FallbackController

  def create(conn, params) do
    IO.inspect params

    conn
      |> put_status(200)
      |> text("ok")
  end
end
