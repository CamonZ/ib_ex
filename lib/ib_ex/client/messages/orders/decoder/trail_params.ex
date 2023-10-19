defmodule IbEx.Client.Messages.Orders.Decoder.TrailParams do
  alias IbEx.Client.Types.Order.TrailParams, as: Params

  @spec parse(list(binary())) :: {Params.t(), list(binary)} | {:error, any()}

  def parse(fields, opts \\ [])

  def parse(fields, _opts) when is_list(fields) and length(fields) >= 2 do
    {params, rest} = Enum.split(fields, 2)
    [price, percent] = params

    {Params.new(price, percent), rest}
  end

  def parse(thing, _) do
    {:error, thing}
  end
end
