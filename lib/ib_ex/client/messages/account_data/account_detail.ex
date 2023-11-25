defmodule IbEx.Client.Messages.AccountData.AccountDetail do
  @moduledoc """
  Incoming message for the different fields detailing the details & value of an account.

  Once subscribed through the request message,
  changes to these fields are streamed and received through this message.

  The fields received through this message include:

  * AccountCode
  * AccountOrGroup
  * AccountReady
  * AccountType
  * AccruedCash
  * AccruedDividend
  * AvailableFunds
  * Billable
  * Buying Power
  * CashBalance
  * ColumnPrio-S
  * CorporateBondValue
  * Currency
  * Cushion
  * EquityWithLoanValue
  * ExcessLiquidity
  * ExchangeRate
  * FullAvailableFunds
  * FullExcessLiquidity
  * FullInitialMarginReq
  * FullMaintMarginReq
  * FundValue
  * FutureOptionValue
  * FuturesPNL
  * FxCashBalance
  * GrossPositionValue
  * Guarantee
  * IndianStockHaircut
  * InitMarginreq
  * IssuerOptionValue
  * Leverage-S
  * LookAheadAvailableFunds
  * LookAheadExcessLiquidity
  * LookAheadInitMarginReq
  * LookAheadMaintMarginReq
  * LookAheadNextChange
  * MaintMarginReq
  * MoneyMarketFundValue
  * MutualFundValue
  * NLVAndMarginInReview
  * NetDividend
  * NetLiquidation
  * NetLiquidationByCurrency
  * NetLiquidationUncertainty
  * OptionMarketValue
  * PASharesValue
  * PhysicalCertificateValue
  * PostExpirationExcess
  * PostExpirationMargin
  * RealCurrency
  * RealizedPnL
  * SegmentTitle-S
  * StockMarketValue
  * TBillValue
  * TotalCashBalance
  * TotalCashValue
  * TotalDebitCardPendingCharges
  * TradingType-S
  * UnrealizedPnL
  * WarrantValue
  """

  defstruct version: nil, field: nil, value: nil, currency: nil, account: nil
  
  def from_fields([version_str, field, value, currency, account]) do
    case Integer.parse(version_str) do
      {version, _} ->
        {
          :ok,
          %__MODULE__{
            version: version,
            field: field,
            value: value,
            currency: currency,
            account: account
          }
        }

      _ ->
        {:error, :invalid_args}
    end
  end

  def from_fields(_fields) do
    {:error, :invalid_args}
  end
  
  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "<-- AccountDetail{field: #{msg.field}, value: #{msg.value}, currency: #{msg.currency}, account: #{msg.account}}"
    end
  end
end
