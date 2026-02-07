defmodule IbEx.Client.Types.HistoricalSession do
  @moduledoc """
  Represents a historical trading session with start and end times.
  """

  defstruct start_date_time: nil,
            end_date_time: nil,
            ref_date: nil

  @type t :: %__MODULE__{
          start_date_time: binary() | nil,
          end_date_time: binary() | nil,
          ref_date: binary() | nil
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
