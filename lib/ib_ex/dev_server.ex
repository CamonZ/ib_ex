defmodule IbEx.DevServer do
  @moduledoc false

  use Supervisor

  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    port = Keyword.get(opts, :port, 4040)

    client_opts =
      [name: IbEx.Client, trace_messages: true]
      |> maybe_put_env(:host, "TWS_HOST", &parse_host/1)
      |> maybe_put_env(:port, "TWS_PORT", &String.to_integer/1)

    Logger.info("DevServer starting Client with opts: #{inspect(client_opts)}")

    children = [
      {Phoenix.PubSub, name: IbEx.PubSub},
      IbEx.TraceServer,
      {IbEx.Client, client_opts},
      {IbEx.Client.ContractResolver, client: IbEx.Client, name: IbEx.ContractResolver},
      {IbEx.MarketDataManager,
       client: IbEx.Client, resolver: IbEx.ContractResolver, pubsub: IbEx.PubSub, name: IbEx.MarketDataManager},
      {Bandit, plug: Tidewave, port: port}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp maybe_put_env(opts, key, env_var, parser) do
    case System.get_env(env_var) do
      nil -> opts
      value -> Keyword.put(opts, key, parser.(value))
    end
  end

  defp parse_host(host_string) do
    host_string
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end
end
