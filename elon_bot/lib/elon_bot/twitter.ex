defmodule ElonBot.Twitter do
  require Logger

  @headers [{"Authorization", "Bearer #{ElonBot.Config.twitter_bearer_token()}"}]

  def load_user(user_name) do
    with {:ok, user} <- find_user(user_name),
         {:ok, timeline} <- find_timeline(user.id) do
      {:ok, %{user: user, tweets: timeline}}
    end
  end

  def find_user(user_name) do
    "users/by/username/#{user_name}"
      |> get
      |> handle_response
  end

  def find_timeline(user_id) do
    "users/#{user_id}/tweets?tweet.fields=attachments,created_at&exclude=replies,retweets&expansions=attachments.media_keys&media.fields=preview_image_url,url,type"
      |> get
      |> handle_response
  end

  def get(api_path) do
    :get
      |> Finch.build("https://api.twitter.com/2/#{api_path}", @headers)
      |> Finch.request(ElonBot.Twitter.Finch)
  end

  defp handle_response({:ok, %Finch.Response{status: 200, body: body}}) do
    data = case Jason.decode!(body) do
      %{"meta" => %{"result_count" => 0}} -> %{}

      %{"data" => data, "includes" => %{"media" => media_items}} ->
        media_item_group_map = group_media_items_by_id(media_items)

        resolve_attachments(data, media_item_group_map)

      %{"data" => data} -> data
    end

    {:ok, data |> atomize_keys() |> deserialize_created_at}
  end

  defp handle_response({:error, %Mint.TransportError{reason: :closed}}) do
    Logger.debug("Mint connection closed")

    {:ok, []}
  end

  defp handle_response({_, res}) do
    {:error, "Cannot handle response: #{inspect res}"}
  end

  defp group_media_items_by_id(media_items) do
    Enum.into(media_items, %{}, fn item -> {item["media_key"], item} end)
  end

  defp resolve_attachments(data, media_item_group_map) do
    Enum.map(data, fn
      %{"attachments" => %{"media_keys" => keys}} = item ->
        attachments = Enum.map(keys, &(media_item_group_map[&1]))

        Map.put(item, "attachments", attachments)


      item -> item
    end)
  end

  def atomize_keys(map) do
    transform_keys(map, fn
      key when is_binary(key) -> String.to_atom(key)
      key -> key
    end)
  end

  defp transform_keys(map, transform_fn) when is_map(map) do
    Enum.into(map, %{}, fn {key, value} ->
      {transform_fn.(key), transform_keys(value, transform_fn)}
    end)
  end

  defp transform_keys(list, transform_fn) when is_list(list) do
    Enum.map(list, &transform_keys(&1, transform_fn))
  end

  defp transform_keys(item, _transform_fn), do: item

  defp deserialize_created_at(items) when is_list(items) do
    Enum.map(items, &deserialize_created_at/1)
  end

  defp deserialize_created_at(%{created_at: created_at} = item) do
    {:ok, datetime, _} = DateTime.from_iso8601(created_at)

    %{item | created_at: datetime}
  end

  defp deserialize_created_at(item) do
    item
  end
end
