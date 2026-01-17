---
name: ralph-loop
description: Autonomous implementation loop with atomic task queue. Use when implementing features automatically - Ralph executes tasks one by one from task-queue.yaml
allowed-tools: [Bash, Read, Write, Edit, Grep, Glob, Task, TodoWrite]
---

# Ralph Loop — Autonomous Task Queue Executor

**R**elentless **A**utonomous **L**oop for **P**roduct **H**acking

Ralph executes atomic tasks from `.bmad/task-queue.yaml` one by one until completion or blocker.

## When to Use

- After `/bmad:sprint-planning` created task queue
- When you want autonomous implementation
- For batch execution of multiple stories
- When you need hands-off development

## Prerequisites

Before running Ralph Loop:
1. Run `/bmad:sprint-planning` to create sprint plan
2. Verify `.bmad/task-queue.yaml` exists
3. Ensure openapi.yaml is in place (if API tasks exist)

## Core Loop

```
┌─────────────────────────────────────────────────────────────┐
│                     RALPH LOOP                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Load task-queue.yaml                                     │
│                    ↓                                         │
│  2. Find next task (pending + deps done)                     │
│                    ↓                                         │
│  3. Execute task via appropriate subagent                    │
│                    ↓                                         │
│  4. Verify acceptance criteria                               │
│                    ↓                                         │
│  5. Update status → done | blocked                           │
│                    ↓                                         │
│  6. Commit changes                                           │
│                    ↓                                         │
│  7. Auto-transition to next task ─────────┐                  │
│                    ↓                      │                  │
│  8. Repeat until: ALL DONE or BLOCKED     │                  │
│                                           │                  │
└───────────────────────────────────────────┘                  │
            ↑                                                  │
            └──────────────────────────────────────────────────┘
```

## State Machine

```
┌─────────┐    start    ┌─────────────┐   pass    ┌──────────┐
│ PENDING │───────────▶│ IN_PROGRESS │─────────▶│   DONE   │
└─────────┘             └─────────────┘           └──────────┘
                              │                        │
                              ▼ fail                   │
                        ┌──────────┐                   │
                        │ RETRYING │───────────────────┤
                        └──────────┘   retry < 3       │
                              │                        │
                              ▼ retry >= 3             │
                        ┌─────────┐                    │
                        │ BLOCKED │                    │
                        └─────────┘                    │
                              │                        │
                              ▼                        ▼
                     [STOP: Human needed]    [CONTINUE: Next task]
```

## Task Queue Workflow

### 1. Load Queue

```bash
cat .bmad/task-queue.yaml
```

Read current state:
- `current_task` — task being executed (or null)
- `tasks[]` — all tasks with statuses
- `summary` — completed/blocked counts

### 2. Find Next Task

Algorithm:
```
for task in tasks:
  if task.status == "pending":
    if all(dep.status == "done" for dep in task.depends_on):
      return task  # This is next task
return null  # No available tasks
```

**Priority order:**
1. `api` tasks first (spec before implementation)
2. `backend` tasks (data layer)
3. `frontend` tasks (UI layer)
4. `test` tasks last (verify implementation)

### 3. Execute Task

**Update queue:**
```yaml
current_task: "TASK-001-C"
tasks:
  - id: "TASK-001-C"
    status: "in_progress"
    started_at: "2026-01-17T10:30:00Z"
```

**Route to subagent by type:**

| Task Type | Subagent | Focus |
|-----------|----------|-------|
| `api` | API Agent | Update openapi.yaml, ensure spec validity |
| `backend` | Backend Agent | VSA slice: controller, service, dto, schema |
| `frontend` | Frontend Agent | FSD feature: UI, model, api hooks |
| `test` | Test Agent | Unit + integration tests, coverage |
| `devops` | DevOps Agent | CI/CD, Docker, deploy configs |

**Subagent prompt template:**
```
Execute task: {task.id}

**Context:**
- Story: {task.story_id}
- Title: {task.title}
- Type: {task.type}

**Outputs required:**
{task.outputs}

**Acceptance criteria:**
{task.acceptance}

**Dependencies completed:**
{task.depends_on} — files already created

Follow VSA/FSD architecture rules strictly.
Return DONE when all acceptance criteria met.
Return BLOCKED if you encounter unresolvable issue.
```

### 4. Verify Task

After subagent completes:

1. **Check outputs exist:**
   ```bash
   for file in task.outputs:
     ls -la $file
   ```

2. **Check acceptance criteria:**
   - For backend: verify VSA structure, Zod schemas
   - For frontend: verify FSD imports, TypeScript strict
   - For tests: run tests, check coverage

