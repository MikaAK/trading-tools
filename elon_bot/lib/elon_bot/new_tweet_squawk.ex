defmodule ElonBot.NewTweetSquawk do
  use Task, restart: :permanent

  alias ElonBot.{Discord, TweetStore}

  require Logger

  @check_interval :timer.minutes(1)
  @elon_twitter_name "elonmusk"

  def start_link(_) do
    Task.start(fn -> run(true) end)
  end

  def run(first_run?) do
    check_for_new_tweets(first_run?)

    Process.sleep(@check_interval)

    run(false)
  end

  def check_for_new_tweets(first_run?) do
    case ElonBot.Twitter.load_user(@elon_twitter_name) do
      {:ok, %{tweets: tweets}} -> add_and_check_for_new_tweets(tweets, first_run?)
      {:error, e} ->
        Logger.error("Error loading tweets\n#{inspect e}")

        Discord.post_in_channel("Couldn't load tweets from twitter, please check the bot...")
    end
  end

  defp add_and_check_for_new_tweets(tweets, first_run?) do
    with tweets when tweets !== [] <- TweetStore.add_new(tweets) do
      if first_run? do
        [latest_tweet | _] = tweets

        send_tweet_message_to_discord(latest_tweet)
      else
        tweets
          |> TweetStore.sort_by_creation(:asc)
          |> Enum.map(&send_tweet_message_to_discord/1)
      end
    end
  end

  defp send_tweet_message_to_discord(%{attachments: attachments} = tweet) do
    attachments_text = format_attachments(attachments)

    tweet
      |> format_tweet
      |> Kernel.<>("\n#{attachments_text}")
      |> Discord.post_in_channel
  end

  defp send_tweet_message_to_discord(tweet) do
    tweet |> format_tweet() |> Discord.post_in_all_channels
  end

  defp format_tweet(%{text: text, created_at: created_at}) do
    "#{Calendar.strftime(created_at, "%a, %B %d %Y")} - #{HtmlEntities.decode(text)}"
  end

  defp format_attachments(attachments) do
    attachments
      |> Stream.map(fn
        %{preview_image_url: url} -> url
        %{url: url} -> url
      end)
      |> Enum.join("\n")
  end
end
