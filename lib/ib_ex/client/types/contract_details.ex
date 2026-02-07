defmodule IbEx.Client.Types.ContractDetails do
  @moduledoc """
  Represents the details of a contract as returned by the ContractDetails response.
  """

  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Types.TagValue

  alias IbEx.Client.Types.ContractDetails.{
    BondDetails,
    FundDetails,
    EventContract
  }

  defstruct contract: nil,
            market_name: nil,
            min_tick: 0.0,
            order_types: nil,
            valid_exchanges: nil,
            price_magnifier: 0,
            under_conid: 0,
            long_name: nil,
            contract_month: nil,
            industry: nil,
            category: nil,
            subcategory: nil,
            time_zone_id: nil,
            trading_hours: nil,
            liquid_hours: nil,
            ev_rule: nil,
            ev_multiplier: 0.0,
            agg_group: 0,
            under_symbol: nil,
            under_sec_type: nil,
            market_rule_ids: nil,
            real_expiration_date: nil,
            last_trade_time: nil,
            stock_type: nil,
            min_size: nil,
            size_increment: nil,
            suggested_size_increment: nil,
            min_algo_size: nil,
            sec_id_list: [],
            ineligibility_reason_list: [],
            bond_details: nil,
            fund_details: nil,
            event_contract: nil

  @type t :: %__MODULE__{
          contract: Contract.t() | nil,
          market_name: binary() | nil,
          min_tick: float(),
          order_types: binary() | nil,
          valid_exchanges: binary() | nil,
          price_magnifier: non_neg_integer(),
          under_conid: non_neg_integer(),
          long_name: binary() | nil,
          contract_month: binary() | nil,
          industry: binary() | nil,
          category: binary() | nil,
          subcategory: binary() | nil,
          time_zone_id: binary() | nil,
          trading_hours: binary() | nil,
          liquid_hours: binary() | nil,
          ev_rule: binary() | nil,
          ev_multiplier: float(),
          agg_group: non_neg_integer(),
          under_symbol: binary() | nil,
          under_sec_type: binary() | nil,
          market_rule_ids: binary() | nil,
          real_expiration_date: binary() | nil,
          last_trade_time: binary() | nil,
          stock_type: binary() | nil,
          min_size: Decimal.t() | nil,
          size_increment: Decimal.t() | nil,
          suggested_size_increment: Decimal.t() | nil,
          min_algo_size: Decimal.t() | nil,
          sec_id_list: list(TagValue.t()),
          ineligibility_reason_list: list(binary()),
          bond_details: BondDetails.t() | nil,
          fund_details: FundDetails.t() | nil,
          event_contract: EventContract.t() | nil
        }

  def new(attrs) when is_list(attrs) do
    attrs
    |> Enum.into(%{})
    |> new()
  end

  def new(attrs) when is_map(attrs) do
    attrs =
      attrs
      |> assign_params(:bond_details, BondDetails)
      |> assign_params(:fund_details, FundDetails)
      |> assign_params(:event_contract, EventContract)

    struct(__MODULE__, attrs)
  end

  def new(), do: new(%{})

  defp assign_params(attrs, key, module) do
    case Map.get(attrs, key) do
      nil -> attrs
      value when is_map(value) -> Map.put(attrs, key, module.new(value))
      %{__struct__: _} = value -> Map.put(attrs, key, value)
      _ -> attrs
    end
  end
end
