# Domain Concepts

## Interactive Brokers

IbEx implements the [IB TWS API](https://interactivebrokers.github.io/tws-api/) protocol — a proprietary TCP-based protocol for communicating with Interactive Brokers' Trader Workstation (TWS) or IB Gateway.

## Key Types

### Contract (`IbEx.Client.Types.Contract`)

Financial instrument specification. Represents any tradeable security.

- **Key fields**: `conid`, `symbol`, `security_type`, `exchange`, `currency`, `strike`, `right`
- **Security types**: STK (stock), OPT (option), FUT (future), and more
- **Default exchange**: `SMART` (IB smart routing)
- **Sub-types**: `ComboLeg`, `DeltaNeutral` in `types/contract/`

### Order (`IbEx.Client.Types.Order`)

Trade order with extensive parameters. One of the largest structs in the codebase.

- **Actions**: BUY, SELL, SSHORT
- **Order types**: LMT, MKT, STP, and many more
- **Time in force**: DAY, GTC, IOC, GTD, OPG, FOK, DTC
- **Sub-types**: Numerous parameter structs in `types/order/` (algo params, scale params, hedge params, etc.)

### Tick Types (`IbEx.Client.Constants.TickTypes`)

100+ real-time data point types: `:bid`, `:ask`, `:last`, `:volume`, `:high`, `:low`, `:close`, etc.

- `to_atom(str)` converts numeric string to atom
- `size_related_type?(atom)` determines if a tick triggers a size update

### Server Versions (`IbEx.Client.Constants.ServerVersions`)

TWS capabilities gated by version numbers. The client validates the server supports required features.

- **Minimum**: `pending_price_revision` (version 178)
- **Latest supported**: `rfq_fields` (version 187)
- `version_for(key)` → `{:ok, version}` or `:error`

### Other Types

| Type | Purpose |
|------|---------|
| `BidAsk` | Bid/ask price pair |
| `Trade` | Trade information |
| `Execution` | Trade execution details |
| `ExecutionsFilter` | Filter for execution queries |
| `MidPoint` | Midpoint price |
| `NewsArticle` / `NewsHeadline` | News data |
| `OrderCancel` | Order cancellation data |
| `TagValue` | Generic key-value pair |
| `MarketDepthDescription` | Order book parameters |
| `ContractDescription` | Contract with descriptions |

## Utility Functions (`IbEx.Client.Utils`)

Safe type conversions for the binary protocol:

| Function | Purpose |
|----------|---------|
| `to_decimal(str)` | String → Decimal (handles unset) |
| `to_float(str)` | String → Float |
| `to_integer(str)` | String → Integer |
| `to_bool(str)` | "0"/"1" → Boolean |
| `boolify_mask(mask, bit)` | Bitwise flag extraction |
| `parse_init_connection_timestamp(str)` | Parse TWS timestamp |
