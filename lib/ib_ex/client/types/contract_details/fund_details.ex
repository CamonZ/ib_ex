defmodule IbEx.Client.Types.ContractDetails.FundDetails do
  @moduledoc """
  Mutual fund-specific fields for a ContractDetails.
  """

  import IbEx.Client.Utils, only: [list_to_union_type: 1]

  @fund_asset_types ~w(others money_market fixed_income multi_asset equity sector guaranteed alternative)a
  @type fund_asset_type :: unquote(list_to_union_type(@fund_asset_types))

  @fund_asset_type_codes %{
    "000" => :others,
    "001" => :money_market,
    "002" => :fixed_income,
    "003" => :multi_asset,
    "004" => :equity,
    "005" => :sector,
    "006" => :guaranteed,
    "007" => :alternative
  }

  @fund_distribution_policies ~w(accumulation_fund income_fund)a
  @type fund_distribution_policy :: unquote(list_to_union_type(@fund_distribution_policies))

  @fund_distribution_policy_codes %{
    "N" => :accumulation_fund,
    "Y" => :income_fund
  }

  defstruct name: nil,
            family: nil,
            type: nil,
            front_load: nil,
            back_load: nil,
            back_load_time_interval: nil,
            management_fee: nil,
            closed?: false,
            closed_for_new_investors?: false,
            closed_for_new_money?: false,
            notify_amount: nil,
            minimum_initial_purchase: nil,
            subsequent_minimum_purchase: nil,
            blue_sky_states: nil,
            blue_sky_territories: nil,
            distribution_policy_indicator: nil,
            asset_type: nil

  @type t :: %__MODULE__{
          name: binary() | nil,
          family: binary() | nil,
          type: binary() | nil,
          front_load: binary() | nil,
          back_load: binary() | nil,
          back_load_time_interval: binary() | nil,
          management_fee: binary() | nil,
          closed?: boolean(),
          closed_for_new_investors?: boolean(),
          closed_for_new_money?: boolean(),
          notify_amount: binary() | nil,
          minimum_initial_purchase: binary() | nil,
          subsequent_minimum_purchase: binary() | nil,
          blue_sky_states: binary() | nil,
          blue_sky_territories: binary() | nil,
          distribution_policy_indicator: fund_distribution_policy() | nil,
          asset_type: fund_asset_type() | nil
        }

  def fund_asset_types, do: @fund_asset_types
  def fund_asset_type_codes, do: @fund_asset_type_codes
  def fund_distribution_policies, do: @fund_distribution_policies
  def fund_distribution_policy_codes, do: @fund_distribution_policy_codes

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
