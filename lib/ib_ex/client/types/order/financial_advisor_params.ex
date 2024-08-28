defmodule IbEx.Client.Types.Order.FinancialAdvisorParams do
  defstruct group_identifier: nil, method: nil, percentage: nil, profile: nil

  @type t :: %__MODULE__{
          group_identifier: binary(),
          method: binary(),
          percentage: binary(),
          profile: binary()
        }

  @spec new(map() | Keyword.t()) :: t()
  def new(args) when is_list(args) do
    args
    |> Enum.into(%{})
    |> new()
  end

  def new(args) when is_map(args) do
    struct(__MODULE__, args)
  end

  @spec new(binary(), binary(), binary(), binary()) :: t()
  def new(identifier, method, percentage, profile) do
    %__MODULE__{
      group_identifier: identifier,
      method: method,
      percentage: percentage,
      profile: profile
    }
  end

  def new(), do: new(%{})

  def serialize(%__MODULE__{} = params) do
    [
      params.group_identifier,
      params.profile,
      params.method,
      params.percentage
    ]
  end
end
