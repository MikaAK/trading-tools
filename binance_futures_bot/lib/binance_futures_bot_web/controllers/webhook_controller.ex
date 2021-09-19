defmodule WebhookController do
  use BinanceFuturesBotWeb, :controller

  action_fallback BinanceFuturesBotWeb.FallbackController
end
