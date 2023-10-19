defmodule IbEx.Client.Messages.Orders.Decoder.FinancialAdvisorParams do
  alias IbEx.Client.Types.Order.FinancialAdvisorParams, as: Params

  @spec parse(list(binary())) :: {Params.t(), list(binary)} | {:error, any()}

  def parse(fields, opts \\ [])

  def parse(fields, _opts) when is_list(fields) and length(fields) >= 4 do
    {params, rest} = Enum.split(fields, 4)
    [group, method, percentage, profile] = params
    {Params.new(group, method, percentage, profile), rest}
  end

  def parse(thing, _) do
    {:error, thing}
  end
end
