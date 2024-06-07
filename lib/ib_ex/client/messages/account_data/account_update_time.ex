defmodule IbEx.Client.Messages.AccountData.AccountUpdateTime do
  @moduledoc """
  Incoming message indicating the update time of an account.
  Assumes no timezone information for the time provided.
  """

  defstruct version: nil, timestamp: nil

  alias IbEx.Client.Protocols.Subscribable

  @spec from_fields([String.t()]) :: {:ok, %__MODULE__{}} | {:error, :invalid_args}
  def from_fields([version_str, hour_minute]) do
    with {version, ""} <- Integer.parse(version_str),
         {:ok, timestamp} <- build_timestamp(hour_minute) do
      {:ok, %__MODULE__{version: version, timestamp: timestamp}}
    else
      _ -> {:error, :invalid_args}
    end
  end

  @spec from_fields(list()) :: {:error, :invalid_args}
  def from_fields(_fields), do: {:error, :invalid_args}

  @spec build_timestamp(String.t()) :: {:ok, NaiveDateTime.t()} | {:error, :invalid_args}
  defp build_timestamp(hour_minute) do
    case Time.from_iso8601("#{hour_minute}:00") do
      {:ok, time} ->
        NaiveDateTime.new(Date.utc_today(), time)

      _ ->
        {:error, :invalid_args}
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "<-- AccountUpdateTime{timestamp: #{msg.timestamp}}"
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Messages.AccountData.AccountUpdateTime
    alias IbEx.Client.Subscriptions

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(_msg, table_ref) do
      Subscriptions.lookup(table_ref, AccountUpdateTime)
    end
  end
end
