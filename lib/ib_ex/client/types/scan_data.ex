defmodule IbEx.Client.Types.ScanData do
  @moduledoc """
  Represents a single result row from a market scanner response.
  """

  alias IbEx.Client.Types.Contract

  defstruct contract: nil,
            rank: nil,
            distance: nil,
            benchmark: nil,
            projection: nil,
            legs_str: nil

  @type t :: %__MODULE__{
          contract: Contract.t() | nil,
          rank: non_neg_integer() | nil,
          distance: binary() | nil,
          benchmark: binary() | nil,
          projection: binary() | nil,
          legs_str: binary() | nil
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
