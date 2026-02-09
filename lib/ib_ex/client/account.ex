defmodule IbEx.Client.Account do
  @moduledoc """
  Thematic module for account operations.

  Provides high-level functions for querying account data, positions, summaries,
  and P&L information. This module is stateless -- it builds proto request structs
  and delegates to `Client.request/3` or `Client.subscribe/3`.

  ## Functions

  * `request_updates/3` - Requests account data updates
    (bounded stream: accumulates AccountValue, PortfolioValue, AccountUpdateTime responses,
    ends with AccountDataEnd, global correlation).
  * `positions/2` - Requests current positions
    (bounded stream: accumulates Position responses, ends with PositionEnd, global correlation).
  * `summary/2` - Requests account summary
    (bounded stream: accumulates AccountSummary responses, ends with AccountSummaryEnd, req_id correlation).
  * `positions_multi/3` - Requests positions for multiple accounts/models
    (bounded stream: accumulates PositionMulti responses, ends with PositionMultiEnd, req_id correlation).
  * `updates_multi/3` - Requests account updates for multiple accounts/models
    (bounded stream: accumulates AccountUpdateMulti responses, ends with AccountUpdateMultiEnd, req_id correlation).
  * `pnl/3` - Subscribes to P&L updates for an account
    (stream subscription with req_id correlation, receives PnL protos).
  * `pnl_single/4` - Subscribes to single-position P&L updates
    (stream subscription with req_id correlation, receives PnLSingle protos).
  * `unsubscribe_pnl/2` - Cancels a P&L subscription.
  * `unsubscribe_pnl_single/2` - Cancels a single-position P&L subscription.
  """

  alias IbEx.Client
  alias IbEx.Client.Proto.Protobuf, as: Proto

  @doc """
  Requests account data updates for the given account.

  Sends an `AccountDataRequest` through `Client.request/3` using global correlation.
  The response is a bounded stream that accumulates `AccountValue`, `PortfolioValue`,
  and `AccountUpdateTime` protos and ends with an `AccountDataEnd` marker.

  Returns `{:ok, [%Proto.AccountValue{} | %Proto.PortfolioValue{} | %Proto.AccountUpdateTime{}, ...]}` on success,
  or `{:error, reason}` on failure.

  ## Options

  * `:subscribe` - Whether to subscribe to updates (default: `true`)
  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, updates} = Account.request_updates(client, "DU123456")

  """
  @spec request_updates(pid(), String.t(), keyword()) :: {:ok, list()} | {:error, any()}
  def request_updates(client, acct_code, opts \\ []) do
    request = %Proto.AccountDataRequest{
      subscribe: Keyword.get(opts, :subscribe, true),
      acct_code: acct_code
    }

    Client.request(client, request, opts)
  end

  @doc """
  Requests current positions.

  Sends a `PositionsRequest` through `Client.request/3` using global correlation.
  The response is a bounded stream that accumulates `Position` protos and ends
  with a `PositionEnd` marker.

  Returns `{:ok, [%Proto.Position{}, ...]}` on success (accumulated list),
  or `{:error, reason}` on failure.

  ## Options

  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, positions} = Account.positions(client)

  """
  @spec positions(pid(), keyword()) :: {:ok, list()} | {:error, any()}
  def positions(client, opts \\ []) do
    request = %Proto.PositionsRequest{}
    Client.request(client, request, opts)
  end

  @doc """
  Requests account summary.

  Sends an `AccountSummaryRequest` through `Client.request/3` using req_id correlation.
  The response is a bounded stream that accumulates `AccountSummary` protos and ends
  with an `AccountSummaryEnd` marker.

  Returns `{:ok, [%Proto.AccountSummary{}, ...]}` on success (accumulated list),
  or `{:error, reason}` on failure.

  ## Options

  * `:group` - Account group, e.g. `"All"` (default: `"All"`)
  * `:tags` - Comma-separated tags, e.g. `"NetLiquidation,TotalCashValue"` (default: `"$LEDGER"`)
  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, summaries} = Account.summary(client)
      {:ok, summaries} = Account.summary(client, group: "All", tags: "NetLiquidation,TotalCashValue")

  """
  @spec summary(pid(), keyword()) :: {:ok, list()} | {:error, any()}
  def summary(client, opts \\ []) do
    request = %Proto.AccountSummaryRequest{
      group: Keyword.get(opts, :group, "All"),
      tags: Keyword.get(opts, :tags, "$LEDGER")
    }

    Client.request(client, request, opts)
  end

  @doc """
  Requests positions for multiple accounts/models.

  Sends a `PositionsMultiRequest` through `Client.request/3` using req_id correlation.
  The response is a bounded stream that accumulates `PositionMulti` protos and ends
  with a `PositionMultiEnd` marker.

  Returns `{:ok, [%Proto.PositionMulti{}, ...]}` on success (accumulated list),
  or `{:error, reason}` on failure.

  ## Options

  * `:model_code` - Model code filter (default: `""`)
  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, positions} = Account.positions_multi(client, "DU123456")
      {:ok, positions} = Account.positions_multi(client, "DU123456", model_code: "myModel")

  """
  @spec positions_multi(pid(), String.t(), keyword()) :: {:ok, list()} | {:error, any()}
  def positions_multi(client, account, opts \\ []) do
    request = %Proto.PositionsMultiRequest{
      account: account,
      model_code: Keyword.get(opts, :model_code, "")
    }

    Client.request(client, request, opts)
  end

  @doc """
  Requests account updates for multiple accounts/models.

  Sends an `AccountUpdatesMultiRequest` through `Client.request/3` using req_id correlation.
  The response is a bounded stream that accumulates `AccountUpdateMulti` protos and ends
  with an `AccountUpdateMultiEnd` marker.

  Returns `{:ok, [%Proto.AccountUpdateMulti{}, ...]}` on success (accumulated list),
  or `{:error, reason}` on failure.

  ## Options

  * `:model_code` - Model code filter (default: `""`)
  * `:ledger_and_nlv` - Whether to include ledger and NLV data (default: `true`)
  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, updates} = Account.updates_multi(client, "DU123456")
      {:ok, updates} = Account.updates_multi(client, "DU123456", model_code: "myModel")

  """
  @spec updates_multi(pid(), String.t(), keyword()) :: {:ok, list()} | {:error, any()}
  def updates_multi(client, account, opts \\ []) do
    request = %Proto.AccountUpdatesMultiRequest{
      account: account,
      model_code: Keyword.get(opts, :model_code, ""),
      ledger_and_nlv: Keyword.get(opts, :ledger_and_nlv, true)
    }

    Client.request(client, request, opts)
  end

  @doc """
  Subscribes to P&L updates for the given account.

  Builds a `PnLRequest` and sends it through `Client.subscribe/3`.
  The caller receives `{:ib_ex, subscription_ref, msg}` messages with PnL protos.

  Returns `{:ok, subscription_ref}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:model_code` - Model code filter (default: `""`)

  ## Examples

      {:ok, ref} = Account.pnl(client, "DU123456")
      {:ok, ref} = Account.pnl(client, "DU123456", model_code: "myModel")

  """
  @spec pnl(pid(), String.t(), keyword()) :: {:ok, reference()} | {:error, any()}
  def pnl(client, account, opts \\ []) do
    request = %Proto.PnLRequest{
      account: account,
      model_code: Keyword.get(opts, :model_code, "")
    }

    Client.subscribe(client, request, opts)
  end

  @doc """
  Subscribes to single-position P&L updates.

  Builds a `PnLSingleRequest` and sends it through `Client.subscribe/3`.
  The caller receives `{:ib_ex, subscription_ref, msg}` messages with PnLSingle protos.

  Returns `{:ok, subscription_ref}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:model_code` - Model code filter (default: `""`)

  ## Examples

      {:ok, ref} = Account.pnl_single(client, "DU123456", 265598)
      {:ok, ref} = Account.pnl_single(client, "DU123456", 265598, model_code: "myModel")

  """
  @spec pnl_single(pid(), String.t(), integer(), keyword()) :: {:ok, reference()} | {:error, any()}
  def pnl_single(client, account, con_id, opts \\ []) when is_integer(con_id) do
    request = %Proto.PnLSingleRequest{
      account: account,
      model_code: Keyword.get(opts, :model_code, ""),
      con_id: con_id
    }

    Client.subscribe(client, request, opts)
  end

  @doc """
  Cancels a P&L subscription.

  Delegates to `Client.unsubscribe/2` which sends a `CancelPnL` message
  and removes the subscription.

  Returns `:ok` on success, or `{:error, :not_found}` if the subscription does not exist.

  ## Examples

      :ok = Account.unsubscribe_pnl(client, subscription_ref)

  """
  @spec unsubscribe_pnl(pid(), reference()) :: :ok | {:error, :not_found}
  def unsubscribe_pnl(client, subscription_ref) do
    Client.unsubscribe(client, subscription_ref)
  end

  @doc """
  Cancels a single-position P&L subscription.

  Delegates to `Client.unsubscribe/2` which sends a `CancelPnLSingle` message
  and removes the subscription.

  Returns `:ok` on success, or `{:error, :not_found}` if the subscription does not exist.

  ## Examples

      :ok = Account.unsubscribe_pnl_single(client, subscription_ref)

  """
  @spec unsubscribe_pnl_single(pid(), reference()) :: :ok | {:error, :not_found}
  def unsubscribe_pnl_single(client, subscription_ref) do
    Client.unsubscribe(client, subscription_ref)
  end
end
