defmodule ElonBot.Discord do
  @main_url hd(ElonBot.Config.discord_webhook_urls())
  @webhook_urls ElonBot.Config.discord_webhook_urls()
  @headers [{"Content-Type", "application/json"}]


  # For testing stick the above fn inside the if
  # if Mix.env() === :prod do
    def post_in_channel(webhook_url \\ @main_url, message) do
      res = :post
        |> Finch.build(webhook_url, @headers, Jason.encode!(%{content: message}))
        |> Finch.request(ElonBot.Discord.Finch)

      with {:ok, _} <- res do
        :ok
      end
    end
  # else
  #   def post_in_channel(webhook_url \\ @main_url, message) do
  #     IO.inspect "SENDING MESSAGE #{message} to #{webhook_url}\nHeaders: #{inspect(@headers)}"

  #     :ok
  #   end
  # end

  def post_in_all_channels(message) do
    Enum.reduce(@webhook_urls, :ok, fn
      webhook_url, :ok -> post_in_channel(webhook_url, message)
      _, {:error, _} = e -> e
      _, acc -> acc
    end)
  end
end
