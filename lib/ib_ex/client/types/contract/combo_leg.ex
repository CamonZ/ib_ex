defmodule IbEx.Client.Types.Contract.ComboLeg do
  @moduledoc """
  Represents contract combo leg params

  TODO: implement serialization
  """
  import IbEx.Client.Utils, only: [list_to_union_type: 1]

  defstruct conid: nil,
            ratio: nil,
            action: nil,
            exchange: nil,
            open_close: nil,
            short_sale_slot: 0,
            designated_location: nil,
            exempt_code: -1

  @actions ~w(BUY SELL SSHORT)a
  @type actions :: unquote(list_to_union_type(@actions))

  # open_close values:
  # 	SAME_POS    = 0 = open/close leg value is same as combo
  # 	OPEN_POS    = 1 = open
  # 	CLOSE_POS   = 2 = close
  # 	UNKNOWN_POS = 3 = unknown
  @type open_close :: 0..3

  # for stock legs when doing short sale
  # Contract.ComboLeg short_sale_slot values:
  # TODO: 
  # 0 ??? 
  # 1 = clearing broker, 2 = third party
  @type short_sale_slot :: 1..2

  @type t :: %__MODULE__{
          conid: non_neg_integer(),
          ratio: non_neg_integer(),
          action: actions(),
          exchange: binary(),
          open_close: open_close(),
          short_sale_slot: short_sale_slot(),
          designated_location: binary(),
          exempt_code: integer()
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
end
