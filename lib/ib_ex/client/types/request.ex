defmodule IbEx.Client.Types.Request do
  @callback new(opts :: Keyword.t()) :: {:ok, map()} | {:error, reason :: term}
  @callback serialize(request :: map()) :: binary()
end
