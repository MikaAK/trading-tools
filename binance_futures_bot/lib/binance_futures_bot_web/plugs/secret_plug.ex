defmodule BinanceFuturesBotWeb.SecretPlug do
  require Logger

  import Plug.Conn

  @behaviour Plug

  @signature_key "signature"
  @signature BinanceFuturesBot.Config.webhook_secret()

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    conn = fetch_query_params(conn)

    validate_signature(conn, conn.query_params)
  end

  defp validate_signature(conn, %{@signature_key => signature}) when signature === @signature do
    conn
  end

  defp validate_signature(conn, _query_params) do
    error = %{code: :unauthorized, message: "secret is not correct"}

    Logger.error("[SecretPlug] #{error.message}")

    conn |> send_resp(403, Jason.encode!(error)) |> halt
  end
end
