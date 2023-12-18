defmodule IbEx.Client.Types.NewsHeadline do
  @moduledoc """
    Represents a news headline received through the market data subscription
  """

  defstruct timestamp: nil,
            provider: nil,
            provider_id: nil,
            title: nil,
            language: nil,
            sentiment: nil,
            extra_metadata: nil

  @type t :: %__MODULE__{
          timestamp: DateTime.t(),
          provider: String.t(),
          provider_id: String.t(),
          title: String.t(),
          language: String.t() | nil,
          sentiment: String.t() | nil,
          extra_metadata: map()
        }

  @spec from_news_tick(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_news_tick([ts, provider, id, title, extra]) do
    case DateTime.from_unix(String.to_integer(ts), :millisecond) do
      {:ok, timestamp} ->
        metadata = extract_metadata(extra)

        msg = %__MODULE__{
          timestamp: timestamp,
          provider: provider,
          provider_id: id,
          title: title
        }

        {:ok, Map.merge(msg, metadata)}

      _ ->
        {:error, :invalid_args}
    end
  rescue
    _ ->
      {:error, :invalid_args}
  end

  def from_news_tick(_) do
    {:error, :invalid_args}
  end

  defp extract_metadata(str) do
    metadata = metadata_map(str)
    extra = Map.drop(metadata, ["L", "K"])

    %{language: metadata["L"], sentiment: metadata["K"], extra_metadata: extra}
  end

  defp metadata_map(str) do
    str
    |> String.split(":")
    |> Enum.chunk_every(2)
    |> Enum.reduce(%{}, fn [k, v], acc -> Map.put(acc, k, v) end)
  end
end
