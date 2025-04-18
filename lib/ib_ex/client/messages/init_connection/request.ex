defmodule IbEx.Client.Messages.InitConnection.Request do
  @moduledoc """
  This message is the first one sent during the connection initialization process
  """

  @prefix "API"

  defstruct prefix: @prefix, version: nil

  alias IbEx.Client.Constants.ServerVersions
  alias IbEx.Client.Protocols.Traceable

  def new do
    {:ok, %__MODULE__{version: ServerVersions.client_version()}}
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Connection.Frame

    def to_string(msg) do
      Enum.join([msg.prefix, Frame.pack(msg.version)], "\x00")
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "--> API, #{msg.version}"
    end
  end
end
