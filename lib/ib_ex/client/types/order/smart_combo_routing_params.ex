defmodule IbEx.Client.Types.Order.SmartComboRoutingParams do
  @moduledoc """
  Params for smart routing of BAG orders
  """
  alias IbEx.Client.Types.{TagValue, TagValueList}

  defstruct params: []

  @type t :: %__MODULE__{
          params: list(TagValue.t())
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

  @spec serialize(__MODULE__.t()) :: list() | {:error, :invalid_args}
  def serialize(%__MODULE__{params: params}) do
    [
      length(params)
    ] ++ TagValueList.serialize(params)
  end
end
