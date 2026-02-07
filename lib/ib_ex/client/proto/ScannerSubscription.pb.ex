defmodule IbEx.Client.Proto.Protobuf.ScannerSubscription.ScannerSubscriptionFilterOptionsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ScannerSubscription.ScannerSubscriptionFilterOptionsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.ScannerSubscription.ScannerSubscriptionOptionsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ScannerSubscription.ScannerSubscriptionOptionsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.ScannerSubscription do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ScannerSubscription",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:number_of_rows, 1, json_name: "numberOfRows", proto3_optional: true, type: :int32)
  field(:instrument, 2, proto3_optional: true, type: :string)
  field(:location_code, 3, json_name: "locationCode", proto3_optional: true, type: :string)
  field(:scan_code, 4, json_name: "scanCode", proto3_optional: true, type: :string)
  field(:above_price, 5, json_name: "abovePrice", proto3_optional: true, type: :double)
  field(:below_price, 6, json_name: "belowPrice", proto3_optional: true, type: :double)
  field(:above_volume, 7, json_name: "aboveVolume", proto3_optional: true, type: :int64)
  field(:market_cap_above, 8, json_name: "marketCapAbove", proto3_optional: true, type: :double)
  field(:market_cap_below, 9, json_name: "marketCapBelow", proto3_optional: true, type: :double)
  field(:moody_rating_above, 10, json_name: "moodyRatingAbove", proto3_optional: true, type: :string)
  field(:moody_rating_below, 11, json_name: "moodyRatingBelow", proto3_optional: true, type: :string)
  field(:sp_rating_above, 12, json_name: "spRatingAbove", proto3_optional: true, type: :string)
  field(:sp_rating_below, 13, json_name: "spRatingBelow", proto3_optional: true, type: :string)
  field(:maturity_date_above, 14, json_name: "maturityDateAbove", proto3_optional: true, type: :string)
  field(:maturity_date_below, 15, json_name: "maturityDateBelow", proto3_optional: true, type: :string)
  field(:coupon_rate_above, 16, json_name: "couponRateAbove", proto3_optional: true, type: :double)
  field(:coupon_rate_below, 17, json_name: "couponRateBelow", proto3_optional: true, type: :double)
  field(:exclude_convertible, 18, json_name: "excludeConvertible", proto3_optional: true, type: :bool)
  field(:average_option_volume_above, 19, json_name: "averageOptionVolumeAbove", proto3_optional: true, type: :int64)
  field(:scanner_setting_pairs, 20, json_name: "scannerSettingPairs", proto3_optional: true, type: :string)
  field(:stock_type_filter, 21, json_name: "stockTypeFilter", proto3_optional: true, type: :string)

  field(:scanner_subscription_filter_options, 22,
    json_name: "scannerSubscriptionFilterOptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.ScannerSubscription.ScannerSubscriptionFilterOptionsEntry,
    map: true
  )

  field(:scanner_subscription_options, 23,
    json_name: "scannerSubscriptionOptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.ScannerSubscription.ScannerSubscriptionOptionsEntry,
    map: true
  )
end
