defmodule IbEx.Client.Messages.MarketData.RequestData do
  @moduledoc """
  Request to get intra-second snapshot market data


  The input parameters are the following:

  * request_id: Unique identifier for the stream of data, needs to be a numeric string
  * contract: The financial instrument or news source description used to specify which market data to request
  * tick_list: A comma delimited list of generic tick types
  * snapshot: Boolean indicating whether to return a single market data snapshot
  * regulatory_snapshot: Boolean indicating whether to use regulatory snapshots

  At the current moment requesting data for BAG and
  delta neutral contract are not implemented yet
  """

  @version 11

  defstruct message_id: nil,
            request_id: nil,
            contract: nil,
            version: @version,
            tick_list: nil,
            snapshot: nil,
            regulatory_snapshot: nil,
            options: []

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Protocols.Subscribable

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          request_id: non_neg_integer(),
          contract: Contract.t(),
          version: non_neg_integer(),
          tick_list: String.t(),
          snapshot: boolean(),
          regulatory_snapshot: boolean(),
          options: list()
        }

  @spec new(Contract.t(), String.t(), boolean(), boolean()) ::
          {:ok, t()} | {:error, :not_implemented}
  def new(contract, tick_list, snapshot, regulatory_snapshot) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, message_id} ->
        {
          :ok,
          %__MODULE__{
            message_id: message_id,
            contract: contract,
            tick_list: tick_list,
            snapshot: snapshot,
            regulatory_snapshot: regulatory_snapshot
          }
        }

      :error ->
        {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base
    alias IbEx.Client.Types.Contract

    def to_string(msg) do
      fields = [
        msg.message_id,
        msg.version,
        msg.request_id
      ]

      fields =
        fields ++
          Contract.serialize(msg.contract, false) ++
          [false, msg.tick_list, msg.snapshot, msg.regulatory_snapshot, ""]

      Base.build(fields)
    end
  end

  defimpl Inspect, for: __MODULE__ do
    alias IbEx.Client.Types.Contract

    def inspect(msg, _opts) do
      contract = Enum.join(Contract.serialize(msg.contract, false), ", ")

      """
      --> MarketData.RequestData{
        request_id: #{msg.request_id},
        contract: #{contract},
        tick_list: #{msg.tick_list},
        snapshot: #{msg.snapshot},
        regulatory_snapshot: #{msg.regulatory_snapshot}
      }
      """
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    # Subscription based on request_id, can handle multiple requests
    def subscribe(msg, pid, table_ref) do
      request_id = Subscriptions.subscribe_by_request_id(table_ref, pid)
      {:ok, %{msg | request_id: request_id}}
    end

    def lookup(_, _) do
      {:error, :lookup_not_necessary}
    end
  end
end
