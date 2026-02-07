defmodule IbEx.Client.Messages.ErrorInfo.Error do
  defstruct id: nil, code: nil, message: nil

  alias IbEx.Client.Protocols.Traceable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- %Error{id: #{msg.id}, code: #{msg.code}, message: #{msg.message}}
      """
    end
  end
end
