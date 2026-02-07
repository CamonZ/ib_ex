defmodule IbEx.Client.Types.WshEventDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.WshEventData

  describe "new/0" do
    test "creates a WshEventData struct with default attributes" do
      assert WshEventData.new() == %WshEventData{data_json: nil}
    end
  end

  describe "new/1" do
    test "creates a WshEventData struct from a map" do
      json = ~s({"event_type":"earnings","date":"20250120"})
      params = %{data_json: json}

      result = WshEventData.new(params)

      assert result.data_json == json
    end

    test "creates a WshEventData struct from a keyword list" do
      json = ~s({"event_type":"dividend","date":"20250215"})
      params = [data_json: json]

      result = WshEventData.new(params)

      assert result.data_json == json
    end
  end
end
