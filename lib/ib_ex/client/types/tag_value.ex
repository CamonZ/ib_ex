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

  @type t :: list(TagValue.t())
  @spec serialize(__MODULE__.t()) :: list() | {:error, :invalid_args}
  def serialize([]), do: []

  def serialize(list) when is_list(list) do
    list
    |> to_nested_list()
    |> List.flatten()
  end

  def serialize(_), do: {:error, :invalid_args}

  @spec serialize_to_string(__MODULE__.t()) :: binary()
  def serialize_to_string(list) when is_list(list) do
    list
    |> to_nested_list()
    |> Enum.map(fn [tag, value] -> tag <> "=" <> value end)
    |> Enum.join(",")
  end

  def serialize_to_string(_), do: ""
  defp to_nested_list(list) when is_list(list) do
    list
    |> Enum.reduce([], fn %{tag: tag, value: value}, acc -> [[tag, value] | acc] end)
    |> Enum.reverse()
  end
end
