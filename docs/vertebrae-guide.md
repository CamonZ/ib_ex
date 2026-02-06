# Vertebrae (vtb) — Task Management Guide

Vertebrae is a task management system integrated with Claude Code via skills (slash commands). It provides structured workflows for planning, triaging, implementing, and reviewing work.

## Setup

```bash
vtb init
```

Creates `.claude/skills/` (skill files).

## Core Concepts

### Task Hierarchy

```
epic       → Large initiative spanning multiple features
  ticket   → Single deliverable feature
    task   → Unit of work (default level)
```

### Task Position: Workflow + Step

Tasks don't have a standalone status. Instead, a task's position is defined by its **workflow** and **step** within that workflow. For example, a task might be in the `implementation` workflow at the `coding` step.

Use `vtb transition-to` to move tasks between workflows and steps:
```bash
vtb transition-to <id> implementation           # Assign to workflow (first step)
vtb transition-to <id> implementation:coding    # Specific workflow:step
```

Workflows and steps are project-specific — use `vtb workflow list` to see what's configured.

### Priorities

`low`, `medium`, `high`, `critical`

---

## Creating Tickets

### Basic Creation

```bash
# Simple task
vtb add "Task title"

# Ticket with level and description
vtb add "Feature title" -l ticket -d "Detailed description"

# Epic for a large initiative
vtb add "Refactor auth system" -l epic -d "Overhaul the authentication layer"

# Subtask under a parent
vtb add "Create sign() function" --parent <ticket-id>

# With priority and tags
vtb add "Fix login bug" -p critical -t bug -t backend

# Mark as needing human review
vtb add "Sensitive security change" --needs-review

# With a dependency (this task is blocked by another)
vtb add "Write integration tests" --depends-on <blocker-id>
```

### Planning a Feature (Epic → Tickets → Tasks)

```bash
# 1. Create the epic
vtb add "Implement market data streaming" -l epic -d "Real-time market data support"

# 2. Break into tickets
vtb add "Add MarketData request messages" -l ticket --parent <epic-id>
vtb add "Add MarketData response parsing" -l ticket --parent <epic-id>

# 3. Break tickets into tasks
vtb add "Create RequestData struct" --parent <ticket-id>
vtb add "Implement String.Chars for RequestData" --parent <ticket-id>

# 4. Set dependencies
vtb depend <string-chars-task> --on <struct-task>

# 5. View the plan
vtb show <epic-id>
vtb blockers <final-task-id>
```

---

## Documenting Tickets with Sections

Sections add structured content to tickets. They are critical for triage.

### Section Types

| Type | Purpose | Cardinality |
|------|---------|-------------|
| `goal` | What this task achieves | Single |
| `context` | Background information | Single |
| `current_behavior` | How it works now (for bugs) | Single |
| `desired_behavior` | How it should work | Single |
| `step` | Ordered implementation steps | Multiple |
| `constraint` | Requirements/limitations | Multiple |
| `testing_criterion` | How to verify success | Multiple |
| `anti_pattern` | What to avoid | Multiple |
| `failure_test` | Expected failure/edge cases | Multiple |

### Adding Sections

```bash
# Define the objective
vtb section <id> goal "Allow users to subscribe to real-time market data"

# Background context
vtb section <id> context "TWS provides tick-by-tick data via request ID subscriptions"

# Implementation steps (ordered)
vtb section <id> step "Create RequestData struct with contract and tick_list fields"
vtb section <id> step "Implement String.Chars protocol for binary serialization"
vtb section <id> step "Implement Subscribable protocol for ETS registration"
vtb section <id> step "Add response parsing in from_fields/1"

# Constraints
vtb section <id> constraint "Must validate server version supports market data"
vtb section <id> constraint "All tests must use async: true"

# Testing criteria (at least 1 unit + 1 integration)
vtb section <id> testing_criterion "UNIT: RequestData.new/1 returns valid struct"
vtb section <id> testing_criterion "INTEGRATION: Full request/response cycle with mock connection"

# Anti-patterns
vtb section <id> anti_pattern "Don't bypass Subscribable protocol with direct ETS writes"

# Failure tests
vtb section <id> failure_test "Invalid contract returns {:error, reason}"
```

### Viewing Sections

```bash
vtb sections <id>                     # List all sections
vtb sections <id> --type step         # Filter by type
```

### Removing Sections

```bash
# Single-instance types (no index needed)
vtb unsection <id> goal
vtb unsection <id> context

# Multi-instance types (index required)
vtb unsection <id> step --index 2
vtb unsection <id> testing_criterion --index 1
```

### Editing Sections

```bash
vtb update <id> --edit-section step 0 "Updated step content"
vtb update <id> --remove-section step 0
```

---

## Triage: Making Tickets Ready for Work

Triage validates that a ticket is properly documented before it can be transitioned into an actionable workflow.

### Required Sections (blocks triage without them)

