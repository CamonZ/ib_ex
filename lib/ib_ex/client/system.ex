defmodule IbEx.Client.System do
  @moduledoc """
  Thematic module for system-level operations.

  Provides high-level functions for querying server time, setting log levels,
  retrieving configuration, and fetching user information. This module is
  stateless -- it builds proto request structs and delegates to `Client.request/3`
  or `Client.command/2`.

  ## Functions

  * `current_time/2` - Requests the server's current time in seconds
    (single request/response, global correlation).
  * `current_time_millis/2` - Requests the server's current time in milliseconds
    (single request/response, global correlation).
  * `set_log_level/2` - Sets the TWS server log verbosity level
    (fire-and-forget command, no response expected).
  * `config/2` - Requests the server configuration
    (single request/response, req_id correlation).
  * `user_info/2` - Requests information about the authenticated user
    (single request/response, req_id correlation).
  """

  alias IbEx.Client
  alias IbEx.Client.Proto.Protobuf, as: Proto

  @doc """
  Requests the server's current time in seconds (Unix epoch).

  Sends a `CurrentTimeRequest` through `Client.request/3` using global correlation.

  Returns `{:ok, %Proto.CurrentTime{}}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, %Proto.CurrentTime{current_time: unix_seconds}} = System.current_time(client)

  """
  @spec current_time(pid(), keyword()) :: {:ok, struct()} | {:error, any()}
  def current_time(client, opts \\ []) do
    request = %Proto.CurrentTimeRequest{}
    Client.request(client, request, opts)
  end

  @doc """
  Requests the server's current time in milliseconds (Unix epoch).

  Sends a `CurrentTimeInMillisRequest` through `Client.request/3` using global correlation.

  Returns `{:ok, %Proto.CurrentTimeInMillis{}}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, %Proto.CurrentTimeInMillis{current_time_in_millis: millis}} = System.current_time_millis(client)

  """
  @spec current_time_millis(pid(), keyword()) :: {:ok, struct()} | {:error, any()}
  def current_time_millis(client, opts \\ []) do
    request = %Proto.CurrentTimeInMillisRequest{}
    Client.request(client, request, opts)
  end

  @doc """
  Sets the TWS server log verbosity level.

  Sends a `SetServerLogLevelRequest` as a fire-and-forget command through
  `Client.command/2`. No response is expected from the server.

  ## Log Levels

  * `1` - System
  * `2` - Error
  * `3` - Warning
  * `4` - Information
  * `5` - Detail

  Returns `:ok`.

  ## Examples

      :ok = System.set_log_level(client, 5)

  """
  @spec set_log_level(pid(), integer()) :: :ok
  def set_log_level(client, log_level) when is_integer(log_level) do
    request = %Proto.SetServerLogLevelRequest{log_level: log_level}
    Client.command(client, request)
  end

  @doc """
  Requests the server configuration.

  Sends a `ConfigRequest` through `Client.request/3` using req_id correlation.

  Returns `{:ok, %Proto.ConfigResponse{}}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, %Proto.ConfigResponse{}} = System.config(client)

  """
  @spec config(pid(), keyword()) :: {:ok, struct()} | {:error, any()}
  def config(client, opts \\ []) do
    request = %Proto.ConfigRequest{}
    Client.request(client, request, opts)
  end

  @doc """
  Requests information about the authenticated user.

  Sends a `UserInfoRequest` through `Client.request/3` using req_id correlation.

  Returns `{:ok, %Proto.UserInfo{}}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, %Proto.UserInfo{white_branding_id: branding_id}} = System.user_info(client)

  """
  @spec user_info(pid(), keyword()) :: {:ok, struct()} | {:error, any()}
  def user_info(client, opts \\ []) do
    request = %Proto.UserInfoRequest{}
    Client.request(client, request, opts)
  end
end
