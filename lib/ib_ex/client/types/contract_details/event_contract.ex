defmodule IbEx.Client.Types.ContractDetails.EventContract do
  @moduledoc """
  Event contract data associated with a ContractDetails.
  """

  defstruct contract_id: nil,
            description_1: nil,
            description_2: nil

  @type t :: %__MODULE__{
          contract_id: binary() | nil,
          description_1: binary() | nil,
          description_2: binary() | nil
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
