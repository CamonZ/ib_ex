defmodule IbEx.Client.Messages.Orders.Decoder.VolatilityOrderParams do
  alias IbEx.Client.Types.Order.VolatilityOrderParams, as: Params

  @spec parse(list(binary())) :: {Params.t(), list(binary)} | {:error, any()}

  def parse(fields, opts \\ [])

  def parse(fields, opts) when is_list(fields) and length(fields) >= 3 do
    open_order = Keyword.get(opts, :open_order, false)

    {args, rest} =
      {%{}, fields}
      |> extract_initial_params()
      |> extract_delta_neutral_details(open_order)
      |> extract_last_fields()

    {Params.new(args), rest}
  end

  def parse(thing, _) do
    {:error, thing}
  end

  defp extract_initial_params({args, fields}) do
    {[volatility, volatility_type, order_type, aux_price], rest} = Enum.split(fields, 4)

    {
      Map.merge(args, %{
        volatility: volatility,
        volatility_type: volatility_type,
        delta_neutral_order_type: order_type,
        delta_neutral_aux_price: aux_price
      }),
      rest
    }
  end

  defp extract_delta_neutral_details({%{delta_neutral_order_type: ""} = args, fields}, _) do
    {args, fields}
  end

  defp extract_delta_neutral_details(data, open_order) do
    data
    |> extract_v27_params(open_order)
    |> extract_v31_params(open_order)
  end

  defp extract_v27_params({args, fields}, open_order) do
    case open_order do
      true ->
        {[conid, settling_firm, acct, intent], rest} = Enum.split(fields, 4)

        {
          Map.merge(args, %{
            delta_neutral_conid: conid,
            delta_neutral_settling_firm: settling_firm,
            delta_neutral_clearing_account: acct,
            delta_neutral_clearing_intent: intent
          }),
          rest
        }

      false ->
        {[conid], rest} = Enum.split(fields, 1)
        {Map.merge(args, %{delta_neutral_conid: conid}), rest}
    end
  end

  defp extract_v31_params({args, fields}, open_order) do
    case open_order do
      true ->
        {[open_close, short_sale, ss_slot, location], rest} = Enum.split(fields, 4)

        {
          Map.merge(args, %{
            delta_neutral_open_close: open_close,
            delta_neutral_short_sale: short_sale,
            delta_neutral_short_sale_slot: ss_slot,
            delta_neutral_designated_location: location
          }),
          rest
        }

      false ->
        {[short_sale, ss_slot, location], rest} = Enum.split(fields, 3)

        {
          Map.merge(args, %{
            delta_neutral_short_sale: short_sale,
            delta_neutral_short_sale_slot: ss_slot,
            delta_neutral_designated_location: location
          }),
          rest
        }
    end
  end

  defp extract_last_fields({args, fields}) do
    {[continuous_update, reference_price_type], rest} = Enum.split(fields, 2)

    {
      Map.merge(args, %{continuous_update: continuous_update, reference_price_type: reference_price_type}),
      rest
    }
  end
end
