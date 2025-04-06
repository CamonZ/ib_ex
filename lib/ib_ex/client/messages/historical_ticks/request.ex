defmodule IbEx.Client.Messages.HistoricalTicks.Request do
  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Protocols.Traceable

  @valid_what_to_show ["TRADES", "BID_ASK", "MIDPOINT"]

  defstruct message_id: nil,
            request_id: nil,
            contract: nil,
            start_datetime: nil,
            end_datetime: nil,
            number_of_ticks: nil,
            what_to_show: nil,
            use_rth_data: nil,
            ignore_size: nil,
            misc_options: nil

  def new(opts) when is_list(opts) do
    with {:ok, message_id} <- Requests.message_id_for(__MODULE__),
         request_id <- Keyword.get(opts, :request_id),
         {:ok, %Contract{} = contract} <- Keyword.fetch(opts, :contract),
         start_datetime <- Keyword.get(opts, :start_datetime),
         end_datetime <- Keyword.get(opts, :end_datetime),
         number_of_ticks <- Keyword.get(opts, :number_of_ticks, 1000),
         what_to_show <- Keyword.get(opts, :what_to_show, "TRADES"),
         use_rth_data <- Keyword.get(opts, :use_rth_data, false),
         ignore_size <- Keyword.get(opts, :ignore_size, false),
         misc_options <- Keyword.get(opts, :misc_options, []),
         true <- validate_timestamps(start_datetime, end_datetime),
         true <- validate_what_to_show(what_to_show) do
      {:ok,
       %__MODULE__{
         message_id: message_id,
         request_id: request_id,
         contract: contract,
         start_datetime: start_datetime,
         end_datetime: end_datetime,
         number_of_ticks: number_of_ticks,
         what_to_show: what_to_show,
         use_rth_data: use_rth_data,
         ignore_size: ignore_size,
         misc_options: misc_options
       }}
    else
      _ ->
        {:error, :invalid_args}
    end
  end

  def new(_) do
    {:error, :invalid_args}
  end

  defp validate_timestamps(start_dt, end_dt) do
    not is_nil(start_dt) or not is_nil(end_dt)
  end

  defp validate_what_to_show(wts) do
    wts in @valid_what_to_show
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
          Contract.serialize(msg.contract) ++
          [
            msg.start_datetime,
            msg.end_datetime,
            msg.number_of_ticks,
            msg.what_to_show,
            msg.use_rth_data,
            msg.ignore_size,
            msg.misc_options
          ]

      Base.build(fields)
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      --> %HistoricalTicks{
        message_id: #{msg.message_id}
        request_id: #{msg.request_id}
        contract: #{inspect(msg.contract)}
        start_datetime: #{msg.start_datetime}
        end_datetime: #{msg.end_datetime}
        number_of_ticks: #{msg.number_of_times}
        what_to_show: #{msg.what_to_show}
        use_rth_data: #{msg.use_rth_data}
        ignore_size: #{msg.ignore_size}
        misc_options: #{inspect(msg.misc_options)}
      }
      """
    end
  end
end
