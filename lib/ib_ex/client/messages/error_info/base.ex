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

  def from_fieds([version_str, msg] = fields) do
    case Integer.parse(version_str) do
      {version, _} ->
        msg = %Error{
          version: version,
          message: msg
        }

        {:ok, msg}

      _ ->
        {:error, {:unexpected_error, fields}}
    end
  end

  def from_fields([version_str, id_str, code_str, msg_str, _] = fields) do
    with {version, _} <- Integer.parse(version_str),
         {id, _} <- Integer.parse(id_str),
         {code, _} <- Integer.parse(code_str) do
      msg = %{
        id: id,
        version: version,
        code: code,
        message: msg_str
      }

      if id == -1 do
        {:ok, struct(Info, msg)}
      else
        {:ok, struct(Error, msg)}
      end
    else
      _ ->
        Logger.error("Error parsing expected Error/Info message: #{inspect(fields)}")
        {:error, {:unexpected_error, fields}}
    end
  end

  def from_fields(fields) do
    Logger.warning("Trying to parse message as Error/Info: #{inspect(fields)}")
    {:error, {:invalid_args, fields}}
  end
end
