defmodule IbEx.Client.Messages.Orders.Decoder.ShortSaleParams do
  alias IbEx.Client.Types.Order.ShortSaleParams, as: Params

  @spec parse(list(binary())) :: {Params.t(), list(binary)} | {:error, any()}

  def parse(fields, opts \\ [])

  def parse(fields, _opts) when is_list(fields) and length(fields) >= 3 do
    {params, rest} = Enum.split(fields, 3)
    [slot, location, code] = params

    {Params.new(slot, location, code), rest}
  end

  def parse(thing, _) do
    {:error, thing}
  end
end
