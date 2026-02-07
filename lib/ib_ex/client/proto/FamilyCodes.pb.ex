defmodule IbEx.Client.Proto.Protobuf.FamilyCodes do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.FamilyCodes",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:family_codes, 1, json_name: "familyCodes", repeated: true, type: IbEx.Client.Proto.Protobuf.FamilyCode)
end
