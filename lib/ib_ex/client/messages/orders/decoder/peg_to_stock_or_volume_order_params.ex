defmodule IbEx.Client.Messages.Orders.Decoder.PegToStockOrVolumeOrderParams do
  alias IbEx.Client.Types.Order.PegToStockOrVolumeOrderParams, as: Params

  @spec parse(list(binary())) :: {Params.t(), list(binary)} | {:error, any()}

  def parse(fields, opts \\ [])

  def parse(fields, _opts) when is_list(fields) and length(fields) >= 2 do
    {params, rest} = Enum.split(fields, 2)
    [lower, upper] = params

    {Params.new(lower, upper), rest}
  end

  def parse(thing, _) do
    {:error, thing}
  end
end
