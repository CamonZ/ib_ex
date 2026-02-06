# IbEx - Interactive Brokers TWS Client for Elixir

Elixir library implementing the Interactive Brokers TWS/Gateway TCP protocol for trading and market data.

## Quick Reference

- **Language**: Elixir ~> 1.16 (CI uses 1.18 / OTP 27.0)
- **Build**: `mix compile --warnings-as-errors`
- **Test**: `mix test`
- **Format**: `mix format` (line length: 120)
- **Deps**: `mix deps.get`

## Documentation Index

| Document | Description |
|----------|-------------|
| [Quick Reference](docs/quick-reference.md) | Commands, dependencies, environment |
| [Architecture](docs/architecture.md) | Core components, data flow, subscription system |
| [Message Protocol](docs/message-protocol.md) | Binary format, message structure, adding new messages |
| [Code Conventions](docs/code-conventions.md) | Formatting, naming, error handling, testing, CI |
| [Git Conventions](docs/git-conventions.md) | Commit messages, branch naming, PR workflow |
| [Domain Concepts](docs/domain-concepts.md) | IB types: Contract, Order, Tick Types, Server Versions |
| [Vertebrae Guide](docs/vertebrae-guide.md) | Task management: creating tickets, sections, workflows, triage |
