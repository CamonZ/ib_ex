defmodule IbEx.Client.Messages.Orders.OpenOrder do
  defstruct order: nil

  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Types.Contract

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      contract_str = Enum.join(Contract.serialize(msg.order.contract, false), ", ")

      """
      <-- OpenOrder{
        order: %Order{
          action: #{msg.order.action},
          total_quantity: #{msg.order.total_quantity},
          order_type: #{msg.order.order_type},
          contract: #{contract_str}
        }
      }
      """
    end
  end
end
