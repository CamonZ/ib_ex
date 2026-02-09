defmodule IbEx.Client.Scanner do
  @moduledoc """
  Thematic module for market scanner operations.

  Provides high-level functions for subscribing to scanner data streams,
  cancelling scanner subscriptions, and requesting scanner parameters.
  This module is stateless -- it builds proto request structs and delegates
  to `Client.subscribe/3`, `Client.unsubscribe/2`, and `Client.request/3`.

  ## Functions

  * `subscribe/3` - Subscribes to a scanner data stream for the given subscription criteria
    (ScannerData).
  * `unsubscribe/2` - Cancels a scanner subscription.
  * `parameters/2` - Requests the XML document describing available scanner parameters.
  """

  alias IbEx.Client
  alias IbEx.Client.Proto.Protobuf, as: Proto

  @doc """
  Subscribes to a scanner data stream for the given subscription criteria.

  Builds a `ScannerSubscriptionRequest` and sends it through `Client.subscribe/3`.
  The caller receives `{:ib_ex, subscription_ref, msg}` messages with
  ScannerData protos.

  Returns `{:ok, subscription_ref}` on success, or `{:error, reason}` on failure.

  ## Options

  * Currently unused, reserved for future options.

  ## Examples

      scanner_sub = %IbEx.Client.Proto.Protobuf.ScannerSubscription{
        instrument: "STK",
        location_code: "STK.US.MAJOR",
        scan_code: "TOP_PERC_GAIN",
        number_of_rows: 10
      }
      {:ok, ref} = Scanner.subscribe(client, scanner_sub)

  """
  @spec subscribe(pid(), struct(), keyword()) :: {:ok, reference()} | {:error, any()}
  def subscribe(client, scanner_subscription, opts \\ [])

  def subscribe(client, %Proto.ScannerSubscription{} = scanner_subscription, opts) do
    request = %Proto.ScannerSubscriptionRequest{scanner_subscription: scanner_subscription}
    Client.subscribe(client, request, opts)
  end

  @doc """
  Cancels a scanner subscription.

  Delegates to `Client.unsubscribe/2` which sends a `CancelScannerSubscription`
  message and removes the subscription.

  Returns `:ok` on success, or `{:error, :not_found}` if the subscription does not exist.

  ## Examples

      :ok = Scanner.unsubscribe(client, subscription_ref)

  """
  @spec unsubscribe(pid(), reference()) :: :ok | {:error, :not_found}
  def unsubscribe(client, subscription_ref) do
    Client.unsubscribe(client, subscription_ref)
  end

  @doc """
  Requests the XML document describing available scanner parameters.

  Sends a `ScannerParametersRequest` through `Client.request/3` using global
  correlation (no req_id). Returns the XML string containing all available
  scanner parameters, instruments, locations, and scan codes.

  Returns `{:ok, %Proto.ScannerParameters{}}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, %Proto.ScannerParameters{} = result} = Scanner.parameters(client)
      result.xml

  """
  @spec parameters(pid(), keyword()) :: {:ok, struct()} | {:error, any()}
  def parameters(client, opts \\ []) do
    request = %Proto.ScannerParametersRequest{}
    Client.request(client, request, opts)
  end
end
