defmodule IbEx.Client.Messages.ErrorInfo.Info do
  defstruct id: nil, code: nil, version: nil, message: nil

  alias IbEx.Client.Protocols.Traceable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- %Info{id: #{msg.id}, code: #{msg.code}, version: #{msg.version}, message: #{msg.message}}
      """
    end
  end
end
