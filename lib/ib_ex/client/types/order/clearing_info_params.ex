defmodule IbEx.Client.Types.Order.ClearingInfoParams do
  @moduledoc """
  Params for clearing info
  """
  import IbEx.Client.Utils, only: [list_to_union_type: 1]

  @clearing_intents ~w(IB Away PTA)a

  @type clearing_intent :: unquote(list_to_union_type(@clearing_intents))

  defstruct account: nil,
            settling_firm: nil,
            clearing_account: nil,
            clearing_intent: nil

  @type t :: %__MODULE__{
          # IB account
          account: binary(),
          settling_firm: binary(),
          # True beneficiary of the order 
          clearing_account: binary(),
          clearing_intent: clearing_intent() | nil
        }

  def new(args) when is_list(args) do
    args
    |> Enum.into(%{})
    |> new()
  end

  def new(args) when is_map(args) do
    struct(__MODULE__, args)
  end

  def new(), do: new(%{})

  @spec serialize(__MODULE__.t()) :: list()
  def serialize(%__MODULE__{} = params) do
    [
      params.clearing_account,
      params.clearing_intent
    ]
  end
end
