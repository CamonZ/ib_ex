defmodule IbEx.Client.Proto.Protobuf.PortfolioValue do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.PortfolioValue",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:contract, 1, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:position, 2, proto3_optional: true, type: :string)
  field(:market_price, 3, json_name: "marketPrice", proto3_optional: true, type: :double)
  field(:market_value, 4, json_name: "marketValue", proto3_optional: true, type: :double)
  field(:average_cost, 5, json_name: "averageCost", proto3_optional: true, type: :double)
  field(:unrealized_pnl, 6, json_name: "unrealizedPNL", proto3_optional: true, type: :double)
  field(:realized_pnl, 7, json_name: "realizedPNL", proto3_optional: true, type: :double)
  field(:account_name, 8, json_name: "accountName", proto3_optional: true, type: :string)
end
