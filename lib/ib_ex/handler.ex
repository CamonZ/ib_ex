defmodule IbEx.Handler do
  @moduledoc """
  Base callback behaviour for middle layer event handlers.

  Defines common lifecycle callbacks that all domain-specific handlers share
  (e.g. connection state changes, errors). Domain managers invoke these
  callbacks on state changes so applications receive clean domain events
  without dealing with low-level protocol details.

  ## Usage

  Implement this behaviour in your application module:

      defmodule MyApp.Handler do
        use IbEx.Handler

        @impl IbEx.Handler
        def handle_connected(context) do
          Logger.info("Connected to TWS: \#{inspect(context)}")
          :ok
        end
      end

  All callbacks are optional. The `use IbEx.Handler` macro injects default
  no-op implementations that return `:ok`, so you only need to define the
  callbacks you care about.

  ## Extending with domain-specific callbacks

  Domain handler behaviours (e.g. a future `IbEx.OrderHandler`) should
  `use IbEx.Handler` in their own `__using__` macro to inherit the base
  callbacks and add domain-specific ones.
  """

  @type context :: map()

  @doc """
  Invoked when the client establishes a connection to TWS/Gateway.

  The `context` map contains connection metadata. Its contents may vary
  depending on which manager triggers it.
  """
  @callback handle_connected(context :: context()) :: :ok

  @doc """
  Invoked when the connection to TWS/Gateway is lost.

  The `context` map contains disconnection metadata such as the reason
  for disconnection when available.
  """
  @callback handle_disconnected(context :: context()) :: :ok

  @doc """
  Invoked when an error is received from TWS or occurs within a manager.

  The `error` term describes what went wrong. The `context` map provides
  additional metadata about where the error originated.
  """
  @callback handle_error(error :: term(), context :: context()) :: :ok

  @optional_callbacks [handle_connected: 1, handle_disconnected: 1, handle_error: 2]

  defmacro __using__(_opts) do
    quote do
      @behaviour IbEx.Handler

      @doc false
      def handle_connected(_context), do: :ok

      @doc false
      def handle_disconnected(_context), do: :ok

      @doc false
      def handle_error(_error, _context), do: :ok

      defoverridable handle_connected: 1, handle_disconnected: 1, handle_error: 2
    end
  end
end
