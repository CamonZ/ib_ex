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
vtb transition-to <id> <workflow-id>                # Assign to workflow (first step)
vtb transition-to <id> <workflow-id>:<step-id>      # Specific workflow:step
```

Workflows and steps are identified by UUIDs. Use `vtb workflow list` and `vtb step list <workflow-id>` to discover the IDs for your project.

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

# Triage the ticket (validates sections — use workflow UUID from vtb workflow list)
vtb transition-to <id> <todo-workflow-id>

# Force past warnings (not recommended)
vtb transition-to <id> <todo-workflow-id> --force
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

# 5. Verify and triage (use workflow UUID from vtb workflow list)
vtb show <id>
vtb transition-to <id> <todo-workflow-id>
```

---

## Workflows and Steps

Workflows define the stages a task progresses through.

### Creating Workflows

```bash
# Basic workflow with steps (format: name:model)
vtb workflow add "Implementation" --step Coding:sonnet --step Testing:haiku --step Docs:haiku

# With description and auto-advance
vtb workflow add "Code Review" \
  -d "Review and approval process" \
  --step Review:sonnet \
  --step Approved:haiku \
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

All step commands use UUIDs. Use `vtb workflow list` and `vtb step list <workflow-id>` to discover IDs.

```bash
# Add a step to an existing workflow
vtb step add "Testing" -w <workflow-id> \
  --goal "Verify implementation" \
  --model sonnet \
  --order 1

# Add a final step (marks workflow complete)
vtb step add "Approved" -w <workflow-id> --final

# Add step with transition restrictions (--transition-to takes a step UUID)
vtb step add "Needs Work" -w <workflow-id> --transition-to <step-id>

# List, show, update, delete steps
vtb step list <workflow-id>
vtb step show <step-id>
vtb step update <step-id> --goal "New goal" --model opus
vtb step delete <step-id>
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

Use `transition-to` to move tasks **across** workflows or to specific steps. Both workflow and step arguments are UUIDs — use `vtb workflow list` and `vtb step list <workflow-id>` to discover them.

```bash
# Move to a workflow (starts at first step)
vtb transition-to <id> <workflow-id>

# Move to a specific step within a workflow
vtb transition-to <id> <workflow-id>:<step-id>

# Common lifecycle transitions (using UUIDs from your project)
vtb transition-to <id> <backlog-workflow-id>                         # Triage ticket for work
vtb transition-to <id> <implementation-workflow-id>                  # Start implementation
vtb transition-to <id> <implementation-workflow-id>:<testing-step-id> # Move to testing step
vtb transition-to <id> <review-workflow-id>                          # Submit for review
vtb transition-to <id> <done-workflow-id>                            # Mark complete
```

### Step Lifecycle (within a workflow)

Steps exist within a workflow. Before working on a task, determine which workflow it's in and which step it's currently at:

```bash
vtb step list <workflow-id>       # List all steps in the workflow (with order)
vtb show <task-id>                # See the task's current workflow and step
```

The step lifecycle commands manage a task's progression through these steps:

| Command | Purpose |
|---------|---------|
| `start-step` | Marks the current step as actively being worked on |
| `complete-step` | Marks the current step as done |
| `reject-step` | Rejects the current step and moves to a target step with optional feedback |

After completing a step, use `transition-to` to move the task to the next step.

#### `start-step` — Begin work on the current step

Signals that work has actively begun on a task's current workflow step. Call this before doing any work on the step.

```bash
vtb start-step <id>
```

**Arguments:**
- `<id>` — Task ID (case-insensitive)

**Behavior:**
- Marks the task's current step as "in progress"
- The task must already be assigned to a workflow and positioned at a step
- Idempotent — calling it again on an already-started step is a no-op

#### `complete-step` — Mark the current step as done

Marks the current step as completed. This does **not** automatically advance to the next step — use `transition-to` afterwards to move the task forward.

```bash
vtb complete-step <id>
```

**Arguments:**
- `<id>` — Task ID (case-insensitive)

**Behavior:**
- Marks the current step as completed
- The task should have been started with `start-step` first
- After completing, check which steps the task can transition to and use `transition-to` to advance

#### `reject-step` — Send a task back to a different step

Rejects the current step and transitions the task to a target step. Typically used during review to send work back for revision. Supports an optional feedback message explaining what needs to change.

