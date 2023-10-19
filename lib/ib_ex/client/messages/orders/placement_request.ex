defmodule IbEx.Client.Messages.Orders.PlacementRequest do
  @message_id 3

  alias IbEx.Client.Messages.Base

  defstruct message_id: nil, client_id: nil, optional_capabilities: nil

  def new(opts \\ []) do
    optional_capabilities = Keyword.get(opts, :optional_capabilities)
    client_id = Keyword.get(opts, :client_id, 0)

    {:ok, %__MODULE__{message_id: @message_id, client_id: client_id, optional_capabilities: optional_capabilities}}
  end
end

defimpl String.Chars, for: __MODULE__ do
  alias IbEx.Client.Messages.Base

  def to_string(msg) do
    fields =
      case is_nil(msg.optional_capabilities) do
        true -> []
        false -> [msg.optional_capabilities]
      end

    Base.build([msg.message_id, msg.client_id] ++ fields)
  end
end

defimpl Inspect, for: __MODULE__ do
  def inspect(msg, _opts) do
    "--> MarketData{version: #{msg.version}}"
  end
end
