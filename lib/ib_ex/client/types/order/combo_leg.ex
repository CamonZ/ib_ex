defmodule IbEx.Client.Types.Order.ComboLeg do
  defstruct conid: nil,
            ratio: nil,
            action: nil,
            exchange: nil,
            open_close: nil,
            short_sale_slot: nil,
            designated_location: nil,
            exempt_code: nil
end
