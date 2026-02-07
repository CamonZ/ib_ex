defmodule IbEx.Client.Types.OrderState.MarginInfo do
  @moduledoc """
  Margin information associated with an OrderState.

  Contains before/change/after values for initial margin, maintenance margin,
  and equity with loan. Each metric has both a regular (RTH) variant and an
  outside regular trading hours variant.
  """

  defstruct init_margin_before: nil,
            init_margin_change: nil,
            init_margin_after: nil,
            maint_margin_before: nil,
            maint_margin_change: nil,
            maint_margin_after: nil,
            equity_with_loan_before: nil,
            equity_with_loan_change: nil,
            equity_with_loan_after: nil,
            init_margin_before_outside_rth: nil,
            init_margin_change_outside_rth: nil,
            init_margin_after_outside_rth: nil,
            maint_margin_before_outside_rth: nil,
            maint_margin_change_outside_rth: nil,
            maint_margin_after_outside_rth: nil,
            equity_with_loan_before_outside_rth: nil,
            equity_with_loan_change_outside_rth: nil,
            equity_with_loan_after_outside_rth: nil

  @type t :: %__MODULE__{
          init_margin_before: binary() | nil,
          init_margin_change: binary() | nil,
          init_margin_after: binary() | nil,
          maint_margin_before: binary() | nil,
          maint_margin_change: binary() | nil,
          maint_margin_after: binary() | nil,
          equity_with_loan_before: binary() | nil,
          equity_with_loan_change: binary() | nil,
          equity_with_loan_after: binary() | nil,
          init_margin_before_outside_rth: binary() | nil,
          init_margin_change_outside_rth: binary() | nil,
          init_margin_after_outside_rth: binary() | nil,
          maint_margin_before_outside_rth: binary() | nil,
          maint_margin_change_outside_rth: binary() | nil,
          maint_margin_after_outside_rth: binary() | nil,
          equity_with_loan_before_outside_rth: binary() | nil,
          equity_with_loan_change_outside_rth: binary() | nil,
          equity_with_loan_after_outside_rth: binary() | nil
        }

  def new(args) when is_list(args) do
    args
    |> Enum.into(%{})
    |> new()
  end

  def new(args) when is_map(args) do
    struct(__MODULE__, args)
  end

  def new(), do: new(%{})
end
