---
name: ralph-loop
description: Autonomous implementation loop with atomic task queue. Use when implementing features automatically - Ralph executes tasks one by one from task-queue.yaml
allowed-tools: [Bash, Read, Write, Edit, Grep, Glob, Task, TodoWrite]
---

## MANDATORY: FIRST ACTIONS

**CRITICAL — DO THESE IMMEDIATELY BEFORE ANYTHING ELSE**

### 1. Create Progress Marker (FIRST!)

```bash
mkdir -p .bmad && echo "$(date -Iseconds)" > .bmad/ralph-in-progress
```

Run this Bash command RIGHT NOW before reading task queue.

### 2. Cleanup Stale Subagent Markers

Before each iteration, remove any stale subagent markers:

```bash
rm -f .bmad/subagent-active
```

This prevents stale markers from previous crashed subagents.

### 3. Use Subagents for Tasks (ENFORCED BY HOOK)

Ralph MUST execute each task via Task tool subagent. NEVER execute tasks directly in main context.

### Required Pattern

```
For EACH task:
1. Read task from task-queue.yaml
2. Update status to "in_progress"
3. SPAWN SUBAGENT via Task tool ← MANDATORY
4. Wait for subagent result
5. Update task status based on result
6. Commit changes
7. Move to next task
```

### Task Tool Call (REQUIRED)

```typescript
Task({
  subagent_type: getAgentType(task.type),  // backend-agent, frontend-agent, etc.
  description: `Execute ${task.id}`,
  prompt: buildTaskPrompt(task)
})
```

### Agent Type Mapping

| Task Type | subagent_type |
|-----------|---------------|
| `api` | `api-agent` |
| `backend` | `backend-agent` |
| `frontend` | `frontend-agent` |
| `test` | `test-agent` |
| `devops` | `devops-agent` |

### FORBIDDEN

```
❌ Reading task files and implementing directly
❌ Running pnpm/npm commands for task implementation
❌ Editing source files without spawning subagent
❌ "Let me implement this task..." in main context
```

### CORRECT

```
✅ "Spawning backend-agent to execute TASK-001-A..."
✅ Task({ subagent_type: "backend-agent", ... })
✅ "Agent returned: done. Moving to next task."
```

---

# Ralph Loop — Autonomous Task Queue Executor

**R**elentless **A**utonomous **L**oop for **P**roduct **H**acking

Ralph executes atomic tasks from `.bmad/task-queue.yaml` one by one until completion or blocker.

## CRITICAL: Avoid Infinite Loops

**NEVER run the same command repeatedly if it returns empty output!**

- `tsc --noEmit` returns EMPTY output when there are NO ERRORS (this is success!)
- `pnpm test` with no test files returns empty or warning (this is OK)
- Empty output ≠ failure. Check exit code instead.

**Max iterations per verification command: 1**
If a command succeeds (exit 0), move on. Do not retry.

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

## TDD Rules

**For `test` type tasks:**
- Write FAILING test first
- Verify `pnpm test` shows failure
- DO NOT implement — just test
- This is RED phase of TDD

**For `backend`/`frontend` type tasks:**
- Run tests FIRST to confirm they fail
- Implement code
- Run tests — must ALL PASS
- This is GREEN phase of TDD

**Task order enforces TDD:**
```yaml
# Task queue ensures test → implementation order:
- id: "TASK-001-A"
  type: "test"
  title: "Write FAILING auth test"
  acceptance:
    - "Create auth.integration.test.ts"
    - "pnpm test shows 1 FAILING test"

- id: "TASK-001-B"
  type: "backend"
  depends_on: ["TASK-001-A"]
  title: "Implement auth service"
  acceptance:
    - "AuthService validates initData"
    - "pnpm test shows ALL PASSING"  # GREEN!
```

## Task Queue Workflow

### 0. Create Progress Marker

Before starting the loop, create marker file for auto-resume:

```bash
mkdir -p .bmad
echo "$(date -Iseconds)" > .bmad/ralph-in-progress
```

This file enables:
- Context warning hook to show Ralph-specific messages
- SessionStart hook to prompt resume after /clear

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

### 4.5. Quality Gates — BACKPRESSURE (MANDATORY)

**BACKPRESSURE = задача НЕ МОЖЕТ быть done пока gates не пройдут.**

This is the most important section. Without backpressure, Ralph can "cheat" and mark tasks done without real completion.

#### Gate Commands

Run ALL gates before marking any task as done:

```bash
# 1. TypeScript (MUST PASS)
pnpm typecheck
# Empty output = SUCCESS (no errors)

# 2. Lint (MUST PASS)
pnpm lint
# Exit code 0 = SUCCESS

# 3. Tests (MUST PASS)
pnpm test
# All tests green = SUCCESS
```

#### Gate Logic

