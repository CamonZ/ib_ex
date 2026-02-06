# Architecture

## Directory Structure

```
lib/ib_ex/
├── application.ex                # OTP Application (minimal, no children)
├── client.ex                     # GenServer - central coordinator
├── client/
│   ├── connection.ex             # GenServer - TCP socket to TWS
│   ├── connection/
│   │   ├── socket.ex             # :gen_tcp wrapper
│   │   └── frame.ex              # Binary frame packing
│   ├── subscriptions.ex          # ETS-based request→subscriber mapping
│   ├── protocols/
│   │   ├── subscribable.ex       # Maps requests to response subscribers
│   │   └── traceable.ex          # Human-readable message tracing
│   ├── constants/                # Server versions, tick types, bar sizes
│   ├── types/                    # Domain structs (Contract, Order, Trade, etc.)
│   ├── utils/                    # Type conversion helpers
│   └── messages/                 # Request/response message implementations
│       ├── base.ex               # Binary serialization primitives
│       ├── requests.ex           # Message ID registry (module → numeric ID)
│       ├── responses.ex          # Response dispatcher (numeric ID → module)
│       └── [category]/           # Messages grouped by domain
```

## Core Components

### Client (`IbEx.Client`)

GenServer that coordinates all communication with TWS. Manages connection lifecycle, message dispatching, and the subscription table.

**Key struct fields:**
- `connection` - Connection process PID
- `status` - `:disconnected` → `:connecting` → `:connected`
- `server_version` - TWS server version (gates feature availability)
- `subscriptions_table_ref` - ETS table for request→subscriber mapping
- `next_valid_id` - Order ID counter from TWS
- `trace_messages` - Debug flag for logging message flow

### Connection (`IbEx.Client.Connection`)

GenServer managing the raw TCP socket to TWS/Gateway. Default host `{127, 0, 0, 1}`, default port `7496`.

**Sub-modules:**
- `Connection.Socket` - Thin `:gen_tcp` wrapper (connect, disconnect, send, packet mode)
- `Connection.Frame` - Binary frame packing with `pack/2`

### Subscriptions (`IbEx.Client.Subscriptions`)

ETS table (`set`, `public`) mapping request IDs to subscriber PIDs. Three subscription modes:

1. **By request_id** (most common) - auto-allocated integer, used by most market data/order messages
2. **By module atom** - for singleton responses (e.g., `InitConnection`)
3. **By custom ID** - for special cases

### Protocols

**Subscribable** - Maps requests to response subscribers via ETS.
- `subscribe(msg, pid, table)` → `{:ok, msg_with_id}` - registers subscriber
- `lookup(msg, table)` → `{:ok, pid}` - finds subscriber for a response

**Traceable** - Human-readable message representation for debugging.
- `to_s(msg)` → String
- Requests use `-->` prefix, responses use `<--` prefix
- Enabled when `trace_messages: true` in Client options

## Data Flow

### Connection Handshake

1. `Client` spawns `Connection` on init
2. `Connection` establishes TCP socket to TWS/Gateway
3. `Connection` calls `Client.connection_opened/1`
4. Client sends `InitConnection.Request`
5. Receives `InitConnection.Response` with server version
6. Validates server version against minimum (`pending_price_revision` = 178)
7. Sends `StartApi.Request`
8. Receives `ManagedAccounts` and `NextValidId`
9. Client status becomes `:connected`

### Request/Response Cycle

1. Caller invokes `Client.send_request/2`
2. `Subscribable.subscribe` stores `{request_id, caller_pid}` in ETS
3. `Connection.send_message` sends binary to TWS
4. TWS response arrives via TCP → `Connection` → `Client.process_message/2`
5. `Responses.parse` dispatches to the correct module's `from_fields/1`
6. `Subscribable.lookup` retrieves subscriber PID from ETS
7. Response is relayed to subscriber process
