defmodule IbEx.Client.Types.Execution do
  @moduledoc """
  Represents a trade by the user
  """

  defstruct execution_id: "",
            timestamp: "",
            account_id: "",
            exchange: "",
            side: "",
            size: 0,
            price: 0.0,
            perm_id: 0,
            client_id: 0,
            order_id: 0,
            liquidation: 0,
            cumulative_quantity: Decimal.new("0"),
            average_price: Decimal.new("0.0"),
            order_ref: "",
            ev_rule: "",
            ev_multiplier: Decimal.new("0.0"),
            model_code: "",
            last_liquidity: 0,
            pending_price_revision: false

  @type t :: %__MODULE__{
          execution_id: String.t(),
          timestamp: DateTime.t(),
          account_id: String.t(),
          exchange: String.t(),
          side: String.t(),
          size: float(),
          price: float(),
          perm_id: non_neg_integer(),
          client_id: non_neg_integer(),
          order_id: any(),
          liquidation: non_neg_integer(),
          cumulative_quantity: Decimal.t(),
          average_price: float(),
          order_ref: String.t(),
          ev_rule: String.t(),
          ev_multiplier: float(),
          model_code: String.t(),
          last_liquidity: non_neg_integer(),
          pending_price_revision: boolean()
        }

  alias IbEx.Client.Utils

  @last_liquidities %{
    "1" => :add,
    "2" => :remove,
    "3" => :routed_out
  }

  def from_execution_data([
        order_id,
        execution_id,
        time,
        account_id,
        exchange,
        side,
        size,
        price,
        perm_id,
        client_id,
        liquidation,
        cumulative_quantity,
        average_price,
        order_ref,
        ev_rule,
        ev_mult,
        model_code,
        last_liq,
        pending_price_revision
      ]) do
    with {:ok, ts} <- Utils.parse_timestamp_str(time) do
      {
        :ok,
        %__MODULE__{
          order_id: order_id,
          execution_id: execution_id,
          timestamp: ts,
          account_id: account_id,
          exchange: exchange,
          side: side,
          size: Utils.to_float(size),
          price: Utils.to_float(price),
          perm_id: Utils.to_integer(perm_id),
          client_id: Utils.to_integer(client_id),
          liquidation: Utils.to_integer(liquidation),
          cumulative_quantity: Utils.to_decimal(cumulative_quantity),
          average_price: Utils.to_float(average_price),
          order_ref: order_ref,
          ev_rule: ev_rule,
          ev_multiplier: Utils.to_float(ev_mult),
          model_code: model_code,
          last_liquidity: @last_liquidities[last_liq],
          pending_price_revision: Utils.to_bool(pending_price_revision)
        }
      }
    else
      _ ->
        {:error, :invalid_args}
    end
  rescue
    _ ->
      {:error, :invalid_args}
  end
end
