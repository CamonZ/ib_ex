defmodule IbEx.Client.Proto.Mapper.ExecutionFilter do
  @moduledoc """
  Maps between `IbEx.Client.Types.ExecutionsFilter` domain structs and
  `IbEx.Client.Proto.Protobuf.ExecutionFilter` proto structs.

  Field name translations:
  - client_id: string (domain) <-> int32 (proto)
  - account_id (domain) <-> acct_code (proto)
  - security_type (domain) <-> sec_type (proto)
  - specific_dates: list of strings (domain) <-> repeated int32 (proto)
  - last_n_days: integer in both
  """

  alias IbEx.Client.Types.ExecutionsFilter, as: DomainFilter
  alias IbEx.Client.Proto.Protobuf.ExecutionFilter, as: ProtoFilter
  alias IbEx.Client.Utils

  @doc """
  Converts a domain ExecutionsFilter to a proto ExecutionFilter.
  """
  @spec to_proto(DomainFilter.t()) :: ProtoFilter.t()
  def to_proto(%DomainFilter{} = filter) do
    %ProtoFilter{
      client_id: Utils.to_integer(filter.client_id, :nullable),
      acct_code: filter.account_id,
      time: filter.time,
      symbol: filter.symbol,
      sec_type: filter.security_type,
      exchange: filter.exchange,
      side: filter.side,
      last_n_days: filter.last_n_days,
      specific_dates: dates_to_ints(filter.specific_dates)
    }
  end

  @doc """
  Converts a proto ExecutionFilter to a domain ExecutionsFilter.
  """
  @spec from_proto(ProtoFilter.t()) :: DomainFilter.t()
  def from_proto(%ProtoFilter{} = proto) do
    %DomainFilter{
      client_id: Utils.to_string_value(proto.client_id, :nullable),
      account_id: proto.acct_code,
      time: proto.time,
      symbol: proto.symbol,
      security_type: proto.sec_type,
      exchange: proto.exchange,
      side: proto.side,
      last_n_days: proto.last_n_days,
      specific_dates: ints_to_dates(proto.specific_dates)
    }
  end

  # --- Private helpers ---

  defp dates_to_ints(nil), do: []
  defp dates_to_ints([]), do: []

  defp dates_to_ints(dates) when is_list(dates) do
    Enum.map(dates, fn
      date when is_binary(date) -> String.to_integer(date)
      date when is_integer(date) -> date
    end)
  end

  defp ints_to_dates(nil), do: nil
  defp ints_to_dates([]), do: nil
  defp ints_to_dates(ints) when is_list(ints), do: Enum.map(ints, &Integer.to_string/1)
end
