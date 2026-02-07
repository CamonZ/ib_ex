defmodule IbEx.Client.Messages.CurrentTime.Request do
  defstruct id: nil

  @type t :: %__MODULE__{
          id: non_neg_integer()
        }

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  @spec new :: {:ok, __MODULE__.t()} | {:error, :message_not_implemented}
  def new do
    case Requests.message_id_for(__MODULE__) do
      {:ok, message_id} ->
        {:ok, %__MODULE__{id: message_id}}

      _ ->
        {:error, :message_not_implemented}
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "--> %CurrentTime{id: #{msg.id}}"
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Messages.CurrentTime.Response
    alias IbEx.Client.Subscriptions

    # Subscription based on message structs, can handle only 1 subscriber
    def subscribe(msg, pid, table_ref) do
      :ok = Subscriptions.subscribe_by_modules(table_ref, [Response], pid)
      {:ok, msg}
    end

    def lookup(_, _) do
      # Return an error when trying to lookup the subscriber of a message request,
      # only the response messages of a request need to be relayed back
      {:error, :lookup_not_necessary}
    end
  end
end
