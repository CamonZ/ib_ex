defmodule IbEx.Client.Types.Contract do
  alias IbEx.Client.Types.Contract.{DeltaNeutral, ComboLeg}
  import IbEx.Client.Utils, only: [list_to_union_type: 1]

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
            security_id_type: "",
            security_id: "",
            combo_legs_description: nil,
            combo_legs: [],
            delta_neutral_contract: nil,
            description: "",
            issuer_id: ""

  @rights ~w(C CALL P PUT ?)

  @security_types ~w(STK OPT FUT IND FOP CASH BAG WAR BOND CMDTY NEWS FUND)a
  @type security_type :: unquote(list_to_union_type(@security_types))

  @security_id_types ~w(CUSIP SEDOL ISIN RIC)a
  @type security_id_type :: unquote(list_to_union_type(@security_id_types))

  @type t :: %__MODULE__{
          conid: binary(),
          symbol: binary(),
          security_type: security_type(),
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
          security_id_type: security_id_type(),
          security_id: binary(),
          combo_legs_description: binary(),
          combo_legs: list(ComboLeg.t()),
          delta_neutral_contract: DeltaNeutral.t(),
          description: binary(),
          issuer_id: binary()
        }

  @deserialize_fields_order [
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
  def security_types, do: Enum.map(@security_types, &to_string/1)
  def security_id_types, do: @security_id_types

  @spec from_serialized_fields(list(binary())) :: {:ok, t()} | {:error, :invalid_args}
  @doc """
  Used to create a contract from the ExecutionData or OpenOrder messages which carries 11
  fields for the contract
  """

  def from_serialized_fields(fields) when is_list(fields) and length(fields) == 11 do
    contract =
      @deserialize_fields_order
      |> Enum.zip(fields)
      |> Enum.into(%{})
      |> new()

    {:ok, contract}
  end

  def from_serialized_fields(_) do
    {:error, :invalid_args}
  end

  def assign_params(attrs, key, module) do
    Map.put(attrs, key, module.new(Map.get(attrs, key, %{})))
  end

  @spec new(map()) :: t()
  def new(attrs) when is_map(attrs) do
    attrs =
      case attrs.security_type == "BAG" do
        true ->
          assign_params(attrs, :delta_neutral_contract, DeltaNeutral)

        false ->
          attrs
      end

    struct(__MODULE__, attrs)
  end

  @spec serialize(__MODULE__.t(), boolean()) :: list()
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

  @spec maybe_serialize_combo_legs(__MODULE__.t()) :: list()
  def maybe_serialize_combo_legs(%__MODULE__{} = contract) do
    if contract.security_type == "BAG" do
      serialize_combo_legs(contract)
    else
      []
    end
  end

  @spec serialize_combo_legs(__MODULE__.t()) :: list()
  def serialize_combo_legs(%__MODULE__{} = contract) do
    [
      length(contract.combo_legs)
    ] ++
      (Enum.reduce(contract.combo_legs, [], fn %ComboLeg{} = leg, acc ->
         [
           [
             leg.conid,
             leg.ratio,
             leg.action,
             leg.exchange,
             leg.open_close,
             leg.short_sale_slot,
             leg.designated_location,
             leg.exempt_code
           ]
           | acc
         ]
       end)
       |> Enum.reverse()
       |> List.flatten())
  end

  @spec serialize_delta_neutral_contract(__MODULE__.t()) :: list()
  def serialize_delta_neutral_contract(%__MODULE__{delta_neutral_contract: %DeltaNeutral{} = contract}) do
    DeltaNeutral.serialize(contract)
  end

  def serialize_delta_neutral_contract(%__MODULE__{}), do: [false]
end
