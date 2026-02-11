defmodule IbEx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children =
      if Mix.env() == :dev and Code.ensure_loaded?(IbEx.DevServer) do
        [IbEx.DevServer]
      else
        []
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IbEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
