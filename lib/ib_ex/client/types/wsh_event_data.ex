defmodule IbEx.Client.Types.WshEventData do
  @moduledoc """
  Represents Wall Street Horizon event data for a contract.
  """

  defstruct data_json: nil

  @type t :: %__MODULE__{
          data_json: binary() | nil
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
