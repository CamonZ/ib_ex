defmodule IbEx.Client.Types.FamilyCode do
  @moduledoc """
  Represents a family code that links accounts belonging to the same family.
  """

  defstruct account_id: nil,
            family_code_str: nil

  @type t :: %__MODULE__{
          account_id: binary() | nil,
          family_code_str: binary() | nil
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
