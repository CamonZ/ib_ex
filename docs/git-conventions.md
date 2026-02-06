# Git & PR Conventions

## Commit Messages

| Prefix | When | Example |
|--------|------|---------|
| `[FEAT-###]` | Feature with ticket number | `[FEAT-155] Swap Inspect implementation for a custom protocol` |
| `[NO-REF]` | Without ticket reference | `[NO-REF] Add Traceable implementation for SymbolSamples` |

Descriptions are verb-first: **Add**, **Remove**, **Update**, **Swap**, **Fix**, **Implement**, **Create**.

## Branch Naming

| Pattern | When | Example |
|---------|------|---------|
| `{ticket_number}-description-in-kebab-case` | Feature with ticket | `155-create-a-new-protocol-for-inspecting-tracing-messages-flow` |
| `no-ref-description-in-kebab-case` | Without ticket | `no-ref-add-implementation-tick-by-tick-response` |

## PR Workflow

- PRs target the `master` branch
- CI must pass: compile (warnings-as-errors), format check, tests
- Merge commits from GitHub PRs
- Remote: `origin` pointing to `CamonZ/ib_ex` on GitHub
