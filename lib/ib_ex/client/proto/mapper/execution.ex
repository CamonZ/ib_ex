defmodule IbEx.Client.Proto.Mapper.Execution do
  @moduledoc """
  Maps between `IbEx.Client.Types.Execution` domain structs and
  `IbEx.Client.Proto.Protobuf.Execution` proto structs.

  Field name translations:
  - execution_id (domain) <-> exec_id (proto)
  - account_id (domain) <-> acct_number (proto)
  - size (domain, float) <-> shares (proto, string)
  - cumulative_quantity (domain, Decimal) <-> cum_qty (proto, string)
  - average_price (domain, float) <-> avg_price (proto, double)
  - ev_multiplier (domain, Decimal) <-> ev_multiplier (proto, double)
  - liquidation (domain, int) <-> is_liquidation (proto, bool)
  - pending_price_revision (domain) <-> is_price_revision_pending (proto)
  - opt_exercise_or_lapse_type (domain, atom) <-> opt_exercise_or_lapse_type (proto, int32)
  """

  alias IbEx.Client.Types.Execution, as: DomainExecution
  alias IbEx.Client.Proto.Protobuf.Execution, as: ProtoExecution
  alias IbEx.Client.Proto.Mapper.Helpers

  @option_exercise_type_map %{
    none: 0,
    exercise: 1,
    lapse: 2
  }

  @option_exercise_type_reverse_map %{
    0 => :none,
    1 => :exercise,
    2 => :lapse
  }

  @doc """
  Converts a domain Execution to a proto Execution.
  """
  @spec to_proto(DomainExecution.t()) :: ProtoExecution.t()
  def to_proto(%DomainExecution{} = exec) do
    %ProtoExecution{
      order_id: to_integer(exec.order_id),
      exec_id: exec.execution_id,
      time: timestamp_to_string(exec.timestamp),
      acct_number: exec.account_id,
      exchange: exec.exchange,
      side: exec.side,
      shares: float_or_int_to_string(exec.size),
      price: to_double(exec.price),
      perm_id: exec.perm_id,
      client_id: exec.client_id,
      is_liquidation: exec.liquidation != 0,
      cum_qty: Helpers.decimal_to_string(exec.cumulative_quantity),
      avg_price: to_double(exec.average_price),
      order_ref: exec.order_ref,
      ev_rule: exec.ev_rule,
      ev_multiplier: decimal_or_float_to_double(exec.ev_multiplier),
      model_code: exec.model_code,
      last_liquidity: exec.last_liquidity,
      is_price_revision_pending: exec.pending_price_revision,
      submitter: exec.submitter,
      opt_exercise_or_lapse_type: Map.get(@option_exercise_type_map, exec.opt_exercise_or_lapse_type)
    }
  end

  @doc """
  Converts a proto Execution to a domain Execution.
  """
  @spec from_proto(ProtoExecution.t()) :: DomainExecution.t()
  def from_proto(%ProtoExecution{} = proto) do
    %DomainExecution{
      order_id: proto.order_id,
      execution_id: proto.exec_id || "",
      timestamp: proto.time || "",
      account_id: proto.acct_number || "",
      exchange: proto.exchange || "",
      side: proto.side || "",
      size: string_to_float(proto.shares) || 0,
      price: proto.price || 0.0,
      perm_id: proto.perm_id || 0,
      client_id: proto.client_id || 0,
      liquidation: bool_to_liquidation(proto.is_liquidation),
      cumulative_quantity: Helpers.string_to_decimal(proto.cum_qty) || Decimal.new("0"),
      average_price: proto.avg_price || 0.0,
      order_ref: proto.order_ref || "",
      ev_rule: proto.ev_rule || "",
      ev_multiplier: double_to_decimal_or_default(proto.ev_multiplier),
      model_code: proto.model_code || "",
      last_liquidity: proto.last_liquidity || 0,
      pending_price_revision: proto.is_price_revision_pending || false,
      submitter: proto.submitter,
      opt_exercise_or_lapse_type: Map.get(@option_exercise_type_reverse_map, proto.opt_exercise_or_lapse_type)
    }
  end

  # --- Private helpers ---

  defp to_integer(val) when is_integer(val), do: val
  defp to_integer(val) when is_binary(val), do: String.to_integer(val)
  defp to_integer(nil), do: nil

  defp to_double(%Decimal{} = val), do: Decimal.to_float(val)
  defp to_double(val) when is_float(val), do: val
  defp to_double(val) when is_integer(val), do: val / 1
  defp to_double(nil), do: nil

  defp float_or_int_to_string(nil), do: nil
  defp float_or_int_to_string(0), do: "0"
  defp float_or_int_to_string(val) when is_float(val), do: Float.to_string(val)
  defp float_or_int_to_string(val) when is_integer(val), do: Integer.to_string(val)

  defp decimal_or_float_to_double(%Decimal{} = d), do: Decimal.to_float(d)
  defp decimal_or_float_to_double(val) when is_float(val), do: val
  defp decimal_or_float_to_double(val) when is_integer(val), do: val / 1
  defp decimal_or_float_to_double(nil), do: nil

  defp string_to_float(nil), do: nil
  defp string_to_float(""), do: nil

  defp string_to_float(str) when is_binary(str) do
    case Float.parse(str) do
      {val, _} -> val
      :error -> nil
    end
  end

  defp bool_to_liquidation(nil), do: 0
  defp bool_to_liquidation(true), do: 1
  defp bool_to_liquidation(false), do: 0

  defp double_to_decimal_or_default(nil), do: Decimal.new("0.0")
  defp double_to_decimal_or_default(val) when is_float(val), do: Decimal.from_float(val)
  defp double_to_decimal_or_default(val) when is_integer(val), do: Decimal.new(val)

  defp timestamp_to_string(%DateTime{} = dt), do: DateTime.to_string(dt)
  defp timestamp_to_string(%NaiveDateTime{} = dt), do: NaiveDateTime.to_string(dt)
  defp timestamp_to_string(str) when is_binary(str), do: str
  defp timestamp_to_string(nil), do: nil
end
