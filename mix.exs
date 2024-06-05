defmodule IbEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :ib_ex,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {IbEx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:timex, "~> 3.7"},
      {:decimal, "~> 2.1"},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false}
    ]
  end
end
