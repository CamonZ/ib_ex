defmodule IbEx.Client.Messages.TickByTickData.Request do
  @moduledoc """
  Request for realtime Time and Sales data of a given contract

  The required parameters for the request are:

  * The contract for which we're requesting the tick by tick data
  * The request id (unique identifier use to differentiate between tick by tick data from different contracts)
  * The tick type (one of 4 possible values defined below)

  The optional parameters are:

  * number_of_ticks (how many historical ticks to receive before new data)
  * ignore_size (???, To be determined)
  """

  alias IbEx.Client.Messages.Base
  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Protocols.Traceable

  defstruct message_id: nil, request_id: nil, contract: nil, tick_type: nil, number_of_ticks: nil, ignore_size: nil

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          request_id: non_neg_integer(),
          contract: Contract.t(),
          tick_type: String.t(),
          number_of_ticks: non_neg_integer(),
          ignore_size: boolean()
        }

  @valid_tick_types ~w(
    Last
    AllLast
    BidAsk
    MidPoint
  )

  @spec new(Contract.t(), non_neg_integer(), String.t(), non_neg_integer(), boolean()) ::
          {:ok, t()} | {:error, :not_implemented | :invalid_args}
  def new(%Contract{} = contract, request_id, tick_type, number_of_ticks \\ 0, ignore_size \\ false) do
    with {:ok, id} <- Requests.message_id_for(__MODULE__),
         {:tick_type, true} <- validate_tick_type(tick_type),
         {:number_of_ticks, true} <- validate_number_of_ticks(number_of_ticks),
         {:ignore_size, true} <- {:ignore_size, is_boolean(ignore_size)} do
      {
        :ok,
        %__MODULE__{
          message_id: id,
          request_id: request_id,
          contract: contract,
          tick_type: tick_type,
          number_of_ticks: number_of_ticks,
          ignore_size: ignore_size
        }
      }
    else
      :error ->
        {:error, :not_implemented}

      {_, false} ->
        {:error, :invalid_args}
    end
  end

  defp validate_tick_type(tick_type) do
    {:tick_type, tick_type in @valid_tick_types}
  end

  defp validate_number_of_ticks(number_of_ticks) do
    {:number_of_ticks, is_integer(number_of_ticks) and number_of_ticks >= 0}
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      fields =
        [msg.message_id, msg.request_id] ++
          Contract.serialize(msg.contract, false) ++
          [msg.tick_type, msg.number_of_ticks, msg.ignore_size]

      Base.build(fields)
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "-->
        TickByTickData{
          message_id: #{msg.message_id},
          request_id: #{msg.request_id},
          contract: #{msg.contract.symbol},
          tick_type: #{msg.tick_type},
          number_of_ticks: #{msg.number_of_ticks},
          ignore_size: #{msg.ignore_size}
        }"
    end
  end
end
