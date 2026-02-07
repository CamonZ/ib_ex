defmodule IbEx.Client.Proto.Mapper.Contract do
  @moduledoc """
  Maps between `IbEx.Client.Types.Contract` domain structs and
  `IbEx.Client.Proto.Protobuf.Contract` proto structs.

  Handles:
  - conid: string (domain) <-> int32 (proto)
  - security_type (domain) <-> sec_type (proto)
  - strike: string (domain) <-> double (proto)
  - primary_exchange (domain) <-> primary_exch (proto)
  - security_id_type (domain) <-> sec_id_type (proto)
  - security_id (domain) <-> sec_id (proto)
  - combo_legs_description (domain) <-> combo_legs_descrip (proto)
  - combo_legs: list of ComboLeg structs
  - delta_neutral_contract: nested struct
  - multiplier: string (domain) <-> double (proto)
  """

  alias IbEx.Client.Types.Contract, as: DomainContract
  alias IbEx.Client.Types.Contract.ComboLeg, as: DomainComboLeg
  alias IbEx.Client.Types.Contract.DeltaNeutral, as: DomainDeltaNeutral

  alias IbEx.Client.Proto.Protobuf.Contract, as: ProtoContract
  alias IbEx.Client.Proto.Protobuf.ComboLeg, as: ProtoComboLeg
  alias IbEx.Client.Proto.Protobuf.DeltaNeutralContract, as: ProtoDeltaNeutral

  alias IbEx.Client.Proto.Mapper.Helpers

  @doc """
  Converts a domain Contract to a proto Contract.
  """
  @spec to_proto(DomainContract.t()) :: ProtoContract.t()
  def to_proto(%DomainContract{} = contract) do
    %ProtoContract{
      con_id: Helpers.conid_to_int(contract.conid),
      symbol: contract.symbol,
      sec_type: contract.security_type,
      last_trade_date_or_contract_month: contract.last_trade_date_or_contract_month,
      strike: Helpers.strike_to_double(contract.strike),
      right: contract.right,
      multiplier: multiplier_to_double(contract.multiplier),
      exchange: contract.exchange,
      primary_exch: contract.primary_exchange,
      currency: contract.currency,
      local_symbol: contract.local_symbol,
      trading_class: contract.trading_class,
      sec_id_type: contract.security_id_type,
      sec_id: contract.security_id,
      description: contract.description,
      issuer_id: contract.issuer_id,
      include_expired: contract.include_expired,
      combo_legs_descrip: contract.combo_legs_description,
      combo_legs: Enum.map(contract.combo_legs || [], &combo_leg_to_proto/1),
      delta_neutral_contract: delta_neutral_to_proto(contract.delta_neutral_contract)
    }
  end

  @doc """
  Converts a proto Contract to a domain Contract.
  """
  @spec from_proto(ProtoContract.t()) :: DomainContract.t()
  def from_proto(%ProtoContract{} = proto) do
    %DomainContract{
      conid: Helpers.conid_to_string(proto.con_id),
      symbol: proto.symbol || "",
      security_type: proto.sec_type || "",
      last_trade_date_or_contract_month: proto.last_trade_date_or_contract_month || "",
      strike: Helpers.strike_to_string(proto.strike) || "0.0",
      right: proto.right || "",
      multiplier: multiplier_to_string(proto.multiplier),
      exchange: proto.exchange || "SMART",
      primary_exchange: proto.primary_exch || "",
      currency: proto.currency || "",
      local_symbol: proto.local_symbol || "",
      trading_class: proto.trading_class || "",
      security_id_type: proto.sec_id_type || "",
      security_id: proto.sec_id || "",
      description: proto.description || "",
      issuer_id: proto.issuer_id || "",
      include_expired: proto.include_expired || false,
      combo_legs_description: proto.combo_legs_descrip,
      combo_legs: Enum.map(proto.combo_legs || [], &combo_leg_from_proto/1),
      delta_neutral_contract: delta_neutral_from_proto(proto.delta_neutral_contract)
    }
  end

  # --- ComboLeg mapping ---

  @spec combo_leg_to_proto(DomainComboLeg.t()) :: ProtoComboLeg.t()
  defp combo_leg_to_proto(%DomainComboLeg{} = leg) do
    %ProtoComboLeg{
      con_id: leg.conid,
      ratio: leg.ratio,
      action: to_string(leg.action),
      exchange: leg.exchange,
      open_close: leg.open_close,
      short_sales_slot: leg.short_sale_slot,
      designated_location: leg.designated_location,
      exempt_code: leg.exempt_code
    }
  end

  @spec combo_leg_from_proto(ProtoComboLeg.t()) :: DomainComboLeg.t()
  defp combo_leg_from_proto(%ProtoComboLeg{} = proto) do
    %DomainComboLeg{
      conid: proto.con_id,
      ratio: proto.ratio,
      action: proto.action,
      exchange: proto.exchange,
      open_close: proto.open_close || 0,
      short_sale_slot: proto.short_sales_slot || 0,
      designated_location: proto.designated_location,
      exempt_code: proto.exempt_code || -1
    }
  end

  # --- DeltaNeutral mapping ---

  @spec delta_neutral_to_proto(DomainDeltaNeutral.t() | nil) :: ProtoDeltaNeutral.t() | nil
  defp delta_neutral_to_proto(nil), do: nil

  defp delta_neutral_to_proto(%DomainDeltaNeutral{} = dn) do
    %ProtoDeltaNeutral{
      con_id: Helpers.conid_to_int(dn.conid),
      delta: Helpers.decimal_to_double(dn.delta),
      price: Helpers.decimal_to_double(dn.price)
    }
  end

  @spec delta_neutral_from_proto(ProtoDeltaNeutral.t() | nil) :: DomainDeltaNeutral.t() | nil
  defp delta_neutral_from_proto(nil), do: nil

  defp delta_neutral_from_proto(%ProtoDeltaNeutral{} = proto) do
    %DomainDeltaNeutral{
      conid: Helpers.conid_to_string(proto.con_id),
      delta: Helpers.double_to_decimal(proto.delta),
      price: Helpers.double_to_decimal(proto.price)
    }
  end

  # --- Multiplier helpers ---
  # Domain stores multiplier as string, proto as double

  defp multiplier_to_double(""), do: nil
  defp multiplier_to_double(nil), do: nil

  defp multiplier_to_double(str) when is_binary(str) do
    case Float.parse(str) do
      {val, _} -> val
      :error -> nil
    end
  end

  defp multiplier_to_string(nil), do: ""
  defp multiplier_to_string(val) when is_float(val), do: Float.to_string(val)
  defp multiplier_to_string(val) when is_integer(val), do: Integer.to_string(val)
end