| Section | Minimum | Details |
|---------|---------|---------|
| `testing_criterion` | **2** | At least 1 unit + 1 integration criterion |
| `step` | **1** | Implementation steps |
| `constraint` | **2** | Architectural/quality guidelines |
| `goal` or `desired_behavior` | **1** | Clear objective |

### Strongly Encouraged (warns but allows with `--force`)

| Section | Minimum | Purpose |
|---------|---------|---------|
| `anti_pattern` | **1** | Pitfalls to avoid |
| `failure_test` | **1** | Error scenarios/edge cases |

### Recommended (informational only)

| Section | Purpose |
|---------|---------|
| `context` | Background information |
| `current_behavior` | Current state (for bugs/changes) |

### Triage Command

```bash
# Check what's missing
vtb show <id>

# Triage the ticket (validates sections)
vtb transition-to <id> todo

# Force past warnings (not recommended)
vtb transition-to <id> todo --force
```

### Complete Triage Workflow

```bash
# 1. Create ticket
vtb add "Fix search bug" -l ticket -d "Search returns no results"

# 2. Add required sections
vtb section <id> goal "Enable searching tasks by ID and content"
vtb section <id> testing_criterion "UNIT: Search matches task IDs correctly"
vtb section <id> testing_criterion "INTEGRATION: Search filters display in real-time"
vtb section <id> step "Debug search query in backend"
vtb section <id> step "Fix event handler"
vtb section <id> constraint "Must validate search input"
vtb section <id> constraint "All tests must pass"

# 3. Add encouraged sections
vtb section <id> anti_pattern "Don't use raw search strings in queries"
vtb section <id> failure_test "Empty search returns all tasks"

# 4. Add optional context
vtb section <id> current_behavior "Search returns no results for task IDs"
vtb section <id> context "Users cannot navigate by task ID"

# 5. Verify and triage
vtb show <id>
vtb transition-to <id> todo
```

---

## Workflows and Steps

Workflows define the stages a task progresses through.

### Creating Workflows

```bash
# Basic workflow with steps (format: name:model)
vtb workflow add "Implementation" --step coding:sonnet --step testing:haiku --step docs:haiku

# With description and auto-advance
vtb workflow add "Code Review" \
  -d "Review and approval process" \
  --step review:sonnet \
  --step approved:haiku \
  --auto-advance
```

### Managing Workflows

```bash
vtb workflow list                       # List all workflows
vtb workflow show <workflow-id>         # See steps and details
vtb workflow update <id> --name "Dev"   # Rename
vtb workflow update <id> --auto-advance # Enable auto-advance
vtb workflow delete <workflow-id>       # Delete (no assigned tasks allowed)
```

### Assigning Workflows to Tasks

```bash
vtb workflow assign <task-id> <workflow-id>    # Assign (starts at first step)
vtb workflow unassign <task-id>                # Remove workflow
```

### Managing Steps

```bash
# Add a step to an existing workflow
vtb step add "Testing" -w implementation \
  --goal "Verify implementation" \
  --model sonnet \
  --order 1

# Add a final step (marks workflow complete)
vtb step add "Approved" -w review --final

# Add step with transition restrictions
vtb step add "Needs Work" -w review --transition-to coding

# List, show, update, delete steps
vtb step list -w implementation
vtb step show coding
vtb step update coding --goal "New goal" --model opus
vtb step delete old-step
```

### Step Properties

| Property | Description |
|----------|-------------|
| `order` | Execution order (lower = first) |
| `final` | Marks workflow as complete when reached |
| `goal` | What this step accomplishes |
| `model` | AI model to use (sonnet, haiku, opus) |
| `agents` | Agent file paths for AI-assisted execution |
| `skills` | Slash commands available during this step |
| `transition-to` | Restrict which steps can follow this one |

---

## Moving Tickets Between Workflows and Steps

### Cross-Workflow Transitions (`transition-to`)

Use `transition-to` to move tasks **across** workflows or to specific steps:

```bash
# Move to a workflow (starts at first step)
vtb transition-to <id> implementation

# Move to a specific step within a workflow
vtb transition-to <id> implementation:coding

# Common lifecycle transitions
vtb transition-to <id> todo                    # Triage ticket for work
vtb transition-to <id> implementation          # Start implementation
vtb transition-to <id> implementation:testing  # Move to testing step
vtb transition-to <id> review                  # Submit for review
vtb transition-to <id> done                    # Mark complete
```

### Within-Workflow Movement

```bash
vtb workflow advance <id>     # Next step in current workflow
vtb workflow retreat <id>     # Previous step in current workflow
```

### Workflow Transitions (between workflows)

Define allowed transitions between workflows:

```bash
# Create transition rule
vtb workflow transition add <from-workflow> <to-workflow> --label "approve"

# With target step in destination
vtb workflow transition add <from-workflow> <to-workflow> \
  --label "escalate" --target-step <step-id>

# List and delete transitions
vtb workflow transition list
vtb workflow transition list --workflow-id <id>
vtb workflow transition delete <from-workflow> <to-workflow>
```

### Key Rules

