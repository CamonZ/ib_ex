# Message Protocol

## Binary Format

The IB TWS protocol uses null-byte (`\x00`) separated fields transmitted over TCP. After the initial handshake, messages use a 4-byte length prefix (packet mode).

- First field: numeric message ID (integer as string)
- Second field: version number (varies by message type)
- Remaining fields: message-specific data

`Messages.Base` provides the serialization primitives:
- `build(fields, include_length)` - Serializes field list to binary with null separators
- `get_fields(binary)` - Parses binary into field list
- `message_id_from_fields(fields)` - Extracts message ID from field list
- `make_field(value)` - Converts a value to a field string (handles nil, booleans, etc.)

## Message Structure

### Request Messages (Client → TWS)

Every request module implements:

| Interface | Purpose |
|-----------|---------|
| `new/1` | Constructor from keyword opts, returns `{:ok, struct}` |
| `String.Chars` protocol | Serializes struct to null-terminated binary |
| `Subscribable` protocol | Registers subscriber PID in ETS by request_id |
| `Traceable` protocol | Debug string with `-->` prefix |

### Response Messages (TWS → Client)

Every response module implements:

| Interface | Purpose |
|-----------|---------|
| `from_fields/1` | Parses field list into struct, returns `{:ok, struct}` |
| `Subscribable` protocol | Looks up subscriber PID from ETS by request_id |
| `Traceable` protocol | Debug string with `<--` prefix |

## Message Registry

**`Messages.Requests`** maps module names to numeric IDs (1–104). Used by `Requests.message_id_for(Module)`.

**`Messages.Responses`** maps numeric IDs back to response modules. `Responses.parse/3` dispatches based on message ID and calls `from_fields/1`.

## Message Categories

```
messages/
├── account_data/       # Account info requests/responses
├── current_time/       # Server time
├── error_info/         # Error messages from TWS
├── executions/         # Trade execution data
├── historical_ticks/   # Historical tick data
├── ids/                # Next valid order ID
├── init_connection/    # Connection initialization handshake
├── market_data/        # Real-time market data (ticks, prices)
├── market_depth/       # Order book / Level 2 data
├── matching_symbols/   # Symbol search/lookup
├── misc/               # Managed accounts, etc.
├── news/               # News bulletins, articles
├── orders/             # Order creation, cancellation, status
├── pnl/                # Profit/Loss tracking
├── start_api/          # API initialization after handshake
└── tick_by_tick_data/  # Tick-by-tick real-time updates
```

## Adding a New Message Type

1. Create the request struct in `lib/ib_ex/client/messages/{category}/`
   - Define the struct with appropriate fields
   - Implement `new/1` returning `{:ok, struct}`
   - Implement `String.Chars` for binary serialization
   - Implement `Subscribable` for ETS subscription
   - Implement `Traceable` for debug output

2. Register the message ID in `messages/requests.ex`

3. Create the response struct in the same category directory
   - Define the struct with parsed fields
   - Implement `from_fields/1` returning `{:ok, struct}`
   - Implement `Subscribable` for ETS lookup
   - Implement `Traceable` for debug output

4. Register the response parser in `messages/responses.ex`

5. Add tests mirroring the `lib/` directory structure in `test/`
