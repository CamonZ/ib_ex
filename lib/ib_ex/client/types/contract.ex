defmodule IbEx.Client.Types.Contract do
  defstruct conid: "0",
            symbol: "",
            security_type: "",
            last_trade_date_or_contract_month: "",
            strike: "0.0",
            right: "",
            multiplier: "",
            # setting this as default same as defined in the IBKR clients
            exchange: "SMART",
            currency: "",
            local_symbol: "",
            primary_exchange: "",
            trading_class: "",
            include_expired: false,
            # CUSIP;SEDOL;ISIN;RIC
            security_id_type: "",
            security_id: "",
            combo_legs_description: nil,
            combo_legs: [],
            delta_neutral_contract: nil,
            description: "",
            issuer_id: ""

  @type t :: %__MODULE__{
          conid: binary(),
          symbol: binary(),
          security_type: binary(),
          last_trade_date_or_contract_month: binary(),
          strike: binary(),
          right: binary(),
          multiplier: binary(),
          exchange: binary(),
          currency: binary(),
          local_symbol: binary(),
          primary_exchange: binary(),
          trading_class: binary(),
          include_expired: boolean(),
          security_id_type: binary(),
          security_id: binary(),
          combo_legs_description: binary(),
          combo_legs: list(),
          delta_neutral_contract: binary(),
          description: binary(),
          issuer_id: binary()
        }

  @rights ~w(C CALL P PUT ?)
  @security_types ~w(STK OPT FUT IND FOP CASH BAG WAR BOND CMDTY NEWS FUND)

  @serialized_fields_order [
    :conid,
    :symbol,
    :security_type,
    :last_trade_date_or_contract_month,
    :strike,
    :right,
    :multiplier,
    :exchange,
    :currency,
    :local_symbol,
    :trading_class
  ]

  def rights, do: @rights
  def security_types, do: @security_types

  @spec from_serialized_fields(list(binary())) :: {:ok, t()} | {:error, :invalid_args}
  @doc """
  Used to create a contract from the ExecutionData or OpenOrder messages which carries 11
  fields for the contract
  """

  def from_serialized_fields(fields) when is_list(fields) and length(fields) == 11 do
    contract =
      @serialized_fields_order
      |> Enum.zip(fields)
      |> Enum.into(%{})
      |> new()

    {:ok, contract}
  end

  def from_serialized_fields(_) do
    {:error, :invalid_args}
  end

  @spec new(map()) :: t()
  def new(attrs) when is_map(attrs) do
    struct(__MODULE__, attrs)
  end

  def serialize(%__MODULE__{} = contract, include_expired \\ true) do
    fields = [
      contract.conid,
      contract.symbol,
      contract.security_type,
      contract.last_trade_date_or_contract_month,
      contract.strike,
      contract.right,
      contract.multiplier,
      contract.exchange,
      contract.primary_exchange,
      contract.currency,
      contract.local_symbol,
      contract.trading_class
    ]

    if include_expired do
      fields ++ [contract.include_expired]
    else
      fields
    end
  end
end