- **`transition-to`** is for cross-workflow moves
- **`workflow advance/retreat`** is for within-workflow moves
- **Never use `vtb update`** for workflow/step changes — always use `transition-to`
- Transitions are validated against workflow rules
- Use `--skip-validation` only as an escape hatch

---

## Marking Implementation Steps Done

Track progress on a task's implementation steps:

```bash
# Mark step 1 as done (1-based index)
vtb step-done <task-id> 1

# View step completion status
vtb show <task-id>
```

Steps display with checkboxes:
```
Steps:
  1. [x] Create database schema
  2. [ ] Implement API endpoint
  3. [ ] Write tests
```

---

## Dependencies

### Creating Dependencies

```bash
# Task A depends on task B (B must finish before A can start)
vtb depend <task-a> --on <task-b>
```

### Removing Dependencies

```bash
vtb undepend <task-a> --on <task-b>
```

### Viewing Dependencies

```bash
# Full blocker tree for a task
vtb blockers <task-id>
vtb blockers <task-id> --depth 2        # Limit depth
vtb blockers <task-id> --all            # Include completed blockers

# Shortest path between two tasks
vtb path <from-task> <to-task>
```

---

## Code References

Link tasks to specific code locations:

```bash
# File reference
vtb ref <id> "lib/ib_ex/client/messages/market_data/request_data.ex"

# Specific line
vtb ref <id> "lib/ib_ex/client/messages/market_data/request_data.ex:L42"

# Line range with name
vtb ref <id> "lib/ib_ex/client.ex:L42-60" --name "send_request" --desc "Main request dispatch"

# Link test to testing criterion
vtb criterion-ref <id> 1 "test/ib_ex/client/messages/market_data/request_data_test.exs:L10-25" \
  --name "test_new_returns_struct"

# View and remove references
vtb refs <id>
vtb unref <id> "lib/ib_ex/client.ex"
vtb unref <id> --all
```

---

## Querying Tasks

### Listing

```bash
vtb list                              # All tasks (tree view)
vtb list --flat                       # Flat table view
vtb list --workflow implementation    # By workflow
vtb list --step coding                # By current step
vtb list -w impl --step coding        # Combine workflow and step
vtb list --level ticket               # By level
vtb list --priority high              # By priority
vtb list --tag backend                # By tag
vtb list --parent <id>                # Children of a task
vtb list --root                       # Only root items
vtb list --search "auth"              # Search title/description
vtb list --all                        # Include completed items
```

### Viewing Details

```bash
vtb show <id>                         # Full task details with sections, refs, relationships
```

### Finding Actionable Work

```bash
vtb ready                             # Highest-level items ready for work or triage
```

### Checking Current Work

```bash
vtb list --workflow implementation    # What's in implementation
vtb blockers <id>                     # What's blocking a task
```

---

## Typical Workflow (End to End)

```bash
# 1. Plan
vtb add "Implement TickByTick support" -l epic -d "Real-time tick data"
vtb add "Add request messages" -l ticket --parent <epic-id>
vtb add "Add response parsing" -l ticket --parent <epic-id>

# 2. Document and triage tickets
vtb section <ticket-id> goal "..."
vtb section <ticket-id> step "..."
vtb section <ticket-id> testing_criterion "UNIT: ..."
vtb section <ticket-id> testing_criterion "INTEGRATION: ..."
vtb section <ticket-id> constraint "..."
vtb section <ticket-id> constraint "..."
vtb transition-to <ticket-id> todo

# 3. Set up workflow
vtb workflow assign <ticket-id> implementation

# 4. Work
vtb transition-to <ticket-id> implementation:coding
vtb step-done <ticket-id> 1
vtb step-done <ticket-id> 2

# 5. Review and complete
vtb transition-to <ticket-id> review
vtb transition-to <ticket-id> done

# 6. Move to next
vtb ready
vtb transition-to <next-id> implementation
```

---

## Human Review

```bash
vtb review <id>                       # Toggle needs_human_review flag
vtb review <id> --set true            # Explicitly set
vtb review <id> --set false           # Clear
```

Tasks with `needs_human_review: true` pause automated workflow advancement.

## Execution Tracking

Record workflow execution history for auditing:

```bash
vtb execution create <task-id>                                    # Start execution record
vtb execution log <execution-id> "Processing..." --level info     # Add log entry
vtb execution update <execution-id> --status completed            # Mark complete
vtb execution list <task-id>                                      # List executions
vtb execution show <execution-id>                                 # Show details
```

## Updating Tasks

```bash
vtb update <id> --title "New title"
vtb update <id> --description "New description"
vtb update <id> --priority high
vtb update <id> --add-tag urgent --add-tag backend
vtb update <id> --remove-tag old-tag
vtb update <id> --level ticket
vtb update <id> --parent <parent-id>
vtb update <id> --parent ""              # Remove parent
```

**Never use `vtb update` for workflow/step changes** — use `vtb transition-to` instead.

## Deleting Tasks

```bash
vtb delete <id>                          # Delete single task
vtb delete <id> --cascade                # Delete task and all children
```
