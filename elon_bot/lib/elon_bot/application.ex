defmodule ElonBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Supervisor.child_spec({Finch, name: ElonBot.Twitter.Finch}, id: ElonBot.Twitter.Finch),
      Supervisor.child_spec({Finch, name: ElonBot.Discord.Finch}, id: ElonBot.Discord.Finch),
      ElonBot.TweetStore,
      ElonBot.NewTweetSquawk
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElonBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
