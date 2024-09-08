defmodule IbEx.Client.Types.TagValue do
  defstruct tag: nil, value: nil

  @type t :: %__MODULE__{
          tag: binary(),
          value: binary()
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

defmodule IbEx.Client.Types.TagValueList do
  alias IbEx.Client.Types.TagValue

  @spec serialize(list(TagValue.t())) :: list() | {:error, :invalid_args}
  def serialize([]), do: []

  def serialize(list) when is_list(list) do
    list
    |> Enum.reduce([], fn %{tag: tag, value: value}, acc -> [[tag, value] | acc] end)
    |> Enum.reverse()
    |> List.flatten()
  end

  def serialize(_), do: {:error, :invalid_args}
end
