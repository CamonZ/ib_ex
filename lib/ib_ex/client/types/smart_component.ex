defmodule IbEx.Client.Types.SmartComponent do
  @moduledoc """
  Represents a SMART routing component exchange with its letter and type.
  """

  defstruct bit_number: nil,
            exchange: nil,
            exchange_letter: nil

  @type t :: %__MODULE__{
          bit_number: non_neg_integer() | nil,
          exchange: binary() | nil,
          exchange_letter: binary() | nil
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
