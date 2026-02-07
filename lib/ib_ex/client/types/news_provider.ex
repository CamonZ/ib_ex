defmodule IbEx.Client.Types.NewsProvider do
  @moduledoc """
  Represents a news provider with its code and name.

  Extracted from the Messages.News.Providers response message to be
  a proper domain type.
  """

  defstruct code: nil,
            name: nil

  @type t :: %__MODULE__{
          code: binary() | nil,
          name: binary() | nil
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
