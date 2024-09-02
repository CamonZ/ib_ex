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

  defstruct message_id: nil, order_id: nil, order: nil, contract: nil, version: @version

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Types.{Order, Contract}

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
    alias IbEx.Client.Types.{Order, Contract}
    alias Contract.DeltaNeutral

    def to_string(msg) do
      fields =
        [
          msg.message_id,
          # old server versions put here the message version
          msg.order_id
          # ] 
        ] ++
          Contract.serialize(msg.contract, false) ++
          [
            msg.contract.security_id_type,
            msg.contract.security_id
          ] ++
          Order.serialize(msg.order, :first_batch) ++
          Contract.maybe_serialize_combo_legs(msg.contract) ++
          Order.maybe_serialize_combo_legs(msg.order, msg.contract.security_type == "BAG") ++          
          Order.serialize(msg.order, :second_batch) ++
          DeltaNeutral.serialize(msg.contract.delta_neutral_contract) ++ 
          Order.serialize(msg.order, :third_batch) ++
          Order.maybe_serialize_min_trade_quantity(msg.order, msg.contract.exchange == "IBKRATS") ++
          Order.serialize(msg.order, :fourth_batch)

      Base.build(fields)
    end

  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      contract = Contract.serialize(msg.contract, false)

      """
      --> RequestCreateOrder{
        order_id: #{msg.order_id},
        order: %Order{
          action: #{msg.order.action}, 
          total_quantity: #{msg.order.total_quantity}, 
          order_type: #{msg.order.order_type},
          limit_price: #{msg.order.limit_price},
          aux_price: #{msg.order.aux_price},
          algo_strategy: #{msg.order.algo_params.algo_strategy},
          misc_options: #{msg.order.misc_options_params.misc_options}
        },
        contract: #{contract}
      }
      """
    end
  end
end
