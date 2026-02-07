defmodule IbEx.Client.Types.IneligibilityReason do
  @moduledoc """
  Represents a reason why a contract or feature is ineligible.
  """

  defstruct id: nil,
            description: nil

  @type t :: %__MODULE__{
          id: binary() | nil,
          description: binary() | nil
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
