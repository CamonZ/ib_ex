defprotocol IbEx.Client.Protocols.Traceable do
  @fallback_to_any true

  @doc """
  Turns the message into a string that can be used when tracing message flows
  """
  def to_s(msg)
end
