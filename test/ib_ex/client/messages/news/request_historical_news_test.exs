defmodule IbEx.Client.Messages.News.RequestHistoricalNewsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.RequestHistoricalNews

  describe "new/6" do
    test "creates the message with valid inputs" do
      start_ts = ~U[2023-12-10 23:57:25.016925Z]
      end_ts = DateTime.add(start_ts, 3600)

      {:ok, msg} = RequestHistoricalNews.new("90001", 8314, "BRFG+BGRUPDN", start_ts, end_ts, 10)

      assert msg.message_id == 86
      assert msg.request_id == "90001"
      assert msg.conid == 8314
      assert msg.provider_codes == "BRFG+BGRUPDN"
      assert msg.start_timestamp == "2023-12-10 23:57:25.0"
      assert msg.end_timestamp == "2023-12-11 00:57:25.0"
      assert msg.max_results == 10
    end
  end

  describe "String.Chars implementation" do
    test "converts RequestHistoricalNews struct to string" do
      msg = %RequestHistoricalNews{
        message_id: 86,
        request_id: "90001",
        conid: 8314,
        provider_codes: "BRFG+BGRUPDN",
        start_timestamp: "2023-12-10 23:57:25.0",
        end_timestamp: "2023-12-11 00:57:25.0",
        max_results: 10
      }

      assert to_string(msg) ==
               <<56, 54, 0, 57, 48, 48, 48, 49, 0, 56, 51, 49, 52, 0, 66, 82, 70, 71, 43, 66, 71, 82, 85, 80, 68, 78, 0,
                 50, 48, 50, 51, 45, 49, 50, 45, 49, 48, 32, 50, 51, 58, 53, 55, 58, 50, 53, 46, 48, 0, 50, 48, 50, 51,
                 45, 49, 50, 45, 49, 49, 32, 48, 48, 58, 53, 55, 58, 50, 53, 46, 48, 0, 49, 48, 0, 0>>
    end
  end

  describe "Inspect implementation" do
    test "returns a human-readable version of the message" do
      msg = %RequestHistoricalNews{request_id: "90001", conid: 8314, provider_codes: "BRFG+BGRUPDN", max_results: 10}

      assert inspect(msg) ==
               """
               --> News.RequestHistoricalNews{
                 request_id: 90001,
                 conid: 8314,
                 provider_codes: BRFG+BGRUPDN,
                 start_timestamp: ,
                 end_timestamp: ,
                 max_results: 10
               }
               """
    end
  end
end
