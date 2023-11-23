defmodule IbEx.Client.Messages.StartApi.Request do
  @moduledoc """
  Message sent after connection's been initialized. Starts the API connection
  it's responses are the ManagedAccounts message, NextValidId and info messages
  regarding the data connections
  """

  @version 2

  alias IbEx.Client.Messages.Requests

  defstruct message_id: nil, optional_capabilities: nil, client_id: nil, version: @version

  def new(opts) do
    with {:ok, message_id} <- Requests.message_id_for(__MODULE__),
         optional_capabilities <- Keyword.get(opts, :optional_capabilities),
         client_id <- Keyword.get(opts, :client_id, 0) do
      fields =
        case is_nil(optional_capabilities) do
          true -> []
          false -> [optional_capabilities]
        end

      {
        :ok,
        %__MODULE__{
          message_id: message_id,
          optional_capabilities: fields,
          client_id: client_id
        }
      }
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build(
        [
          msg.message_id,
          msg.version,
          msg.client_id
        ] ++ msg.optional_capabilities
      )
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "--> StartAPI{id: #{msg.message_id}, version: #{msg.version}, client_id: #{msg.client_id}, opt_capabilities: #{inspect(msg.optional_capabilities)}}"
    end
  end
end
