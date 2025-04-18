defmodule IbEx.Client.Messages.Base do
  alias IbEx.Client.Connection.Frame

  @unset_integer 2 ** 31 - 1
  @unset_double Float.max_finite()

  @spec build(list(any())) :: binary()
  def build(fields, include_length \\ false) when is_list(fields) do
    fields
    |> Enum.map(&make_field/1)
    |> Enum.join("")
    |> Frame.pack(include_length)
  end

  @spec get_fields(binary()) :: list(binary())
  def get_fields(str) when is_binary(str) do
    str
    |> String.split("\x00")
    |> Enum.slice(0..-2//1)
  end

  def get_fields(_) do
    []
  end

  @spec message_id_from_fields(any()) :: {:ok, String.t()} | :error
  def message_id_from_fields(fields) when is_list(fields) and length(fields) > 1 do
    message_id = List.first(fields)

    # Sanity checking the message_id
    _ = String.to_integer(message_id)

    {:ok, message_id}
  rescue
    _ ->
      :error
  end

  def message_id_from_fields(_) do
    :error
  end

  @spec make_field(any()) :: binary()
  def make_field(nil), do: make_field("")

  def make_field(true), do: make_field(1)

  def make_field(false), do: make_field(0)

  def make_field(:unset_integer), do: make_field(@unset_integer)

  def make_field(:unset_double), do: make_field(@unset_double)

  def make_field(thing) when is_tuple(thing) or is_map(thing), do: make_field("")

  def make_field(field), do: to_string(field) <> "\x00"

  defimpl IbEx.Client.Protocols.Subscribable, for: Any do
    def subscribe(_, _, _) do
      {:error, :not_implemented}
    end

    def lookup(_, _) do
      {:error, :not_implemented}
    end
  end
end
