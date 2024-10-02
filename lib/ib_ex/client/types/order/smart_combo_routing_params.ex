defmodule IbEx.Client.Types.Order.SmartComboRoutingParams do
  @moduledoc """
  Params for smart routing of BAG orders
  """
  alias IbEx.Client.Types.TagValueList

  defstruct params: []

  @type t :: %__MODULE__{
          params: TagValueList.t()
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

  @spec serialize(__MODULE__.t(), boolean()) :: list() | {:error, :invalid_args}
  def serialize(module, to_string \\ false) 
  def serialize(%__MODULE__{params: params}, false) do
    [
      length(params)
    ] ++ TagValueList.serialize(params)
  end
  def serialize(%__MODULE__{params: params}, true) do
    [
      length(params),
    TagValueList.serialize_to_string(params)
    ] 
  end
end
