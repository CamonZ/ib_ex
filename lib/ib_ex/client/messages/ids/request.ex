defmodule IbEx.Client.Messages.Ids.Request do
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Traceable

  defstruct message_id: nil

  def new do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {:ok, %__MODULE__{message_id: id}}

      :error ->
        {:error, :not_implemented}
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(_msg) do
      "--> Ids.Request{}"
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    def subscribe(msg, _pid, _table_ref) do
      {:ok, msg}
    end

    def lookup(_, _) do
      {:error, :lookup_not_necessary}
    end
  end
end
