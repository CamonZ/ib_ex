defmodule IbEx.Client.HistoricalData do
  @moduledoc """
  Thematic module for historical data operations.

  Provides high-level functions for requesting historical bars, head timestamps,
  histogram data, and historical ticks. This module is stateless -- it builds
  proto request structs and delegates to `Client.request/3` or `Client.subscribe/3`.

  ## Functions

  * `request_bars/3` - Requests historical OHLCV bars for a contract
    (bounded stream: accumulates HistoricalData responses, ends with HistoricalDataEnd).
  * `head_timestamp/3` - Requests the earliest available data point for a contract
    (single request/response).
  * `histogram/3` - Requests histogram data for a contract
    (single request/response).
  * `request_ticks/3` - Subscribes to historical tick data for a contract
    (stream of HistoricalTicks/HistoricalTicksBidAsk/HistoricalTicksLast batches,
    each carrying an `is_done` flag indicating whether more data follows).
  * `unsubscribe_ticks/2` - Cancels a historical ticks subscription.
  """

  alias IbEx.Client
  alias IbEx.Client.Proto.Mapper
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Types.Contract, as: DomainContract

  @doc """
  Requests historical OHLCV bars for the given contract.

  Accepts domain contracts or proto contracts and sends a `HistoricalDataRequest`
  through `Client.request/3`.

  Returns `{:ok, [%Proto.HistoricalData{}, ...]}` on success (accumulated list),
  or `{:error, reason}` on failure.

  ## Options

  * `:end_date_time` - End date/time string (default: `""`)
  * `:duration` - Duration string, e.g. `"1 D"`, `"1 W"` (default: `"1 D"`)
  * `:bar_size_setting` - Bar size, e.g. `"1 hour"`, `"1 day"` (default: `"1 day"`)
  * `:what_to_show` - Data type: `"TRADES"`, `"MIDPOINT"`, `"BID"`, `"ASK"` (default: `"TRADES"`)
  * `:use_rth` - Use regular trading hours only (default: `true`)
  * `:format_date` - Date format: 1 for yyyyMMdd, 2 for epoch (default: `1`)
  * `:keep_up_to_date` - Keep updating with new bars (default: `false`)
  * `:chart_options` - Map of chart options (default: `%{}`)

  ## Examples

      contract = %IbEx.Client.Types.Contract{symbol: "AAPL", security_type: "STK", currency: "USD"}
      {:ok, bars_list} = HistoricalData.request_bars(client, contract)

  """
  @spec request_bars(pid(), struct(), keyword()) :: {:ok, list()} | {:error, any()}
  def request_bars(client, contract, opts \\ [])

  def request_bars(client, %Proto.Contract{} = proto_contract, opts) do
    request = build_historical_data_request(proto_contract, opts)
    Client.request(client, request, opts)
  end

  def request_bars(client, %DomainContract{} = contract, opts) do
    request_bars(client, Mapper.to_proto(contract), opts)
  end

  @doc """
  Requests the earliest available data point for the given contract.

  Accepts domain contracts or proto contracts and sends a `HeadTimestampRequest`
  through `Client.request/3`.

  Returns `{:ok, %Proto.HeadTimestamp{}}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:what_to_show` - Data type: `"TRADES"`, `"MIDPOINT"`, `"BID"`, `"ASK"` (default: `"TRADES"`)
  * `:use_rth` - Use regular trading hours only (default: `true`)
  * `:format_date` - Date format: 1 for yyyyMMdd, 2 for epoch (default: `1`)

  ## Examples

      contract = %IbEx.Client.Types.Contract{symbol: "AAPL", security_type: "STK", currency: "USD"}
      {:ok, %Proto.HeadTimestamp{}} = HistoricalData.head_timestamp(client, contract)

  """
  @spec head_timestamp(pid(), struct(), keyword()) :: {:ok, struct()} | {:error, any()}
  def head_timestamp(client, contract, opts \\ [])

  def head_timestamp(client, %Proto.Contract{} = proto_contract, opts) do
    request = build_head_timestamp_request(proto_contract, opts)
    Client.request(client, request, opts)
  end

  def head_timestamp(client, %DomainContract{} = contract, opts) do
    head_timestamp(client, Mapper.to_proto(contract), opts)
  end

  @doc """
  Requests histogram data for the given contract.

  Accepts domain contracts or proto contracts and sends a `HistogramDataRequest`
  through `Client.request/3`.

  Returns `{:ok, %Proto.HistogramData{}}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:use_rth` - Use regular trading hours only (default: `true`)
  * `:time_period` - Time period string, e.g. `"1 week"` (default: `"1 week"`)

  ## Examples

      contract = %IbEx.Client.Types.Contract{symbol: "AAPL", security_type: "STK", currency: "USD"}
      {:ok, %Proto.HistogramData{}} = HistoricalData.histogram(client, contract)

  """
  @spec histogram(pid(), struct(), keyword()) :: {:ok, struct()} | {:error, any()}
  def histogram(client, contract, opts \\ [])

  def histogram(client, %Proto.Contract{} = proto_contract, opts) do
    request = build_histogram_request(proto_contract, opts)
    Client.request(client, request, opts)
  end

  def histogram(client, %DomainContract{} = contract, opts) do
    histogram(client, Mapper.to_proto(contract), opts)
  end

  @doc """
  Subscribes to historical tick data for the given contract.

  Accepts domain contracts or proto contracts and sends a `HistoricalTicksRequest`
  through `Client.subscribe/3`. The caller receives `{:ib_ex, subscription_ref, msg}`
  messages with `HistoricalTicks`, `HistoricalTicksBidAsk`, or `HistoricalTicksLast` protos.

  Each response batch includes an `is_done` field -- when `true`, no more data follows
  for the requested range.

  Returns `{:ok, subscription_ref}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:start_date_time` - Start date/time string (default: `""`)
  * `:end_date_time` - End date/time string (default: `""`)
  * `:number_of_ticks` - Number of ticks to request, max 1000 (default: `1000`)
  * `:what_to_show` - Data type: `"TRADES"`, `"MIDPOINT"`, `"BID_ASK"` (default: `"TRADES"`)
  * `:use_rth` - Use regular trading hours only (default: `true`)
  * `:ignore_size` - Ignore size in tick data (default: `false`)

  ## Examples

      contract = %IbEx.Client.Types.Contract{symbol: "AAPL", security_type: "STK", currency: "USD"}
      {:ok, ref} = HistoricalData.request_ticks(client, contract)

  """
  @spec request_ticks(pid(), struct(), keyword()) :: {:ok, reference()} | {:error, any()}
  def request_ticks(client, contract, opts \\ [])

  def request_ticks(client, %Proto.Contract{} = proto_contract, opts) do
    request = build_historical_ticks_request(proto_contract, opts)
    Client.subscribe(client, request, opts)
  end

  def request_ticks(client, %DomainContract{} = contract, opts) do
    request_ticks(client, Mapper.to_proto(contract), opts)
  end

  @doc """
  Cancels a historical ticks subscription.

  Delegates to `Client.unsubscribe/2` which sends a `CancelHistoricalTicks` message.

  Returns `:ok` on success, or `{:error, :not_found}` if the subscription does not exist.

  ## Examples

      :ok = HistoricalData.unsubscribe_ticks(client, subscription_ref)

  """
  @spec unsubscribe_ticks(pid(), reference()) :: :ok | {:error, :not_found}
  def unsubscribe_ticks(client, subscription_ref) do
    Client.unsubscribe(client, subscription_ref)
  end

  defp build_historical_data_request(proto_contract, opts) do
    %Proto.HistoricalDataRequest{
      contract: proto_contract,
      end_date_time: Keyword.get(opts, :end_date_time, ""),
      duration: Keyword.get(opts, :duration, "1 D"),
      bar_size_setting: Keyword.get(opts, :bar_size_setting, "1 day"),
      what_to_show: Keyword.get(opts, :what_to_show, "TRADES"),
      use_rth: Keyword.get(opts, :use_rth, true),
      format_date: Keyword.get(opts, :format_date, 1),
      keep_up_to_date: Keyword.get(opts, :keep_up_to_date, false),
      chart_options: Keyword.get(opts, :chart_options, %{})
    }
  end

  defp build_head_timestamp_request(proto_contract, opts) do
    %Proto.HeadTimestampRequest{
      contract: proto_contract,
      what_to_show: Keyword.get(opts, :what_to_show, "TRADES"),
      use_rth: Keyword.get(opts, :use_rth, true),
      format_date: Keyword.get(opts, :format_date, 1)
    }
  end

  defp build_histogram_request(proto_contract, opts) do
    %Proto.HistogramDataRequest{
      contract: proto_contract,
      use_rth: Keyword.get(opts, :use_rth, true),
      time_period: Keyword.get(opts, :time_period, "1 week")
    }
  end

  defp build_historical_ticks_request(proto_contract, opts) do
    %Proto.HistoricalTicksRequest{
      contract: proto_contract,
      start_date_time: Keyword.get(opts, :start_date_time, ""),
      end_date_time: Keyword.get(opts, :end_date_time, ""),
      number_of_ticks: Keyword.get(opts, :number_of_ticks, 1000),
      what_to_show: Keyword.get(opts, :what_to_show, "TRADES"),
      use_rth: Keyword.get(opts, :use_rth, true),
      ignore_size: Keyword.get(opts, :ignore_size, false)
    }
  end
end
