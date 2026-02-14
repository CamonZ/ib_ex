if Mix.env() == :dev do
  defmodule IbEx.DevServer do
    @moduledoc false

    use Supervisor

    def start_link(opts \\ []) do
      Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def init(opts) do
      port = Keyword.get(opts, :port, 4040)

      children = [
        {Phoenix.PubSub, name: IbEx.PubSub},
        IbEx.TraceServer,
        {IbEx.Client, name: IbEx.Client, trace_messages: true},
        {Bandit, plug: Tidewave, port: port}
      ]

      Supervisor.init(children, strategy: :one_for_one)
    end
  end
end