3. **Run relevant tests:**
   ```bash
   pnpm test:run --filter="{feature}"
   ```

### 5. Update Queue

**On success:**
```yaml
tasks:
  - id: "TASK-001-C"
    status: "done"
    completed_at: "2026-01-17T10:45:00Z"
summary:
  completed_tasks: +1
```

**On failure:**
```yaml
tasks:
  - id: "TASK-001-C"
    status: "retrying"  # or "blocked" if retries >= max_retries
    retries: +1
    error: "Zod schema validation failed"
```

### 6. Commit Changes

After each successful task:
```bash
/commit "feat({feature}): {task.title}"
```

Commit message format:
- `feat(auth): add user schema to Prisma`
- `feat(auth): implement register controller`
- `test(auth): add integration tests`

### 7. Auto-Transition

Loop continues automatically to next task.

**Stop conditions:**
- All tasks done → `<promise>COMPLETE</promise>`
- Task blocked → `<promise>BLOCKED</promise>`
- Max iterations reached → `<promise>LIMIT_REACHED</promise>`

## Retry Logic

```
MAX_RETRIES_PER_TASK = 3

for each task:
  retries = 0
  while retries < MAX_RETRIES:
    result = execute_task(task)
    if result.success:
      mark_done(task)
      break
    retries++
    if retries >= MAX_RETRIES:
      mark_blocked(task, result.error)
      STOP("Human intervention required")
```

## Iteration Limits

```yaml
limits:
  per_task: 5       # Max attempts per single task execution
  per_story: 30     # Max tasks per story (safety)
  per_session: 100  # Max tasks per Ralph session
```

## Output Format

**Success:**
```xml
<promise>COMPLETE</promise>
<summary>
Sprint 1 completed!
- Stories: 8/8 done
- Tasks: 67/67 done
- Time: 4h 23m
- Files created: 47
- Files modified: 12
- Tests: 156 passed
- Coverage: 87%
</summary>
```

**Blocked:**
```xml
<promise>BLOCKED</promise>
<blocker>
Task: TASK-003-D
Story: STORY-003
Type: backend
Error: Database migration conflict - column already exists
Retries: 3/3 exhausted
</blocker>
<action_required>
Human must resolve migration conflict in:
- backend/prisma/migrations/20260117_add_payments/
Then run: /ralph-loop --resume
</action_required>
```

## Usage Examples

### Start Fresh

```
/ralph-loop

Starting Ralph Loop...
Loading task queue: .bmad/task-queue.yaml
Found 67 tasks, 0 completed

Starting: TASK-001-A (Add User schema to Prisma)
...
```

### Resume After Block

```
/ralph-loop --resume

Resuming Ralph Loop...
Last blocked task: TASK-003-D
Status: blocked → pending (human resolved)

Continuing from: TASK-003-D
...
```

### Check Progress

```bash
# Quick status
yq '.summary' .bmad/task-queue.yaml

# Completed tasks
yq '.tasks[] | select(.status == "done")' .bmad/task-queue.yaml

# Current task
yq '.current_task' .bmad/task-queue.yaml

# Blocked tasks
yq '.tasks[] | select(.status == "blocked")' .bmad/task-queue.yaml
```

## Integration with Ledger

Ralph updates continuity ledger automatically:

```markdown
# thoughts/ledgers/CONTINUITY_CLAUDE-ralph.md

## State
- Done:
  - [x] TASK-001-A: Add User schema
  - [x] TASK-001-B: Add auth endpoints to openapi.yaml
  - [x] TASK-001-C: Implement register controller
- Now: [→] TASK-001-D: Implement register service
- Next: TASK-001-E: Create registration form

## Progress
- Sprint 1: 23/67 tasks (34%)
- Current story: STORY-001 (User Authentication)
```

## Best Practices

1. **Run sprint-planning first** — Ralph needs task-queue.yaml
2. **Check queue before starting** — verify tasks look correct
3. **Monitor early tasks** — first few iterations catch issues
4. **Let Ralph run** — don't interrupt mid-task
5. **Review commits** — Ralph commits after each task
6. **Handle blocks promptly** — unblock and resume

## Troubleshooting

**No tasks found:**
- Check `.bmad/task-queue.yaml` exists
- Verify tasks have status `pending`
- Check dependencies are `done`

**Stuck in retries:**
- Check error message in task
- Verify acceptance criteria are achievable
- May need to simplify task

**Tests failing:**
- Run tests manually: `pnpm test:run`
- Check test configuration
- Verify mock setup

## See Also

- `/bmad:sprint-planning` — Creates task queue
- `/dev-story` — Manual story implementation
- `/implement_task` — Single task execution
- `thoughts/ledgers/` — State persistence
