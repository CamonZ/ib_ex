defmodule IbEx.Client.Messages.MarketData.RequestHistoricalData do
  @moduledoc """
  Request to get historical market data.

  The input parameters are the following:

  * request_id: non_neg_integer(). A unique identifier which will serve to identify the incoming data
  * contract: %IbEx.Client.Types.Contract{}. The contract you are working with
  * end_date_time: %DateTime{} | nil. The request’s end date and time. nil indicates current present moment
  * duration: {non_neg_integer(), duration_unit()}. The amount of time go back from the request’s given end date and time. A tuple consisting of any non negative integer followed by any `duration_unit()`.
  * bar_size: {ValidBarSizes[bar_size_unit()], bar_size_unit()}. Bar sizes dictate the data returned by historical bar requests. The bar size will dictate the scale over which the OHLC/V is returned to the API.
  * what_to_show: historical_bar_type(). The type of data to retrieve. 
  * use_rth: boolean(). Determines whether to return all data available during the requested time span, or only data that falls within regular trading hours. Possible values: 
      `true` - only return data within the regular trading hours, even if the requested time span falls partially or completely outside of the RTH. 
      `false` - return all data even where the market in question was outside of its regular trading hours.     
  * format_date: boolean(). The format in which the incoming bars’ date should be presented. Possible values:
      `true` - dates applying to bars returned in the format: yyyymmdd{space}{space}hh:mm:dd
      `false` - dates are returned as a long integer specifying the number of seconds since 1/1/1970 GMT.
  * keep_up_to_date: boolean(). Whether a subscription is made to return updates of unfinished real time bars as they are available (true), or all data is returned on a one-time basis (false). If `true` then `end_date_time` cannot be specified. Supported `what_to_show` values: `:trades`, `:midpoint`, `:bid`, `:ask`
  """

  @version 6

  defstruct version: @version,
            message_id: nil,
            request_id: nil,
            contract: nil,
            end_date_time: nil,
            duration: nil,
            bar_size: nil,
            what_to_show: nil,
            use_rth: false,
            format_date: false,
            keep_up_to_date: false

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Types.Contract

  @typedoc "Specifies unit of time to describe the overall length of time that data can be collected"
  @type duration_unit :: :second | :day | :week | :month | :year

  @typedoc "Possible values to vreate a valid_bar_size"
  @type bar_size_unit :: :second | :minute | :hour | :day | :week | :month

  @typedoc "These values are used to request different data. Some bar types support more products than others"
  @type historical_bar_type ::
          :aggtrades
          | :ask
          | :bid
          | :bid_ask
          | :fee_rate
          | :historical_volatility
          | :midpoint
          | :option_implied_volatility
          | :schedule
          | :trades
          | :yield_ask
          | :yield_bid_ask
          | :yield_last

  @type end_date_time_type :: DateTime.t() | nil
  @type duration_type :: {non_neg_integer(), duration_unit()}
  @type bar_size_type :: {non_neg_integer(), bar_size_unit()}
  @type t :: %__MODULE__{
          version: non_neg_integer(),
          message_id: non_neg_integer(),
          request_id: non_neg_integer(),
          contract: Contract.t(),
          end_date_time: end_date_time_type(),
          duration: duration_type(),
          bar_size: bar_size_type(),
          what_to_show: historical_bar_type(),
          use_rth: boolean(),
          format_date: boolean(),
          keep_up_to_date: boolean()
        }

  @spec new(
          non_neg_integer(),
          Contract.t(),
          end_date_time_type(),
          duration_type(),
          bar_size_type(),
          historical_bar_type(),
          boolean(),
          boolean(),
          boolean()
        ) ::
          {:ok, t()} | {:error, :not_implemented}
  def new(request_id, contract, end_date_time, duration, bar_size, what_to_show, use_rth, format_date, keep_up_to_date) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, message_id} ->
        {
          :ok,
          %__MODULE__{
            message_id: message_id,
            request_id: request_id,
            contract: contract,
            end_date_time: end_date_time,
            duration: duration,
            bar_size: bar_size,
            what_to_show: what_to_show,
            use_rth: use_rth,
            format_date: format_date,
            keep_up_to_date: keep_up_to_date
          }
        }

      :error ->
        {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base
    alias IbEx.Client.Types.Contract
    alias IbEx.Client.Messages.MarketData.RequestHistoricalData.Utils

    def to_string(msg) do
      fields = [
        msg.message_id,
        msg.version,
        msg.request_id,
        Contract.serialize(msg.contract, false),
        Utils.format_end_date_time(msg.end_date_time),
        Utils.format_duration(msg.duration),
        Utils.format_bar_size(msg.bar_size),
        Utils.format_what_to_show(msg.what_to_show),
        Utils.bool_to_int(msg.use_rth),
        Utils.bool_to_int(msg.format_date),
        Utils.bool_to_int(msg.keep_up_to_date)
      ]

      # TODO: implement BAG / Combo request fields 

      Base.build(fields)
    end
  end

  defimpl Inspect, for: __MODULE__ do
    alias IbEx.Client.Types.Contract
    alias IbEx.Client.Messages.MarketData.RequestHistoricalData.Utils

    def inspect(msg, _opts) do
      contract = Enum.join(Contract.serialize(msg.contract, false), ", ")

      """
      --> MarketData.RequestHistoricalData{
        request_id: #{msg.request_id},
        contract: #{contract},
        end_date_time: #{Utils.format_end_date_time(msg.end_date_time)},
        duration: #{Utils.format_duration(msg.duration)}, 
        bar_size: #{Utils.format_bar_size(msg.bar_size)},
        what_to_show: #{Utils.format_what_to_show(msg.what_to_show)},
        use_rth: #{Utils.bool_to_int(msg.use_rth)},
        format_date: #{Utils.bool_to_int(msg.format_date)},
        keep_up_to_date: #{Utils.bool_to_int(msg.keep_up_to_date)}
      }
      """
    end
  end

  defimpl IbEx.Client.Protocols.Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    # Subscription based on request_id, can handle multiple requests
    def subscribe(msg, pid, table_ref) do
      request_id = Subscriptions.subscribe_by_request_id(table_ref, pid)
      {:ok, %{msg | request_id: request_id}}
    end

    def lookup(_, _) do
      {:error, :lookup_not_necessary}
    end
  end
end
