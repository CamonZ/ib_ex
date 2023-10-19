defmodule IbEx.Client.Messages.ErrorInfo.Error do
  defstruct id: nil, code: nil, version: nil, message: nil

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      <-- %Error{id: #{msg.id}, code: #{msg.code}, version: #{msg.version}, message: #{msg.message}}
      """
    end
  end
end
