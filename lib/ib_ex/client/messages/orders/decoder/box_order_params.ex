defmodule IbEx.Client.Messages.Orders.Decoder.BoxOrderParams do
  alias IbEx.Client.Types.Order.BoxOrderParams, as: Params

  @spec parse(list(binary())) :: {Params.t(), list(binary)} | {:error, any()}

  def parse(fields, opts \\ [])

  def parse(fields, _opts) when is_list(fields) and length(fields) >= 3 do
    {params, rest} = Enum.split(fields, 3)
    [starting_price, reference_price, delta] = params

    {Params.new(starting_price, reference_price, delta), rest}
  end

  def parse(thing, _) do
    {:error, thing}
  end
end
