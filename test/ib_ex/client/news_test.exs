defmodule IbEx.Client.NewsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.News
  alias IbEx.Client.Proto.Protobuf, as: Proto

  defmodule MockConnection do
    @moduledoc false
    use GenServer

    def start_link(opts) do
      client = Keyword.fetch!(opts, :client)
      GenServer.start_link(__MODULE__, %{client: client})
    end

    def send_message(_pid, _msg), do: :ok

    @impl true
    def init(state), do: {:ok, state}

    @impl true
    def handle_call(_, _, state), do: {:reply, :ok, state}
  end

  # Wire format helpers: raw wire_id = msg_id + @protobuf_offset (200)
  @news_providers_wire_id 285
  @news_article_wire_id 283
  @historical_news_wire_id 286
  @historical_news_end_wire_id 287
  @news_bulletin_wire_id 214
  @error_message_wire_id 204

  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp start_client do
    {:ok, pid} = Client.start_link(connection_handler: MockConnection)
    pid
  end

  describe "providers/2" do
    test "sends NewsProvidersRequest and returns {:ok, %NewsProviders{}} on response" do
      client = start_client()

      task =
        Task.async(fn ->
          News.providers(client, timeout: 5_000)
        end)

      Process.sleep(50)

      provider_1 = %Proto.NewsProvider{provider_code: "BRFG", provider_name: "Briefing.com General"}
      provider_2 = %Proto.NewsProvider{provider_code: "BRFUPDN", provider_name: "Briefing.com Upgrades/Downgrades"}

      response = %Proto.NewsProviders{news_providers: [provider_1, provider_2]}
      Client.process_message(client, wire_message(@news_providers_wire_id, response))

      assert {:ok, %Proto.NewsProviders{} = result} = Task.await(task, 5_000)
      assert length(result.news_providers) == 2

      [first, second] = result.news_providers
      assert first.provider_code == "BRFG"
      assert first.provider_name == "Briefing.com General"
      assert second.provider_code == "BRFUPDN"
      assert second.provider_name == "Briefing.com Upgrades/Downgrades"
    end

    test "returns {:ok, %NewsProviders{}} with empty list when no providers available" do
      client = start_client()

      task =
        Task.async(fn ->
          News.providers(client, timeout: 5_000)
        end)

      Process.sleep(50)

      response = %Proto.NewsProviders{news_providers: []}
      Client.process_message(client, wire_message(@news_providers_wire_id, response))

      assert {:ok, %Proto.NewsProviders{news_providers: []}} = Task.await(task, 5_000)
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          News.providers(client, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "article/3" do
    test "sends NewsArticleRequest and returns {:ok, %NewsArticle{}} on response" do
      client = start_client()

      task =
        Task.async(fn ->
          News.article(client, "BRFG", "BRFG$12345678", timeout: 5_000)
        end)

      Process.sleep(50)

      response = %Proto.NewsArticle{
        req_id: 1,
        article_type: 0,
        article_text: "This is the full article text content."
      }

      Client.process_message(client, wire_message(@news_article_wire_id, response))

      assert {:ok, %Proto.NewsArticle{} = result} = Task.await(task, 5_000)
      assert result.req_id == 1
      assert result.article_type == 0
      assert result.article_text == "This is the full article text content."
    end

    test "returns {:error, error} when TWS sends ErrorMessage for the req_id" do
      client = start_client()

      task =
        Task.async(fn ->
          News.article(client, "INVALID", "INVALID$999", timeout: 5_000)
        end)

      Process.sleep(50)

      error_proto = %Proto.ErrorMessage{
        id: 1,
        error_code: 200,
        error_msg: "No security definition has been found for the request"
      }

      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert {:error, error} = Task.await(task, 5_000)
      assert %IbEx.Client.Types.Error{} = error
      assert error.id == 1
      assert error.code == 200
      assert error.message == "No security definition has been found for the request"
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          News.article(client, "BRFG", "BRFG$12345678", timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "historical/3" do
    test "accumulates HistoricalNews responses and returns {:ok, list} on HistoricalNewsEnd" do
      client = start_client()

      task =
        Task.async(fn ->
          News.historical(client, 265_598, provider_codes: "BRFG", timeout: 5_000)
        end)

      Process.sleep(50)

      headline_1 = %Proto.HistoricalNews{
        req_id: 1,
        time: "2024-01-15 10:30:00",
        provider_code: "BRFG",
        article_id: "BRFG$12345678",
        headline: "AAPL: Apple reports record earnings"
      }

      headline_2 = %Proto.HistoricalNews{
        req_id: 1,
        time: "2024-01-14 09:00:00",
        provider_code: "BRFG",
        article_id: "BRFG$12345679",
        headline: "AAPL: New product announcement expected"
      }

      Client.process_message(client, wire_message(@historical_news_wire_id, headline_1))
      Client.process_message(client, wire_message(@historical_news_wire_id, headline_2))

      end_marker = %Proto.HistoricalNewsEnd{req_id: 1, has_more: false}
      Client.process_message(client, wire_message(@historical_news_end_wire_id, end_marker))

      assert {:ok, results} = Task.await(task, 5_000)
      assert length(results) == 2

      [first, second] = results
      assert %Proto.HistoricalNews{} = first
      assert first.time == "2024-01-15 10:30:00"
      assert first.provider_code == "BRFG"
      assert first.article_id == "BRFG$12345678"
      assert first.headline == "AAPL: Apple reports record earnings"

      assert %Proto.HistoricalNews{} = second
      assert second.time == "2024-01-14 09:00:00"
      assert second.article_id == "BRFG$12345679"
      assert second.headline == "AAPL: New product announcement expected"
    end

    test "returns {:ok, []} when no historical news exists" do
      client = start_client()

      task =
        Task.async(fn ->
          News.historical(client, 265_598, timeout: 5_000)
        end)

      Process.sleep(50)

      end_marker = %Proto.HistoricalNewsEnd{req_id: 1, has_more: false}
      Client.process_message(client, wire_message(@historical_news_end_wire_id, end_marker))

      assert {:ok, []} = Task.await(task, 5_000)
    end

    test "returns {:error, error} when TWS sends ErrorMessage for the req_id" do
      client = start_client()

      task =
        Task.async(fn ->
          News.historical(client, 999_999, timeout: 5_000)
        end)

      Process.sleep(50)

      error_proto = %Proto.ErrorMessage{
        id: 1,
        error_code: 200,
        error_msg: "No security definition has been found for the request"
      }

      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert {:error, error} = Task.await(task, 5_000)
      assert %IbEx.Client.Types.Error{} = error
      assert error.id == 1
      assert error.code == 200
      assert error.message == "No security definition has been found for the request"
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          News.historical(client, 265_598, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "subscribe_bulletins/2" do
    test "subscribes to news bulletins and receives NewsBulletin messages" do
      client = start_client()

      {:ok, ref} = News.subscribe_bulletins(client)
      assert is_reference(ref)

      bulletin = %Proto.NewsBulletin{
        news_msg_id: 1,
        news_msg_type: 1,
        news_message: "Exchange NYSE is experiencing connectivity issues.",
        originating_exch: "NYSE"
      }

      Client.process_message(client, wire_message(@news_bulletin_wire_id, bulletin))

      assert_receive {:ib_ex, ^ref, %Proto.NewsBulletin{} = received}, 1_000
      assert received.news_msg_id == 1
      assert received.news_msg_type == 1
      assert received.news_message == "Exchange NYSE is experiencing connectivity issues."
      assert received.originating_exch == "NYSE"
    end

    test "receives multiple NewsBulletin messages on the same subscription" do
      client = start_client()

      {:ok, ref} = News.subscribe_bulletins(client)

      bulletin_1 = %Proto.NewsBulletin{
        news_msg_id: 1,
        news_msg_type: 1,
        news_message: "First bulletin message.",
        originating_exch: "NYSE"
      }

      bulletin_2 = %Proto.NewsBulletin{
        news_msg_id: 2,
        news_msg_type: 2,
        news_message: "Second bulletin message.",
        originating_exch: "NASDAQ"
      }

      Client.process_message(client, wire_message(@news_bulletin_wire_id, bulletin_1))
      Client.process_message(client, wire_message(@news_bulletin_wire_id, bulletin_2))

      assert_receive {:ib_ex, ^ref, %Proto.NewsBulletin{news_msg_id: 1, originating_exch: "NYSE"}}, 1_000
      assert_receive {:ib_ex, ^ref, %Proto.NewsBulletin{news_msg_id: 2, originating_exch: "NASDAQ"}}, 1_000
    end

    test "accepts all_messages option" do
      client = start_client()

      {:ok, ref} = News.subscribe_bulletins(client, all_messages: false)
      assert is_reference(ref)
    end
  end

  describe "unsubscribe_bulletins/2" do
    test "cancels an active news bulletins subscription" do
      client = start_client()

      {:ok, ref} = News.subscribe_bulletins(client)
      assert :ok = News.unsubscribe_bulletins(client, ref)
    end

    test "returns error for unknown subscription ref" do
      client = start_client()
      fake_ref = make_ref()

      assert {:error, :not_found} = News.unsubscribe_bulletins(client, fake_ref)
    end
  end
end
