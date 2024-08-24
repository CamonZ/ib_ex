defmodule IbEx.Client.Messages.MarketData.RequestHistoricalData do
  @moduledoc """
  Request to get historical market data.

  The input parameters are the following:

  * request_id: non_neg_integer(). A unique identifier which will serve to identify the incoming data
  * contract: %IbEx.Client.Types.Contract{}. The contract you are working with
  * end_date_time: %DateTime{} | nil. The request’s end date and time. nil indicates current present moment
  * duration: {non_neg_integer(), duration_unit()}. The amount of time go back from the request’s given end date and time. A tuple consisting of any non negative integer followed by any `duration_unit()`.
  * bar_size: {ValidBarSizes[bar_size_unit()], bar_size_unit()}. Bar sizes dictate the data returned by historical bar requests. The bar size will dictate the scale over which the OHLC/V is returned to the API.
  * what_to_show: WhatToShow.t(). The type of data to retrieve. 
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

  alias IbEx.Client.Constants.{WhatToShow, BarSizes, Durations}
  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Utils

  @type end_date_time_type :: DateTime.t() | nil
  @type t :: %__MODULE__{
          version: non_neg_integer(),
          message_id: non_neg_integer(),
          request_id: non_neg_integer(),
          contract: Contract.t(),
          end_date_time: end_date_time_type(),
          duration: String.t(),
          bar_size: String.t(),
          what_to_show: String.t(),
          use_rth: boolean(),
          keep_up_to_date: boolean()
        }

  @spec new(
          Contract.t(),
          end_date_time_type(),
          Durations.t(),
          BarSizes.t(),
          WhatToShow.t(),
          boolean(),
          boolean()
        ) ::
          {:ok, t()} | {:error, :not_implemented}
  def new(
        %Contract{} = contract,
        end_date_time,
        duration,
        bar_size,
        what_to_show,
        use_rth,
        keep_up_to_date
      ) do
    with {:ok, message_id} <- Requests.message_id_for(__MODULE__),
         {:ok, end_date_time} <- format_end_date_time(end_date_time),
         {:ok, duration} <- Durations.format(duration),
         {:ok, bar_size} <- BarSizes.format(bar_size),
         {:ok, what_to_show} <- WhatToShow.format(what_to_show),
         {:ok, use_rth} <- Utils.bool_to_int(use_rth),
         {:ok, keep_up_to_date} <- Utils.bool_to_int(keep_up_to_date) do
      {
        :ok,
        %__MODULE__{
          message_id: message_id,
          contract: contract,
          end_date_time: end_date_time,
          duration: duration,
          bar_size: bar_size,
          what_to_show: what_to_show,
          use_rth: use_rth,
          format_date: 2,
          keep_up_to_date: keep_up_to_date
        }
      }
    else
      {:error, :invalid_args} = error ->
        error

      _ ->
        {:error, :not_implemented}
    end
  end

  @spec format_end_date_time(end_date_time_type()) :: {:ok, String.t()} | {:error, :invalid_args}
  def format_end_date_time(%DateTime{} = unit) do
    {:ok,
     unit
     |> DateTime.to_string()
     |> String.replace(["-", "Z"], "")
     |> String.replace(" ", "-")}
  end

  def format_end_date_time(nil), do: {:ok, ""}

  def format_end_date_time(_) do
    {:error, :invalid_args}
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base
    alias IbEx.Client.Types.Contract

    def to_string(msg) do
      fields =
        [
          msg.message_id,
          msg.request_id
        ] ++
          Contract.serialize(msg.contract, true) ++
          [
            msg.end_date_time,
            msg.bar_size,
            msg.duration,
            msg.use_rth,
            msg.what_to_show,
            msg.format_date,
            msg.keep_up_to_date,
            []
          ]

      # TODO: implement BAG / Combo request fields 

      Base.build(fields)
    end
  end

  defimpl Inspect, for: __MODULE__ do
    alias IbEx.Client.Types.Contract

    def inspect(msg, _opts) do
      contract = Enum.join(Contract.serialize(msg.contract, false), ", ")

      """
      --> MarketData.RequestHistoricalData{
        request_id: #{msg.request_id},
        contract: #{contract},
        end_date_time: #{msg.end_date_time},
        duration: #{msg.duration}, 
        bar_size: #{msg.bar_size},
        what_to_show: #{msg.what_to_show},
        use_rth: #{msg.use_rth},
        format_date: 2,
        keep_up_to_date: #{msg.keep_up_to_date}
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
