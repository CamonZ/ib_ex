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

  alias IbEx.Client.Utils

  @doc """
  Converts a domain Contract to a proto Contract.
  """
  @spec to_proto(DomainContract.t()) :: ProtoContract.t()
  def to_proto(%DomainContract{} = contract) do
    %ProtoContract{
      con_id: Utils.to_integer(contract.conid, :nullable),
      symbol: contract.symbol,
      sec_type: contract.security_type,
      last_trade_date_or_contract_month: contract.last_trade_date_or_contract_month,
      strike: Utils.to_float(contract.strike, :nullable),
      right: contract.right,
      multiplier: Utils.to_float(contract.multiplier, :nullable),
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
      conid: Utils.to_string_value(proto.con_id, :nullable),
      symbol: proto.symbol || "",
      security_type: proto.sec_type || "",
      last_trade_date_or_contract_month: proto.last_trade_date_or_contract_month || "",
      strike: Utils.to_string_value(proto.strike, :nullable) || "0.0",
      right: proto.right || "",
      multiplier: Utils.to_string_value(proto.multiplier, :nullable) || "",
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
      con_id: Utils.to_integer(dn.conid, :nullable),
      delta: Utils.to_float(dn.delta, :nullable),
      price: Utils.to_float(dn.price, :nullable)
    }
  end

  @spec delta_neutral_from_proto(ProtoDeltaNeutral.t() | nil) :: DomainDeltaNeutral.t() | nil
  defp delta_neutral_from_proto(nil), do: nil

  defp delta_neutral_from_proto(%ProtoDeltaNeutral{} = proto) do
    %DomainDeltaNeutral{
      conid: Utils.to_string_value(proto.con_id, :nullable),
      delta: Utils.to_decimal(proto.delta, :nullable),
      price: Utils.to_decimal(proto.price, :nullable)
    }
  end
end