```bash
vtb reject-step <id> <target-step-id>
vtb reject-step <id> <target-step-id> -f "Feedback message"
```

**Arguments:**
- `<id>` — Task ID (case-insensitive)
- `<target-step-id>` — The step ID to transition to (e.g., a previous step for rework)

**Options:**
- `-f`, `--feedback <message>` — Explanation of why the step was rejected and what needs to change

**Behavior:**
- Marks the current step as rejected
- Moves the task to the specified target step
- The feedback message is recorded and visible when viewing the task, giving the next worker context on what to fix
- The target step does not need to be a previous step — it can be any valid step in the workflow

#### Working Through a Workflow

Given a workflow (e.g. Implementation `<wf>`) with steps: Coding `<coding>` (order 0) → Testing `<testing>` (order 1) → Review `<review>` (order 2, final):

```bash
# 1. Determine the task's current position
vtb show <id>                              # Check current workflow and step
vtb step list <wf>                         # List all steps in the workflow

# 2. Work on the current step (Coding)
vtb start-step <id>                        # Mark Coding as in progress
# ... do the coding work ...
vtb complete-step <id>                     # Mark Coding as done

# 3. Transition to the next step
vtb transition-to <id> <wf>:<testing>      # Move to Testing

# 4. Work on the next step (Testing)
vtb start-step <id>                        # Mark Testing as in progress
# ... write and run tests ...
vtb complete-step <id>                     # Mark Testing as done

# 5. Transition to the final step
vtb transition-to <id> <wf>:<review>       # Move to Review

# 6. Work on the final step (Review)
vtb start-step <id>                        # Mark Review as in progress
# ... review the work ...
vtb complete-step <id>                     # Mark Review as done (final step → workflow complete)
```

#### Handling Rejections

When a step fails review, use `reject-step` to send it back with feedback. The `<target-step-id>` is the UUID of the step to return to:

```bash
# Reviewer finds issues during the Review step
vtb reject-step <id> <coding> -f "Missing error handling for invalid contracts"

# Task is now back at Coding step with feedback attached
vtb start-step <id>                        # Resume work on Coding
# ... fix the issues ...
vtb complete-step <id>                     # Mark Coding as done again
vtb transition-to <id> <wf>:<testing>      # Re-advance through the workflow
```

#### Step Lifecycle Summary

```
For each step in the workflow:
  1. vtb show <id>                              — confirm current step
  2. vtb start-step <id>                        — mark step as in progress
  3. (do the work for this step)
  4. vtb complete-step <id>                     — mark step as done
  5. vtb transition-to <id> <wf-id>:<step-id>   — move to the next step

All workflow and step arguments are UUIDs.
Use vtb workflow list and vtb step list <wf-id> to discover them.

Repeat until the final step is completed.

On rejection:
  vtb reject-step <id> <target-step-id> -f "..."  — send back to a previous step
  (restart the cycle from that step)
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
- **`start-step` / `complete-step` / `reject-step`** is for within-workflow step lifecycle
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
vtb list --workflow <workflow-id>     # By workflow
vtb list --step <step-id>             # By current step
vtb list -w <wf-id> --step <step-id>  # Combine workflow and step
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
vtb list --workflow <workflow-id>     # What's in a workflow
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
vtb transition-to <ticket-id> <backlog-wf-id>          # Triage to backlog/todo

# 3. Discover workflow and step UUIDs, then assign
vtb workflow list                                       # Find workflow UUIDs
vtb step list <impl-wf-id>                              # Find step UUIDs within it
vtb workflow assign <ticket-id> <impl-wf-id>

# 4. Work through steps (Coding → Testing → ...)
vtb transition-to <ticket-id> <impl-wf-id>:<coding-step-id>
vtb start-step <ticket-id>
vtb step-done <ticket-id> 1
vtb step-done <ticket-id> 2
vtb complete-step <ticket-id>
vtb transition-to <ticket-id> <impl-wf-id>:<testing-step-id>

vtb start-step <ticket-id>
# ... run tests ...
vtb complete-step <ticket-id>

# 5. Review and complete
vtb transition-to <ticket-id> <review-wf-id>
vtb start-step <ticket-id>
vtb complete-step <ticket-id>            # or reject-step if rework needed
vtb transition-to <ticket-id> <done-wf-id>

# 6. Move to next
vtb ready
vtb transition-to <next-id> <impl-wf-id>
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
