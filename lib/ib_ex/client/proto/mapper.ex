defmodule IbEx.Client.Proto.Mapper do
  @moduledoc """
  Central mapper that converts between IbEx domain types and generated protobuf structs.

  This is the single translation point between the domain world (snake_case fields,
  Decimal for prices, nested sub-structs, sentinel values) and the proto world
  (camelCase wire names, native int/double, flat structure, nil for unset).

  ## Usage

      # Domain -> Proto
      proto_contract = Mapper.to_proto(domain_contract)

      # Proto -> Domain
      domain_contract = Mapper.from_proto(proto_contract)

  Dispatches based on the struct type of the input. Raises `ArgumentError` for
  unknown struct types.
  """

  alias IbEx.Client.Types.Contract, as: DomainContract
  alias IbEx.Client.Types.Order, as: DomainOrder
  alias IbEx.Client.Types.Execution, as: DomainExecution
  alias IbEx.Client.Types.ExecutionsFilter, as: DomainExecutionsFilter

  alias IbEx.Client.Proto.Protobuf.Contract, as: ProtoContract
  alias IbEx.Client.Proto.Protobuf.Order, as: ProtoOrder
  alias IbEx.Client.Proto.Protobuf.Execution, as: ProtoExecution
  alias IbEx.Client.Proto.Protobuf.ExecutionFilter, as: ProtoExecutionFilter

  alias IbEx.Client.Proto.Mapper.{Contract, Order, Execution, ExecutionFilter}

  # --- to_proto: Domain -> Proto ---

  @doc """
  Converts an IbEx domain struct to its corresponding proto struct.

  Raises `ArgumentError` if the given struct type has no registered mapping.

  ## Examples

      iex> contract = %IbEx.Client.Types.Contract{conid: "265598", symbol: "AAPL"}
      iex> proto = IbEx.Client.Proto.Mapper.to_proto(contract)
      iex> proto.con_id
      265598
  """
  @spec to_proto(struct()) :: struct()
  def to_proto(%DomainContract{} = struct), do: Contract.to_proto(struct)
  def to_proto(%DomainOrder{} = struct), do: Order.to_proto(struct)
  def to_proto(%DomainExecution{} = struct), do: Execution.to_proto(struct)
  def to_proto(%DomainExecutionsFilter{} = struct), do: ExecutionFilter.to_proto(struct)

  def to_proto(%{__struct__: module}) do
    raise ArgumentError, "No proto mapping registered for domain type #{inspect(module)}"
  end

  # --- from_proto: Proto -> Domain ---

  @doc """
  Converts a proto struct to its corresponding IbEx domain struct.

  Raises `ArgumentError` if the given proto struct type has no registered mapping.

  ## Examples

      iex> proto = %IbEx.Client.Proto.Protobuf.Contract{con_id: 265598, symbol: "AAPL"}
      iex> domain = IbEx.Client.Proto.Mapper.from_proto(proto)
      iex> domain.conid
      "265598"
  """
  @spec from_proto(struct()) :: struct()
  def from_proto(%ProtoContract{} = struct), do: Contract.from_proto(struct)
  def from_proto(%ProtoOrder{} = struct), do: Order.from_proto(struct)
  def from_proto(%ProtoExecution{} = struct), do: Execution.from_proto(struct)
  def from_proto(%ProtoExecutionFilter{} = struct), do: ExecutionFilter.from_proto(struct)

  def from_proto(%{__struct__: module}) do
    raise ArgumentError, "No domain mapping registered for proto type #{inspect(module)}"
  end
end