```
BEFORE marking task as DONE:
  ├── Run: pnpm typecheck
  │     └── Exit 0? → PASS
  │     └── Exit 1? → FAIL → task stays in_progress, fix errors
  │
  ├── Run: pnpm lint
  │     └── Exit 0? → PASS
  │     └── Exit 1? → FAIL → task stays in_progress, fix errors
  │
  └── Run: pnpm test
        └── All pass? → PASS
        └── Any fail? → FAIL → task stays in_progress, fix errors

ALL THREE PASS → task can be marked DONE
ANY FAILS → task CANNOT be marked done, must fix first
```

#### CRITICAL Rules

1. **Empty output = SUCCESS** for `tsc --noEmit` (no errors means nothing to print)
2. **Check exit code**, not output presence
3. **NO EXCEPTIONS** — even "small" tasks must pass gates
4. **Fix immediately** — don't skip to next task if gates fail

#### Acceptance Criteria → Required Tests

Each acceptance criterion SHOULD have a corresponding test:

```yaml
acceptance:
  - "POST /characters creates character"   # → test: POST returns 201
  - "GET /characters returns list"         # → test: GET returns array
  - "Validation rejects invalid data"      # → test: POST returns 400

# Task is NOT done until tests for EACH criterion exist and PASS
```

#### Gate Failure Response

```yaml
# If gates fail:
tasks:
  - id: "TASK-004-C"
    status: "in_progress"  # NOT done!
    gate_failures:
      - gate: "typecheck"
        error: "Property 'foo' does not exist on type 'Bar'"
        file: "src/features/auth/service.ts:42"
      - gate: "test"
        error: "Expected 201, received 500"
        test: "auth.integration.test.ts"
    retries: 1
```

#### Backpressure Philosophy

> "Don't prescribe how; create gates that reject bad work."
> — ralph-orchestrator

Ralph can try any approach, but the work MUST pass gates. This allows creativity while ensuring quality.

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

### 5.5. Record Task Receipt

After task completion, IMMEDIATELY update task-queue.yaml with receipt:

```yaml
receipt:
  work_summary: "<1-2 sentences what was done>"
  files_created: [...]
  files_modified: [...]
  tests_passed: true|false
  commit_hash: "<hash>"
  notes: "<any learnings for future Ralph>"
  duration_minutes: <number>
```

Also append to `.bmad/ralph-execution-log.jsonl`:
```bash
echo '{"task_id":"...","status":"done","work_summary":"...","tests_passed":true,"commit":"abc1234"}' >> .bmad/ralph-execution-log.jsonl
```

**This provides context for future Ralph iterations and enables debugging.**

### 6. Commit Changes (AUTO - NO CONFIRMATION)

After each successful task, commit directly WITHOUT asking:
```bash
git add -A && git commit -m "feat({feature}): {task.title}"
```

**DO NOT use /commit skill** — it asks for confirmation and breaks automation.

Commit message format:
- `feat(auth): add user schema to Prisma`
- `feat(auth): implement register controller`
- `test(auth): add integration tests`

### 6.5. Context Preservation & Scratchpad

Before moving to next task, ensure future Ralph has context:

1. **Read execution log**: `cat .bmad/ralph-execution-log.jsonl | tail -5`
2. **Check recent receipts**: Look at last 3 completed tasks in task-queue.yaml
3. **Understand dependencies**: What files were created that this task needs
4. **Update scratchpad**: Record learnings, blockers, decisions

#### Scratchpad (Shared Memory)

File: `.bmad/scratchpad.md` — persists across /clear and context resets.

```markdown
# Ralph Scratchpad

## Active Blockers
- [ ] Redis connection timeout in tests — need to mock
- [ ] Prisma generate fails without DB running

## Key Decisions
- **Auth**: Using JWT with 7-day expiry (not sessions)
- **Validation**: Zod over Yup (better TS inference)
- **Testing**: MSW for API mocking (not nock)

## Warnings
- DO NOT modify `shared/config/env.ts` — breaks CI
- Legacy code in `utils/old/` — ignore, will be deleted

## Learnings
- `pino` logger needs `exactOptionalPropertyTypes: false` or explicit undefined
- Express Router type: `Router` not `express.Router`
- Vitest needs `globals: true` for jest-compatible syntax

## File Patterns
- Controllers: `features/{name}/{slice}/controller.ts`
- Services: `features/{name}/{slice}/service.ts`
- Tests: `*.integration.test.ts` for API, `*.test.ts` for unit
```

#### Update Scratchpad When:
- Encounter unexpected error → add to Warnings
- Make architectural decision → add to Key Decisions
- Learn something useful → add to Learnings
- Hit a blocker → add to Active Blockers (with checkbox)

**This prevents duplicate work and provides learning from past iterations.**

### 7. Auto-Transition

Loop continues automatically to next task.

**Stop conditions:**
- All tasks done → `<promise>COMPLETE</promise>`
- Task blocked → `<promise>BLOCKED</promise>`
- Max iterations reached → `<promise>LIMIT_REACHED</promise>`

### 8. Cleanup on Complete

When loop finishes (COMPLETE, BLOCKED, or LIMIT_REACHED), remove progress marker:

```bash
rm -f .bmad/ralph-in-progress
```

This prevents false "Resume Ralph" prompts on next session start.

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
