defmodule IbEx.Client.Subscriptions do
  @moduledoc """
  Handles initialization of the ETS table used by the client
  to map request ids or structs of a given message responses to the
  process that requested sending the message 
  """

  def initialize do
    table_ref = :ets.new(:message_subscriptions, [:set, :private])
    :ets.insert(table_ref, {:message_request_ids, 1})
    table_ref
  end

  def subscribe_by_request_id(table_ref, pid) do
    [message_request_ids: next_request_id] = :ets.lookup(table_ref, :message_request_ids)

    :ets.insert(table_ref, {to_string(next_request_id), pid})
    :ets.update_counter(table_ref, :message_request_ids, {2, 1})

    next_request_id
  end

  def subscribe_by_modules(table_ref, modules, pid) when is_list(modules) do
    Enum.each(modules, &:ets.insert(table_ref, {&1, pid}))
    :ok
  end

  def lookup(table_ref, key) do
    case :ets.lookup(table_ref, key) do
      [{_, pid}] ->
        {:ok, pid}

      _ ->
        {:error, :missing_subscription}
    end
  end
end
