defmodule IbEx.Client.Proto.Mapper.OrderTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Proto.Mapper
  alias IbEx.Client.Proto.Mapper.Order, as: OrderMapper

  alias IbEx.Client.Types.Order, as: DomainOrder
  alias IbEx.Client.Types.TagValue

  alias IbEx.Client.Proto.Protobuf.Order, as: ProtoOrder

  describe "to_proto/1" do
    test "converts main order fields" do
      order =
        DomainOrder.new(%{
          api_client_id: 1,
          api_client_order_id: 42,
          host_order_id: 12_345,
          action: "BUY",
          total_quantity: 100,
          order_type: "LMT",
          limit_price: Decimal.new("150.50"),
          aux_price: Decimal.new("0"),
          time_in_force: "DAY",
          account: "DU12345",
          transmit: true,
          parent_id: 0
        })

      proto = OrderMapper.to_proto(order)

      assert %ProtoOrder{} = proto
      assert proto.client_id == 1
      assert proto.order_id == 42
      assert proto.perm_id == 12_345
      assert proto.action == "BUY"
      assert proto.total_quantity == "100"
      assert proto.order_type == "LMT"
      assert_in_delta proto.lmt_price, 150.50, 0.01
      assert proto.tif == "DAY"
      assert proto.account == "DU12345"
      assert proto.transmit == true
      assert proto.parent_id == 0
    end

    test "flattens scale_order_params to proto flat fields" do
      order =
        DomainOrder.new(%{
          action: "BUY",
          total_quantity: 1000,
          order_type: "LMT",
          scale_order_params: %{
            init_level_size: 100,
            subs_level_size: 50,
            price_increment: Decimal.new("0.5"),
            price_adjust_value: Decimal.new("0.1"),
            price_adjust_interval: 5,
            profit_offset: Decimal.new("1.0"),
            auto_reset: true,
            init_position: 200,
            init_fill_quantity: 10,
            random_percent: false,
            table: "scale_table_1"
          }
        })

      proto = OrderMapper.to_proto(order)

      assert proto.scale_init_level_size == 100
      assert proto.scale_subs_level_size == 50
      assert_in_delta proto.scale_price_increment, 0.5, 0.001
      assert_in_delta proto.scale_price_adjust_value, 0.1, 0.001
      assert proto.scale_price_adjust_interval == 5
      assert_in_delta proto.scale_profit_offset, 1.0, 0.001
      assert proto.scale_auto_reset == true
      assert proto.scale_init_position == 200
      assert proto.scale_init_fill_qty == 10
      assert proto.scale_random_percent == false
      assert proto.scale_table == "scale_table_1"
    end

    test "flattens hedge_order_params" do
      order =
        DomainOrder.new(%{
          action: "BUY",
          order_type: "LMT",
          hedge_order_params: %{
            hedge_type: "delta",
            hedge_param: "0.5"
          }
        })

      proto = OrderMapper.to_proto(order)
      assert proto.hedge_type == "delta"
      assert proto.hedge_param == "0.5"
    end

    test "flattens algo_params with TagValueList to map" do
      order =
        DomainOrder.new(%{
          action: "BUY",
          order_type: "LMT",
          algo_params: %{
            algo_strategy: "Adaptive",
            algo_params: [
              %TagValue{tag: "adaptivePriority", value: "Normal"}
            ],
            algo_id: "algo123"
          }
        })

      proto = OrderMapper.to_proto(order)
      assert proto.algo_strategy == "Adaptive"
      assert proto.algo_id == "algo123"
      assert proto.algo_params == %{"adaptivePriority" => "Normal"}
    end

    test "converts sentinel :unset_double to nil" do
      order =
        DomainOrder.new(%{
          action: "BUY",
          order_type: "LMT",
          trigger_price: :unset_double,
          cash_quantity: :unset_double,
          limit_price_offset: :unset_double
        })

      proto = OrderMapper.to_proto(order)
      assert proto.trigger_price == nil
      assert proto.cash_qty == nil
      assert proto.lmt_price_offset == nil
    end

    test "converts sentinel :unset_integer to nil" do
      order =
        DomainOrder.new(%{
          action: "BUY",
          order_type: "LMT",
          duration: :unset_integer,
          post_to_ats: :unset_integer,
          manual_order_indicator: :unset_integer
        })

      proto = OrderMapper.to_proto(order)
      assert proto.duration == nil
      assert proto.post_to_ats == nil
      assert proto.manual_order_indicator == nil
    end

    test "converts misc_options TagValueList to map" do
      order =
        DomainOrder.new(%{
          action: "BUY",
          order_type: "LMT",
          misc_options: [
            %TagValue{tag: "key1", value: "val1"},
            %TagValue{tag: "key2", value: "val2"}
          ]
        })

      proto = OrderMapper.to_proto(order)
      assert proto.order_misc_options == %{"key1" => "val1", "key2" => "val2"}
    end

    test "flattens financial_advisor_params" do
      order =
        DomainOrder.new(%{
          action: "BUY",
          order_type: "LMT",
          fa_params: %{
            group_identifier: "Group1",
            method: "AvailableEquity",
            percentage: "50"
          }
        })

      proto = OrderMapper.to_proto(order)
      assert proto.fa_group == "Group1"
      assert proto.fa_method == "AvailableEquity"
      assert proto.fa_percentage == "50"
    end

    test "flattens clearing_params" do
      order =
        DomainOrder.new(%{
          action: "BUY",
          order_type: "LMT",
          clearing_params: %{
            clearing_account: "CLEAR1",
            clearing_intent: "IB"
          }
        })

      proto = OrderMapper.to_proto(order)
      assert proto.clearing_account == "CLEAR1"
      assert proto.clearing_intent == "IB"
    end
  end

  describe "from_proto/1" do
    test "converts main order fields back to domain" do
      proto = %ProtoOrder{
        client_id: 1,
        order_id: 42,
        perm_id: 12_345,
        action: "BUY",
        total_quantity: "100",
        order_type: "LMT",
        lmt_price: 150.50,
        aux_price: 0.0,
        tif: "DAY",
        account: "DU12345",
        transmit: true,
        parent_id: 0
      }

      order = OrderMapper.from_proto(proto)

      assert %DomainOrder{} = order
      assert order.api_client_id == 1
      assert order.api_client_order_id == 42
      assert order.host_order_id == 12_345
      assert order.action == "BUY"
      assert order.total_quantity == 100
      assert order.order_type == "LMT"
      assert Decimal.equal?(order.limit_price, Decimal.from_float(150.50))
      assert order.time_in_force == "DAY"
      assert order.account == "DU12345"
      assert order.transmit == true
      assert order.parent_id == 0
    end

    test "unflattens scale fields into ScaleOrderParams" do
      proto = %ProtoOrder{
        action: "BUY",
        order_type: "LMT",
        scale_init_level_size: 100,
        scale_subs_level_size: 50,
        scale_price_increment: 0.5,
        scale_auto_reset: true,
        scale_table: "tbl1"
      }

      order = OrderMapper.from_proto(proto)

      assert order.scale_order_params.init_level_size == 100
      assert order.scale_order_params.subs_level_size == 50
      assert Decimal.equal?(order.scale_order_params.price_increment, Decimal.from_float(0.5))
      assert order.scale_order_params.auto_reset == true
      assert order.scale_order_params.table == "tbl1"
    end

    test "unflattens hedge fields into HedgeOrderParams" do
      proto = %ProtoOrder{
        action: "BUY",
        order_type: "LMT",
        hedge_type: "delta",
        hedge_param: "0.5"
      }

      order = OrderMapper.from_proto(proto)
      assert order.hedge_order_params.hedge_type == "delta"
      assert order.hedge_order_params.hedge_param == "0.5"
    end

    test "unflattens algo_params map into AlgoOrderParams with TagValueList" do
      proto = %ProtoOrder{
        action: "BUY",
        order_type: "LMT",
        algo_strategy: "Adaptive",
        algo_params: %{"adaptivePriority" => "Normal"},
        algo_id: "algo123"
      }

      order = OrderMapper.from_proto(proto)
      assert order.algo_params.algo_strategy == "Adaptive"
      assert order.algo_params.algo_id == "algo123"
      assert length(order.algo_params.algo_params) == 1

      [tv] = order.algo_params.algo_params
      assert tv.tag == "adaptivePriority"
      assert tv.value == "Normal"
    end

    test "nil proto sentinel doubles become :unset_double" do
      proto = %ProtoOrder{
        action: "BUY",
        order_type: "LMT",
        trigger_price: nil,
        cash_qty: nil,
        lmt_price_offset: nil
      }

      order = OrderMapper.from_proto(proto)
      assert order.trigger_price == :unset_double
      assert order.cash_quantity == :unset_double
      assert order.limit_price_offset == :unset_double
    end

    test "nil proto sentinel ints become :unset_integer" do
      proto = %ProtoOrder{
        action: "BUY",
        order_type: "LMT",
        duration: nil,
        post_to_ats: nil,
        manual_order_indicator: nil
      }

      order = OrderMapper.from_proto(proto)
      assert order.duration == :unset_integer
      assert order.post_to_ats == :unset_integer
      assert order.manual_order_indicator == :unset_integer
    end

    test "unflattens misc_options map into TagValueList" do
      proto = %ProtoOrder{
        action: "BUY",
        order_type: "LMT",
        order_misc_options: %{"key1" => "val1", "key2" => "val2"}
      }

      order = OrderMapper.from_proto(proto)
      assert length(order.misc_options) == 2

      tags = Enum.map(order.misc_options, & &1.tag) |> Enum.sort()
      assert tags == ["key1", "key2"]
    end
  end

  describe "roundtrip fidelity" do
    test "basic order roundtrips preserving key fields" do
      original =
        DomainOrder.new(%{
          api_client_id: 1,
          api_client_order_id: 42,
          host_order_id: 12_345,
          action: "BUY",
          total_quantity: 100,
          order_type: "LMT",
          limit_price: Decimal.new("150"),
          aux_price: Decimal.new("0"),
          time_in_force: "DAY",
          account: "DU12345",
          transmit: true,
          parent_id: 0,
          block_order: false,
          sweep_to_fill: false,
          display_size: 0,
          trigger_method: 0,
          outside_rth: false,
          hidden: false,
          origin: 0,
          all_or_none: false,
          not_held: false,
          solicited: false,
          randomize_size: false,
          randomize_price: false,
          trigger_price: :unset_double,
          cash_quantity: :unset_double,
          duration: :unset_integer,
          post_to_ats: :unset_integer,
          manual_order_indicator: :unset_integer
        })

      roundtripped =
        original
        |> Mapper.to_proto()
        |> Mapper.from_proto()

      assert roundtripped.api_client_id == original.api_client_id
      assert roundtripped.api_client_order_id == original.api_client_order_id
      assert roundtripped.host_order_id == original.host_order_id
      assert roundtripped.action == original.action
      assert roundtripped.total_quantity == original.total_quantity
      assert roundtripped.order_type == original.order_type
      assert roundtripped.time_in_force == original.time_in_force
      assert roundtripped.account == original.account
      assert roundtripped.transmit == original.transmit
      assert roundtripped.parent_id == original.parent_id
      assert roundtripped.block_order == original.block_order
      assert roundtripped.outside_rth == original.outside_rth
      assert roundtripped.trigger_price == :unset_double
      assert roundtripped.cash_quantity == :unset_double
      assert roundtripped.duration == :unset_integer
      assert roundtripped.post_to_ats == :unset_integer
      assert roundtripped.manual_order_indicator == :unset_integer
    end

    test "order with nested sub-structs roundtrips preserving nested values" do
      original =
        DomainOrder.new(%{
          action: "BUY",
          total_quantity: 100,
          order_type: "LMT",
          scale_order_params: %{
            init_level_size: 100,
            subs_level_size: 50,
            auto_reset: true,
            random_percent: false
          },
          hedge_order_params: %{
            hedge_type: "delta",
            hedge_param: "0.5"
          },
          algo_params: %{
            algo_strategy: "Adaptive",
            algo_params: [
              %TagValue{tag: "adaptivePriority", value: "Normal"}
            ],
            algo_id: "algo123"
          }
        })

      roundtripped =
        original
        |> Mapper.to_proto()
        |> Mapper.from_proto()

      assert roundtripped.scale_order_params.init_level_size == 100
      assert roundtripped.scale_order_params.subs_level_size == 50
      assert roundtripped.scale_order_params.auto_reset == true
      assert roundtripped.scale_order_params.random_percent == false

      assert roundtripped.hedge_order_params.hedge_type == "delta"
      assert roundtripped.hedge_order_params.hedge_param == "0.5"

      assert roundtripped.algo_params.algo_strategy == "Adaptive"
      assert roundtripped.algo_params.algo_id == "algo123"
      assert length(roundtripped.algo_params.algo_params) == 1
      [tv] = roundtripped.algo_params.algo_params
      assert tv.tag == "adaptivePriority"
      assert tv.value == "Normal"
    end
  end
end
