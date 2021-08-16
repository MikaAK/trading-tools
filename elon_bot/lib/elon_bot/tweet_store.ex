defmodule ElonBot.TweetStore do
  use Agent

  require Logger

  @default_name :tweet_store

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, @default_name)

    Agent.start_link(fn -> [] end, opts)
  end

  def add_new(server \\ @default_name, new_tweets) do
    Agent.get_and_update(server, fn tweets ->
      new_tweets = case sort_by_creation(tweets) do
        [] ->
          Logger.debug("Initializing with tweets #{length(new_tweets)}")

          new_tweets

        [latest_tweet | _] ->
          latest_tweets = reject_tweets_before(new_tweets, latest_tweet.created_at)

          Logger.debug("Found #{length(latest_tweets)} new tweets")

          latest_tweets
      end

      {new_tweets, tweets ++ new_tweets}
    end)
  end

  defp reject_tweets_before(tweets, date_time) do
    Enum.reject(tweets, &(DateTime.compare(&1.created_at, date_time) in [:lt, :eq]))
  end

  def all(server \\ @default_name) do
    Agent.get(server, &sort_by_creation/1)
  end

  def sort_by_creation(tweets, direction \\ :desc) do
    Enum.sort_by(tweets, &(&1.created_at), {direction, DateTime})
  end
end
