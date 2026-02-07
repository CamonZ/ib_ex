defmodule IbEx.Client.Messages.Ids.NextValidId do
  @moduledoc """
  Gets the next valid id to be used for order placement
  """
  require Logger
  alias IbEx.Client.Protocols.Traceable

  defstruct next_valid_id: nil

  def from_protobuf(payload) when is_binary(payload) do
    proto = IbEx.Client.Proto.Protobuf.NextValidId.decode(payload)

    {:ok, %__MODULE__{next_valid_id: proto.order_id}}
  rescue
    err ->
      Logger.warning("Error decoding NextValidId protobuf: #{inspect(err)}")
      {:error, :decode_error}
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "<-- %NextValidId{next_valid_id: #{msg.next_valid_id}}"
    end
  end
end
