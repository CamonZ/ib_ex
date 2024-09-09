defmodule IbEx.Client.Types.AlgoOrderParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.TagValue
  alias IbEx.Client.Types.Order.AlgoOrderParams

  describe "new/0" do
    test "creates a AlgoOrderParams struct with default attributes" do
      assert AlgoOrderParams.new() == %AlgoOrderParams{
               algo_strategy: nil,
               algo_params: [],
               algo_id: nil
             }
    end
  end

  describe "new/1" do
    test "creates a AlgoOrderParams struct with valid attributes" do
      params = %{
        algo_strategy: "algo_strategy",
        algo_params: [TagValue.new()],
        algo_id: "algo_id"
      }

      assert AlgoOrderParams.new(params) == %AlgoOrderParams{
               algo_params: [TagValue.new()],
               algo_strategy: "algo_strategy",
               algo_id: "algo_id"
             }
    end
  end

  describe "serialize/1" do
    test "serializes with algo_strategy == nil" do
      params = %{
        algo_strategy: nil,
        algo_params: [TagValue.new()],
        algo_id: "algo_id"
      }

      assert AlgoOrderParams.new(params) |> AlgoOrderParams.serialize() == [
               params.algo_strategy,
               params.algo_id
             ]
    end

    test "serializes with algo_strategy != nil" do
      params = %{
        algo_strategy: "algo_strategy",
        algo_params: [TagValue.new()],
        algo_id: "algo_id"
      }

      assert AlgoOrderParams.new(params) |> AlgoOrderParams.serialize() == [
               params.algo_strategy,
               length(params.algo_params),
               nil,
               nil,
               params.algo_id
             ]
    end
  end
end
