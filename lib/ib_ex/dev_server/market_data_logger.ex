if Mix.env() == :dev do
  defmodule IbEx.DevServer.MarketDataLogger do
    @moduledoc """
    Dev-only GenServer that subscribes to market data via the MarketDataManager
    and logs all PubSub events for a given symbol and type.

    Supports `:quotes` (L1), `:trades` (tick-by-tick), and `:depth` (L2).

    Start manually:

        alias IbEx.DevServer.MarketDataLogger
        opts = [pubsub: IbEx.PubSub, manager: IbEx.MarketDataManager]

        MarketDataLogger.start_link("AAPL", :quotes, opts)
        MarketDataLogger.start_link("AAPL", :trades, opts)
        MarketDataLogger.start_link("AAPL", :depth, opts)

    """

    use GenServer

    require Logger

    def start_link(symbol, type, opts) when type in [:quotes, :trades, :depth] do
      GenServer.start_link(__MODULE__, {symbol, type, opts})
    end

    def init({symbol, type, opts}) do
      pubsub = Keyword.fetch!(opts, :pubsub)
      manager = Keyword.fetch!(opts, :manager)
      subscription_id = "#{String.downcase(symbol)}-#{type}"

      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{subscription_id}")
      Process.send_after(self(), :subscribe, 5_000)

      {:ok, %{pubsub: pubsub, manager: manager, symbol: symbol, type: type, subscription_id: subscription_id}}
    end

    def handle_info(:subscribe, state) do
      sub_opts = if state.type == :depth, do: [num_rows: 10, is_smart_depth: true], else: []

      try do
        case IbEx.MarketDataManager.subscribe(
               state.manager,
               state.subscription_id,
               state.type,
               {:stock, state.symbol},
               sub_opts
             ) do
          :ok ->
            Logger.info("[MarketDataLogger] Subscribed to #{state.symbol} #{state.type} as #{state.subscription_id}")

          {:error, reason} ->
            Logger.error("[MarketDataLogger] Failed to subscribe: #{inspect(reason)}, retrying in 10s")
            Process.send_after(self(), :subscribe, 10_000)
        end
      catch
        :exit, reason ->
          Logger.warning("[MarketDataLogger] Subscribe call failed: #{inspect(reason)}, retrying in 10s")
          Process.send_after(self(), :subscribe, 10_000)
      end

      {:noreply, state}
    end

    def handle_info({:market_data_error, _data} = event, state) do
      Logger.warning("[MarketDataLogger:#{state.subscription_id}] #{inspect(event)}")
      {:noreply, state}
    end

    def handle_info(event, state) do
      Logger.info("[MarketDataLogger:#{state.subscription_id}] #{inspect(event)}")
      {:noreply, state}
    end
  end
end
