# Code Conventions

## Formatting

- **Line length**: 120 characters (configured in `.formatter.exs`)
- **Formatter**: Standard `mix format` rules
- **CI enforcement**: `mix format --check-formatted`
- **Compilation**: `mix compile --warnings-as-errors` (CI-strict)

## Naming

- **Modules**: PascalCase following Elixir convention — `IbEx.Client.Messages.MarketData.RequestData`
- **Message categories**: Match IB API domains — `market_data`, `orders`, `executions`, `news`, etc.
- **Variables/functions**: `snake_case`
- **Atoms/constants**: `lowercase_with_underscores`
- **Boolean fields**: Use `?` suffix — `can_autoexecute?`, `past_limit?`
- **Message IDs**: Numeric integers (1–104)
- **Request IDs**: Numeric strings (auto-allocated from ETS counter)

## Error Handling

- `{:ok, value}` / `{:error, reason}` tuples throughout
- Safe type conversions in `Utils` handle nil and unset sentinel values
- Unset sentinels: integer `2147483647` (2^31 - 1), float `1.7976931348623157E308`
- Rescue blocks for protocol conversion exceptions
- Fallback implementations for missing protocol methods

## Patterns

- **Protocols for polymorphism**: `Subscribable` and `Traceable` allow per-message behavior without large case statements
- **GenServer for long-lived processes**: `Client` and `Connection`
- **ETS for fast lookup**: O(1) subscription mapping
- **Struct-based messages**: Each message type is its own struct, not generic maps
- **Pipe operator**: Used for data transformations
- **Pattern matching**: Used extensively for field extraction from binary data

## Testing

- **Framework**: ExUnit
- **Async**: `use ExUnit.Case, async: true` on all test modules
- **Mocks**: Inline mock GenServers defined in test files (e.g., `MockSuccessConnection`)
- **Log capture**: `@tag capture_log: true` for tests that produce log output
- **Structure**: Test files mirror `lib/` directory structure under `test/`
- **File count**: ~91 test files covering ~125 source files

## CI Pipeline (`.github/workflows/elixir.yml`)

Runs on push/PR to `master`:
1. Setup Elixir 1.18 / OTP 27.0 on Ubuntu
2. Cache dependencies
3. `mix deps.get`
4. `mix compile --warnings-as-errors`
5. `mix format --check-formatted`
6. `mix test`

Dialyzer is **not** run in CI (dev-only dependency).
