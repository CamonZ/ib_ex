defmodule IbEx.Client.Messages.InitConnection.Request do
  @moduledoc """
  This message is the first one sent during the connection initialization process
  """

  @prefix "API"

  defstruct prefix: @prefix, version: nil

  alias IbEx.Client.Constants.ServerVersions

  def new do
    {:ok, %__MODULE__{version: ServerVersions.client_version()}}
  end

  defimpl String.Chars, for: __MODULE__ do
    def to_string(msg) do
      packed_version = String.slice(:erlang.term_to_binary(msg.version), 2..-1//1)
      Enum.join([msg.prefix, packed_version], "\x00")
    end
  end
end
