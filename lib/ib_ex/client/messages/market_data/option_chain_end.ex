defmodule IbEx.Client.Messages.MarketData.OptionChainEnd do
  @moduledoc """
  Returned option chain struct 
  """

  defstruct request_id: nil

  @type t :: %__MODULE__{
          request_id: String.t()
        }

  @spec from_fields(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_fields(fields) do
    IO.inspect(fields, label: "OptionChainEnd fields", limit: :infinity)
    {:ok, struct(__MODULE__)}
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl IbEx.Client.Protocols.Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(msg, table_ref) do
      Subscriptions.lookup(table_ref, msg.request_id)
    end
  end
end
