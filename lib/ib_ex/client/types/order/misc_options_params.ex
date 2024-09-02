defmodule IbEx.Client.Types.Order.MiscOptionsParams do
  @moduledoc """
  Miscellaneous params
  """

  defstruct misc_options: []

  @type t :: %__MODULE__{
          misc_options: list()
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

  @spec serialize(list()) :: binary()
  def serialize(params) when is_list(params) do
    Enum.reduce(params, "", fn param, acc -> acc <> to_string(param) end)
  end

  def serialize(_), do: ""
end
