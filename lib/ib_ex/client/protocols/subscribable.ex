defprotocol IbEx.Client.Protocols.Subscribable do
  @moduledoc """
  Defines a protocol for message requests sent to TWS and their responses to be relayed back
  to a process through a mapping kept in an ETS table by our Client process.
  """

  @fallback_to_any true

  @doc """
  Subscribes a message and its responses to a subscriber process, either through a
  request_id in the message itself (when it's a field sent out in the request)
  or through mapping the response message struct with the subscriber process

  Returns the message
  """
  def subscribe(msg, subscriber_pid, table_id)

  @doc """
  Looks up the subscriber process for a given message

  Returns a PID
  """
  def lookup(msg, table_id)
end
