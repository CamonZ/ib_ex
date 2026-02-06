# Quick Reference

## Commands

| Command | Description |
|---------|-------------|
| `mix compile --warnings-as-errors` | Compile (CI-strict mode) |
| `mix test` | Run test suite |
| `mix format` | Format code |
| `mix format --check-formatted` | Check formatting (CI) |
| `mix dialyzer` | Run typecheck (dev only, not in CI) |
| `mix deps.get` | Install dependencies |

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `timex` | ~> 3.7 | Date/time parsing and formatting |
| `decimal` | ~> 2.1 | Precise decimal arithmetic |
| `dialyxir` | ~> 1.4 | Static type analysis (dev only) |
| `ex_doc` | ~> 0.34.0 | Documentation generation (dev only) |

## Environment

- **Elixir**: ~> 1.16 (CI uses 1.18)
- **OTP**: 27.0
- **Formatter line length**: 120 characters
