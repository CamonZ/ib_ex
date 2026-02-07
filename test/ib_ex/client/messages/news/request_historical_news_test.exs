defmodule IbEx.Client.Messages.News.RequestHistoricalNewsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.RequestHistoricalNews
  alias IbEx.Client.Protocols.Traceable

  describe "new/6" do
    test "creates the message with valid inputs" do
      start_ts = ~U[2023-12-10 23:57:25.016925Z]
      end_ts = DateTime.add(start_ts, 3600)

      {:ok, msg} = RequestHistoricalNews.new(90001, 8314, "BRFG+BGRUPDN", start_ts, end_ts, 10)

      assert msg.message_id == 86
      assert msg.request_id == 90001
      assert msg.conid == 8314
      assert msg.provider_codes == "BRFG+BGRUPDN"
      assert msg.start_timestamp == "2023-12-10 23:57:25.0"
      assert msg.end_timestamp == "2023-12-11 00:57:25.0"
      assert msg.max_results == 10
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      msg = %RequestHistoricalNews{request_id: 90001, conid: 8314, provider_codes: "BRFG+BGRUPDN", max_results: 10}

      assert Traceable.to_s(msg) ==
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
