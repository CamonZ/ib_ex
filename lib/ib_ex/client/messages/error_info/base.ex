defmodule IbEx.Client.Messages.ErrorInfo.Base do
  alias IbEx.Client.Messages.ErrorInfo.Error
  alias IbEx.Client.Messages.ErrorInfo.Info

  require Logger

  def from_protobuf(payload) when is_binary(payload) do
    proto = IbEx.Client.Proto.Protobuf.ErrorMessage.decode(payload)

    msg = %{
      id: proto.id,
      code: proto.error_code,
      message: proto.error_msg
    }

    if proto.id == -1 do
      {:ok, struct(Info, msg)}
    else
      {:ok, struct(Error, msg)}
    end
  rescue
    err ->
      Logger.warning("Error decoding ErrorMessage protobuf: #{inspect(err)}")
      {:error, :decode_error}
  end
end
