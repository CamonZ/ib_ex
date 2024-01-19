defmodule IbEx.Client.Messages.Orders.RequestCreateOrder do
  @moduledoc """
  Message used to create an order

  Params:

  * order_id: Unique id for the order, gets initially returned in the response of the
    the StartApi message, or through the NextValidId message
  * order: Order struct containing the details of the order
  * contract: Contract struct containing the details of the financial instrument
  """

  @version 45

  defstruct message_id: nil, order_id: nil, order: nil, contract: nil

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Types.Order

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          order_id: non_neg_integer(),
          order: Order.t(),
          contract: Contract.t()
        }

  @spec new(non_neg_integer(), Order.t(), Contract.t()) :: {:ok, t()} | {:error, :invalid_args}
  def new(order_id, %Order{} = order, %Contract{} = contract) do
    {:ok, message_id} = Requests.message_id_for(__MODULE__)

    {
      :ok,
      %__MODULE__{
        message_id: message_id,
        order_id: order_id,
        order: order,
        contract: contract
      }
    }
  end

  def new(_, _, _) do
    {:error, :invalid_args}
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base
    alias IbEx.Client.Types.Contract

    def to_string(msg) do
      fields =
        [
          msg.message_id,
          # old server versions put here the message version
          msg.order_id
        ] ++
          Contract.serialize(msg.contract, false) ++
          [
            msg.contract.security_id_type,
            msg.contract.security_id
          ] ++
          Base.build(fields)
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "--> RequestCreateOrder{version: #{msg.version}}"
    end
  end
end
