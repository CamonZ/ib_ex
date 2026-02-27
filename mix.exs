defmodule IbEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :ib_ex,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:timex, "~> 3.7"},
      {:decimal, "~> 2.1"},
      {:protobuf, "~> 0.16"},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.34.0", only: [:dev], runtime: false},
      {:phoenix_pubsub, "~> 2.1"},
      {:bandit, "~> 1.0", only: :dev},
      {:tidewave, "~> 0.5", only: :dev}
    ]
  end

  defp aliases do
    []
  end
end
