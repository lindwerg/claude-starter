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

## Sprint Auto-Continuation

When all tasks in current sprint are DONE, Ralph automatically continues to next sprint:

```
Sprint 1 tasks ALL DONE
        ↓
Check sprint-plan.md for Sprint 2 stories
        ↓
Generate task-queue.yaml for Sprint 2
        ↓
Continue executing Sprint 2 tasks
        ↓
... repeat until ALL SPRINTS DONE
```

### Auto-Continuation Logic

```
after ALL tasks in task-queue.yaml are DONE:
  1. Read current sprint number from task-queue.yaml
  2. current_sprint = sprint + 1

  3. Read docs/sprint-plan-*.md
  4. Find stories assigned to Sprint {current_sprint}

  5. If no stories for next sprint:
     → PROJECT COMPLETE

  6. Otherwise:
     → Decompose stories into atomic tasks
     → Write new task-queue.yaml (sprint: current_sprint)
     → Continue loop with new tasks
```

### Implementation

After all tasks done, check for next sprint:

```bash
# 1. Get current sprint number
current_sprint=$(yq '.sprint' .bmad/task-queue.yaml)
next_sprint=$((current_sprint + 1))

# 2. Find sprint plan
sprint_plan=$(ls docs/sprint-plan-*.md | head -1)

# 3. Check if next sprint has stories
# Look for "| Sprint ${next_sprint} |" in the stories table
```

**If next sprint has stories:**
1. Extract stories for Sprint N+1 from sprint-plan.md
2. Decompose each story into atomic tasks (30-60 min)
3. Write new `.bmad/task-queue.yaml` with sprint: N+1
4. Continue Ralph Loop

**If no more sprints:**
```xml
<promise>PROJECT_COMPLETE</promise>
<summary>
All sprints completed!
- Sprints: 5/5 done
- Total stories: 42
- Total tasks: 287
- Total commits: 287
</summary>
```

### Task Decomposition (inline)

When generating task-queue for next sprint, follow same rules:

| Task Type | Estimated | Example |
|-----------|-----------|---------|
| api | 30 min | Add endpoint to openapi.yaml |
| backend | 30-45 min | Implement controller/service |
| frontend | 30-45 min | Create component/hook |
| test | 45-60 min | Write integration tests |

**Dependency order:** api → backend → frontend → test

## Output Format

**Sprint Complete, Continuing:**
```xml
<promise>SPRINT_COMPLETE</promise>
<summary>
Sprint 1 completed!
- Stories: 8/8 done
- Tasks: 67/67 done
</summary>
<next_action>
Generating task-queue for Sprint 2...
Found 6 stories, creating 48 tasks.
Continuing automatically.
</next_action>
```

**All Sprints Complete:**
```xml
<promise>PROJECT_COMPLETE</promise>
<summary>
All sprints completed!
- Sprints: 5/5
- Stories: 42/42
- Tasks: 287/287
- Total time: 18h 45m
</summary>
```

**Success (single sprint, legacy):**
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
- `/validate-sprint` — Validates + generates task queue
- `/dev-story` — Manual story implementation
- `/implement_task` — Single task execution
- `thoughts/ledgers/` — State persistence

---

## CRITICAL: Fresh Context Pattern

**Each task MUST be executed via subagent with FRESH context.**

This prevents context drift that ruins long-running agents.

```
Ralph Orchestrator (main context - minimal)
        │
        ├── Task Agent: TASK-001-A (fresh context)
        │       └── Reads task details
        │       └── Implements
        │       └── Returns receipt
        │
        ├── Task Agent: TASK-001-B (fresh context)
        │       └── ...
```

### Subagent Prompt Template

```markdown
Execute atomic task from Ralph Loop.

## Task
- ID: {task.id}
- Title: {task.title}
- Type: {task.type}
- Story: {task.story_id}

## Required Outputs
{task.outputs}

## Acceptance Criteria
{task.acceptance}

## Completed Dependencies
{task.depends_on}

## Instructions
1. Read relevant files (dependencies outputs)
2. Implement following VSA/FSD architecture
3. Verify acceptance criteria met
4. Return completion evidence

## Return Format
\`\`\`yaml
status: done  # or blocked
files_created: [...]
files_modified: [...]
commit_message: "feat(scope): description"
acceptance:
  - criterion: "..."
    passed: true
\`\`\`
```

### Using Task Tool

```typescript
// In Ralph orchestrator
const result = await Task({
  subagent_type: task.type === 'backend' ? 'backend-agent' :
                 task.type === 'frontend' ? 'frontend-agent' :
                 task.type === 'test' ? 'test-agent' : 'general-purpose',
  prompt: buildTaskPrompt(task),
  description: `Execute ${task.id}`
});
```

---

## Re-anchoring (Start of Each Iteration)

Before finding next task, ALWAYS re-anchor:

```bash
# 1. Read progress state
cat .bmad/ralph-progress.yaml

# 2. Read task queue
cat .bmad/task-queue.yaml | yq '.summary'

# 3. Check recent git activity
git log --oneline -5

# 4. Find next available task
yq '.tasks[] | select(.status == "pending")' .bmad/task-queue.yaml | head -1
```

---

## Progress Tracking

**File:** `.bmad/ralph-progress.yaml`

Updated after EACH task completion:

```yaml
session_id: "abc123"
started_at: "2026-01-17T10:00:00Z"
last_updated: "2026-01-17T12:30:00Z"

current_sprint: 1
current_task: "TASK-001-D"

stats:
  tasks_completed: 15
  tasks_blocked: 0
  tasks_remaining: 32

history:
  - task: "TASK-001-A"
    status: "done"
    duration_minutes: 25
    commit: "abc1234"
```

---

## Context Management

### When to /clear

- After every 10-15 tasks completed
- When context usage > 70%
- After sprint completion

### How to Resume After /clear

1. Ralph reads `.bmad/ralph-progress.yaml`
2. Finds `current_task` or next pending
3. Continues from that point

**Progress file is the source of truth after /clear.**

---

## Stop Hook (Auto-Continue)

Ralph uses Stop hook to automatically continue if tasks remain.

**Hook checks:**
1. Is there a completion marker? (PROJECT_COMPLETE, BLOCKED)
2. Are there pending tasks in queue?
3. If yes → continue with next task

**This enables overnight autonomous execution.**
