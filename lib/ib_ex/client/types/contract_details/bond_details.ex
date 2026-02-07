defmodule IbEx.Client.Types.ContractDetails.BondDetails do
  @moduledoc """
  Bond-specific fields for a ContractDetails.
  """

  defstruct cusip: nil,
            ratings: nil,
            desc_append: nil,
            bond_type: nil,
            coupon_type: nil,
            callable?: false,
            putable?: false,
            coupon: 0.0,
            convertible?: false,
            maturity: nil,
            issue_date: nil,
            next_option_date: nil,
            next_option_type: nil,
            next_option_partial?: false,
            notes: nil

  @type t :: %__MODULE__{
          cusip: binary() | nil,
          ratings: binary() | nil,
          desc_append: binary() | nil,
          bond_type: binary() | nil,
          coupon_type: binary() | nil,
          callable?: boolean(),
          putable?: boolean(),
          coupon: float(),
          convertible?: boolean(),
          maturity: binary() | nil,
          issue_date: binary() | nil,
          next_option_date: binary() | nil,
          next_option_type: binary() | nil,
          next_option_partial?: boolean(),
          notes: binary() | nil
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
