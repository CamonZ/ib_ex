defmodule IbEx.Client.Messages.AccountData.Request do
  @moduledoc """
  Request to receive updates related to the account data

  For the account used in tests the following data fields are received through the AccountDetail message:

  * AccountCode
  * AccountOrGroup with variations for each currency held in the account
  * AccountReady
  * AccountType
  * AccruedCash (currency variants)
  * AvailableFunds
  * Billable
  * BuyingPower
  * CashBalance (currency variants)
  * ColumnPrio-S ???
  * CorporateBondValue (currency variants)
  * Currency (currencies in the account)
  * Cushion ???
  * EquityWithLoanValue
  * ExcessLiquidity
  * ExchangeRate between currencies held in account
  * FullAvailableFunds
  * FullExcessLiquidity
  * FullInitMarginReq
  * FullMaintMarginReq
  * FundValue (currency variations)
  * FutureOptionValue (currency variations)
  * FuturesPNL (currency variations)
  * FxCashBalance (currency varaitions)
  * GrossPositionValue
  * Guarantee
  * IndianSockHaircut ???
  * InitMarginReq
  * IssuerOptionValue (currency variants)
  * Leverage-S ???
  * LookAheadAvailableFunds
  * LookAheadExcessLiquidity
  * LookAheadInitMarginReq
  * LookAheadMaintMarginReq
  * LookAheadNextChange
  * MaintMarginReq
  * MoneyMarketFundValue (currency variants)
  * MutualFundValue (currency variants)
  * NLVAndMarginInReview
  * NetDividend (currency variants)
  * NetLIquidation
  * NetLiquidationByCurrency (currency variants)
  * NetLiquidationUncertainty
  * OptionMarketValue (currency variants)
  * PASharesValue
  * PhysicalCertificatesValue
  * PostExpirationExcess
  * PostExpirationMargin
  * RealCurrency (currency variants)
  * RealizedPnL (currency variants)
  * SegmentTitle-S
  * StockMarketValue (currency variants)
  * TBillValue (currency variants)
  * TBondValue (currency variants)
  * TotalCashBalance (currency variants)
  * TotalCashValue
  * TotalDebitCardPendingCharges
  * TradingType-S
  * UnrealizedPnL (currency variants)
  * WarrantValue (currency variants)

  As secondary messages we receive the AccountUpdateTime and AccountDownloadEnd

  The subscribe param allows for continuous updates to be received, though even with subscribed
  set to true, the AccountDownloadEnd message is received at least once and the AccountUpdateTime
  is received twice per update

  In order to unsubscribe from the account updates feed we need to send this message with the subscribe param set to false,
  to confirm this we receive an Info message saying the API client is unsubscribed from account data
  """
  @message_version 1

  alias IbEx.Client.Messages.Base
  alias IbEx.Client.Messages.Requests

  defstruct message_id: nil, version: @message_version, subscribe: nil, account_code: nil

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          version: non_neg_integer(),
          subscribe: boolean(),
          account_code: binary() | nil
        }

  @spec new(boolean(), binary() | nil) :: {:ok, t()} | {:error, :not_implemented}
  def new(subscribe, account_code \\ nil) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {
          :ok,
          %__MODULE__{
            message_id: id,
            subscribe: subscribe,
            account_code: account_code
          }
        }

      :error ->
        {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build([msg.message_id, msg.version, msg.subscribe, msg.account_code])
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "--> AccountUpdates{message_id: #{msg.message_id}, subscribe: #{msg.subscribe}, account_code: #{inspect(msg.account_code)}}"
    end
  end
end
