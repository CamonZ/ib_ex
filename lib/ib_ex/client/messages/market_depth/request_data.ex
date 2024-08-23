defmodule IbEx.Client.Messages.MarketDepth.RequestData do
  @moduledoc """
  Requests the market depth data for a given contract

  The input parameters are:

  * Request id (Unique identifier for )
  * Contract  (Financial instrument to request data for)
  * Number of rows to display (depth of book to display)
  * Is Smart Depth (SMART depth request, i.e. aggregated across multiple depth exchanges)
  """

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Protocols.Subscribable

  @version 5

  defstruct message_id: nil,
            version: @version,
            request_id: "",
            contract: nil,
            num_rows: nil,
            smart_depth?: true,
            options: ["XYZ"]

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          version: non_neg_integer(),
          request_id: non_neg_integer(),
          contract: Contract.t(),
          num_rows: non_neg_integer(),
          smart_depth?: boolean(),
          options: list(binary())
        }

  @spec new(Contract.t(), non_neg_integer(), boolean()) :: {:ok, t()} | {:error, :not_implemented}
  def new(%Contract{} = contract, num_rows, is_smart_depth \\ true) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {
          :ok,
          %__MODULE__{
            message_id: id,
            contract: contract,
            num_rows: num_rows,
            smart_depth?: is_smart_depth
          }
        }

      :error ->
        {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      fields = [
        msg.message_id,
        msg.version,
        msg.request_id
      ]

      fields = fields ++ Contract.serialize(msg.contract, false) ++ [msg.num_rows, msg.smart_depth?, ""]

      Base.build(fields)
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      --> MarketDepth.RequestData{
        request_id: #{msg.request_id},
        contract: #{msg.contract.security_type} #{msg.contract.symbol},
        num_rows: #{msg.num_rows},
        smart_depth?: #{msg.smart_depth?}
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
