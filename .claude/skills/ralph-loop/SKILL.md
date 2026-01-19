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

| Task Type | subagent_type | Responsibilities |
|-----------|---------------|------------------|
| `api` | `api-agent` | OpenAPI spec only, no tests |
| `implementation` | Dynamic | Test + Code together (TDD workflow) |
| `devops` | `devops-agent` | CI/CD, Docker, no tests |
| `e2e` | `test-agent` | Playwright E2E tests |

**Implementation task routing (based on outputs):**
- If `outputs` contains `backend/**/*.ts` → `backend-agent`
- If `outputs` contains `frontend/**/*.tsx` → `frontend-agent`
- If both backend AND frontend → error (split into 2 tasks)

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

## TDD Rules for Implementation Tasks

**For `implementation` type tasks:**

Ralph spawns ONE subagent that executes ALL TDD phases sequentially.

### Phase 1: RED (Write Failing Test)

**Goal:** Create test(s) that describe expected behavior.

**Subagent instructions:**
1. Read `task.tdd_phases.red.tasks`
2. Create test file (*.test.ts or *.integration.test.ts)
3. Write test cases from acceptance criteria marked `[RED]`
4. Run `pnpm test`
5. **VERIFY:** Tests MUST FAIL
   - If tests pass → ERROR (no implementation exists yet!)
   - If tests fail → SUCCESS (expected behavior)
6. Show failure output in response
7. **DO NOT EXIT** — proceed to GREEN phase

**Duration:** 15-20 minutes

**Output:** Failing test file(s)

### Phase 2: GREEN (Implement Code)

**Goal:** Write minimal code to make tests pass.

**Subagent instructions:**
1. Read failing tests from RED phase
2. Read `task.tdd_phases.green.tasks`
3. Implement code from acceptance criteria marked `[GREEN]`:
   - Controller (HTTP layer)
   - Service (business logic)
   - DTO (Zod validation)
   - Repository (data access) if needed
4. Run `pnpm test` frequently during implementation
5. **VERIFY:** ALL tests PASS (including new ones from RED)
   - If tests still fail → continue implementing
   - If tests pass → SUCCESS
6. **DO NOT EXIT** — proceed to REFACTOR (if needed) then GATES

**Duration:** 30-60 minutes

**Output:** Implementation files + passing tests

### Phase 3: REFACTOR (Optional)

**Goal:** Improve code quality without changing behavior.

**Subagent instructions:**
1. Read `task.tdd_phases.refactor.tasks` (if present)
2. Review GREEN phase code for improvements:
   - Extract duplicated logic
   - Better naming
   - Simplify complexity
   - Add type safety
3. Run `pnpm test` after each refactor
4. **VERIFY:** Tests STILL PASS
   - If tests break → revert change
   - If tests pass → keep improvement
5. **DO NOT EXIT** — proceed to GATES

**Duration:** 10-15 minutes (optional)

**Output:** Improved code, tests still passing

### Phase 4: GATES (Mandatory)

**Goal:** Verify code meets quality standards.

**Subagent instructions:**
1. Run ALL quality gates from `task.tdd_phases.gates.verify`:
   ```bash
   pnpm typecheck  # Must exit 0 (no TS errors)
   pnpm lint       # Must exit 0 (no lint errors)
   pnpm test       # Must show all tests pass
   ```
2. **IF ANY GATE FAILS:**
   - Fix the issue (go back to GREEN/REFACTOR)
   - Re-run gates
   - Increment `task.retries`
3. **IF ALL GATES PASS:**
   - Mark task as DONE
   - Return success to Ralph
4. **IF retries >= max_retries:**
   - Mark task as BLOCKED
   - Return failure to Ralph

**Duration:** 5-10 minutes (including fixes)

**Output:** Quality-verified, production-ready code

---

**Critical Rules:**

1. **Single Subagent Execution:** All phases run in ONE subagent spawn
2. **Sequential Flow:** RED → GREEN → REFACTOR → GATES (no skipping)
3. **Gates at End:** Quality gates checked ONCE after GREEN (not after RED!)
4. **No Early Exit:** Subagent completes all phases before returning
5. **Task = DONE:** Only when all phases + gates complete successfully

---

**NEW: Task structure with TDD phases:**

```yaml
- id: "TASK-001-C"
  type: "implementation"
  title: "Login service with validation"
  tdd_phases:
    red:
      description: "Write FAILING test(s)"
      tasks:
        - "Create auth.integration.test.ts"
        - "Test: POST /auth/telegram valid → 200"
        - "Test: POST invalid → 401"
      verify:
        command: "pnpm test"
        expected: "fail"
    green:
      description: "Implement code"
      tasks:
        - "Implement controller.ts"
        - "Implement service.ts"
        - "Implement dto.ts"
      verify:
        command: "pnpm test"
        expected: "pass"
    gates:
      required: true
      verify:
        - command: "pnpm typecheck"
          expected_exit_code: 0
        - command: "pnpm lint"
          expected_exit_code: 0
        - command: "pnpm test"
          expected_exit_code: 0
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
2. `implementation` tasks (test + code together)
3. `e2e` tasks last (full flow verification)

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
| `implementation` | Backend/Frontend Agent | TDD workflow: RED → GREEN → GATES |
| `devops` | DevOps Agent | CI/CD, Docker, deploy configs |
| `e2e` | Test Agent | Playwright E2E tests |

**Subagent routing for `implementation` tasks:**
- If outputs contain `backend/**/*.ts` → Backend Agent
- If outputs contain `frontend/**/*.tsx` → Frontend Agent

**Subagent prompt template (для implementation tasks):**
```
Execute task: {task.id} (type: implementation)

**Context:**
- Story: {task.story_id}
- Title: {task.title}
- Estimated time: {task.estimated_minutes} minutes (all phases)

**TDD Workflow (complete in THIS session):**

═══════════════════════════════════════════════════════
PHASE 1: RED (Write Failing Test)
═══════════════════════════════════════════════════════

{task.tdd_phases.red.tasks}

→ Create: {test_file_path}
→ Run: pnpm test
→ VERIFY: Tests FAIL (show failure output)
→ DO NOT proceed until failure confirmed

═══════════════════════════════════════════════════════
PHASE 2: GREEN (Implement Code)
═══════════════════════════════════════════════════════

{task.tdd_phases.green.tasks}

→ Implement minimal code to make tests pass
→ Run: pnpm test frequently
→ VERIFY: ALL tests PASS (including new ones)
→ Show passing test output

═══════════════════════════════════════════════════════
PHASE 3: REFACTOR (Optional)
═══════════════════════════════════════════════════════

{task.tdd_phases.refactor.tasks if present}

→ Improve code quality (if needed)
→ Run: pnpm test after changes
→ VERIFY: Tests STILL PASS

═══════════════════════════════════════════════════════
PHASE 4: GATES (Mandatory Quality Check)
═══════════════════════════════════════════════════════

→ Run: pnpm typecheck (must exit 0)
→ Run: pnpm lint (must exit 0)
→ Run: pnpm test (must show all pass)
→ VERIFY: ALL GATES PASS

IF ANY GATE FAILS:
- Fix the issue
- Re-run gates
- Do NOT mark done until all pass

═══════════════════════════════════════════════════════

**Required Outputs:**
{task.outputs}

**Acceptance Criteria:**
{task.acceptance}

**Dependencies Completed:**
{task.depends_on} — these files already exist

**Architecture Rules:**
- Backend: Follow VSA (features/{feature}/{slice}/*.ts)
- Frontend: Follow FSD (entities/features/widgets/pages/shared)
- TypeScript: strict mode, no any, Zod validation

**Return Format:**
- DONE: When all phases + gates complete
- BLOCKED: If unresolvable issue after 3 attempts
- Include: Test results + gate outputs in response

Begin with RED phase now!
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
      # Try adaptive unblocking first
      if can_auto_unblock(task):
        create_unblock_tasks(task)
        reset_retries(task)
        continue
      else:
        mark_blocked(task, result.error)
        STOP("Human intervention required")
```

## Adaptive Unblocking (Auto-Resolution)

**NEW:** Ralph can now automatically resolve certain blockers by creating new tasks.

### Supported Blockers

| Blocker Type | Detection Signal | Resolution |
|--------------|------------------|------------|
| `missing_auth` | 401 Unauthorized, "authentication required" | Create STORY-000: Basic JWT Auth (6 tasks) |
| `missing_dependency` | "cannot find module", "import not found" | Create task to install dependency |
| `schema_mismatch` | "column not found", Prisma errors | Create migration task |
| `missing_endpoint` | 404, "endpoint not found" | Create API endpoint task |

### How It Works

```
Task fails with 401 Unauthorized
        ↓
Ralph detects "missing_auth" blocker
        ↓
Generates STORY-000: JWT Authentication
        ↓
Inserts 6 tasks BEFORE blocked task:
  - TASK-000-A: Add /auth to openapi.yaml
  - TASK-000-B: Implement auth service
  - TASK-000-C: Create controllers
  - TASK-000-D: Add auth middleware
  - TASK-000-E: Frontend auth hooks
  - TASK-000-F: Integration tests
        ↓
Blocked task now depends on TASK-000-F
        ↓
Resets retries, continues execution
```

### Example: E2E Test Requires Auth

```yaml
# Original queue
tasks:
  - id: "TASK-006-E2E"
    title: "E2E tests for Characters page"
    type: "e2e"
    status: "blocked"
    blocker_reason: "401 Unauthorized - authentication required"
    retries: 3

# After adaptive unblocking
tasks:
  - id: "TASK-000-A"
    story_id: "STORY-000"
    title: "Add /auth endpoints to openapi.yaml"
    status: "pending"

  # ... 5 more auth tasks ...

  - id: "TASK-000-F"
    story_id: "STORY-000"
    title: "Auth integration tests"
    status: "pending"

  - id: "TASK-006-E2E"
    title: "E2E tests for Characters page"
    status: "pending"  # unblocked!
    depends_on: ["TASK-006-E", "TASK-000-F"]  # now depends on auth
    retries: 0  # reset
```

### When Adaptive Unblocking Fails

If Ralph cannot auto-resolve (e.g., `unknown` blocker type):
- Task marked as `blocked`
- Human intervention required
- Use `/ralph-loop --resume` after fixing

### Blockers Not Auto-Resolved

- Complex architectural issues
- Business logic decisions
- Configuration/deployment problems
- Unknown error types

For these, human must resolve and resume.

---

## ADAPTIVE UNBLOCKING — EXECUTION STEPS

**When task fails after max retries (3), execute these steps BEFORE marking as blocked:**

### Step 1: Save Blocker Reason

```bash
# Update task-queue.yaml with blocker reason
yq -i "(.tasks[] | select(.id == \"$TASK_ID\")).blocker_reason = \"$ERROR_MESSAGE\"" .bmad/task-queue.yaml
```

Save the FULL error message from task failure.

### Step 2: Analyze Blocker Type

Read the blocker_reason and classify:

```bash
BLOCKER_REASON=$(yq '.tasks[] | select(.id == "'$TASK_ID'") | .blocker_reason' .bmad/task-queue.yaml)

# Classify blocker type
if echo "$BLOCKER_REASON" | grep -qiE "401|unauthorized|authentication required"; then
  BLOCKER_TYPE="missing_auth"
elif echo "$BLOCKER_REASON" | grep -qiE "cannot find module|import.*not found"; then
  BLOCKER_TYPE="missing_dependency"
elif echo "$BLOCKER_REASON" | grep -qiE "prisma|column.*not found|relation.*does not exist"; then
  BLOCKER_TYPE="schema_mismatch"
elif echo "$BLOCKER_REASON" | grep -qiE "404|endpoint.*not found"; then
  BLOCKER_TYPE="missing_endpoint"
else
  BLOCKER_TYPE="unknown"
fi
```

### Step 3: Generate Unblock Tasks

**For missing_auth blocker:**

```bash
# Call generate-auth-story script
bash .claude/orchestrator/lib/generate-auth-story.sh "$TASK_ID"

# Script will:
# 1. Create STORY-000 with 6 auth tasks
# 2. Insert BEFORE blocked task
# 3. Add dependency: blocked task depends_on TASK-000-F
# 4. Update task counts in summary
```

**After successful generation:**

1. Reset blocked task to `status: "pending"`
2. Reset `retries: 0`
3. Continue Ralph Loop — auth tasks will execute first
4. Blocked task will execute after auth is complete

### Step 4: If Auto-Unblock Fails

If blocker type is "unknown" or script fails:
- Mark task as `status: "blocked"`
- Output: `<promise>BLOCKED</promise>`
- Include blocker_reason in output
- Stop execution, require human intervention

---

## IMPLEMENTATION IN RALPH LOOP

**When executing Ralph Loop, after task fails 3 times:**

```
Task: TASK-006-E2E failed (retry 3/3)
  ↓
Read error output from last attempt
  ↓
Save blocker_reason to YAML (Step 1)
  ↓
Analyze blocker type (Step 2)
  ↓
IF blocker_type == "missing_auth":
  ├─ Run: bash .claude/orchestrator/lib/generate-auth-story.sh TASK-006-E2E
  ├─ Check exit code
  ├─ IF success (exit 0):
  │   ├─ Output: "✅ STORY-000 created, 6 auth tasks inserted"
  │   ├─ Reset TASK-006-E2E: status="pending", retries=0
  │   └─ Continue loop (auth tasks will execute first)
  └─ IF fail (exit 1):
      └─ Mark BLOCKED, require human
ELSE:
  └─ Mark BLOCKED, require human
```

### Example Output

```
[ralph] Task TASK-006-E2E failed (3/3 retries)
[ralph] Analyzing blocker...
[ralph] Blocker type: missing_auth
[ralph] ⚡ ADAPTIVE UNBLOCKING ACTIVATED
[ralph] Generating STORY-000: Basic JWT Authentication...
[ralph] ✅ Created 6 auth tasks (TASK-000-A through TASK-000-F)
[ralph] ✅ TASK-006-E2E now depends on TASK-000-F
[ralph] Resetting TASK-006-E2E to pending (retries: 0)
[ralph]
[ralph] Continuing with next task: TASK-000-A
```

---

## Iteration Limits

```yaml
limits:
  per_task: 5       # Max attempts per single task execution
  per_story: 30     # Max tasks per story (safety)
  per_session: 100  # Max tasks per Ralph session
```

## Sprint Auto-Continuation (VIA HOOKS)

**Sprint auto-continuation is now AUTOMATED via Claude Code hooks.**

Ralph Loop seamlessly transitions between sprints through a **hook-based enforcement system** that ensures quality gates, manual validation, and automatic continuation.

---

### How It Works

```
Sprint N → All tasks DONE
        ↓
Stop Hook: ralph-sprint-completion.sh
        ↓
1. Generate Sprint Review (stories, commits, learnings)
2. Run Quality Check (typecheck, lint, test, coverage)
3. Archive to .bmad/history/sprint-N/
4. Create marker: .bmad/sprint-validation-pending
5. Open browser for manual testing
6. BLOCK Ralph Loop with message
        ↓
🛑 Ralph BLOCKED → User validates in browser
        ↓
User runs: /validate-sprint
        ↓
validate-sprint skill:
  - Detects multi-sprint context (Step 0)
  - Reads last sprint from .bmad/history/sprint-N/
  - Generates task-queue.yaml for Sprint N+1
        ↓
PostToolUse Hook: ralph-validation-cleanup.sh
  - Removes .bmad/sprint-validation-pending marker
        ↓
Stop Hook: ralph-continue.sh
  - Detects pending tasks → CONTINUE
        ↓
Sprint N+1 → Ralph resumes automatically
```

---

### Enforcement Layers

**1. Sprint Completion Hook (Stop)**
- File: `.claude/hooks/ralph-sprint-completion.sh`
- Triggers: When Ralph Loop tries to stop
- Logic:
  - Check all tasks in task-queue.yaml are `status: done`
  - If YES → Archive sprint, create validation marker, BLOCK
  - If NO → Continue (ralph-continue.sh handles pending tasks)

**2. Validation Enforcement Hook (PreToolUse Task)**
- File: `.claude/hooks/ralph-validation-enforcer.sh`
- Triggers: Before spawning subagent (Task tool)
- Logic:
  - Check if `.bmad/sprint-validation-pending` exists
  - If YES → BLOCK with message "Run /validate-sprint"
  - If NO → Continue

**3. Validation Cleanup Hook (PostToolUse Write)**
- File: `.claude/hooks/ralph-validation-cleanup.sh`
- Triggers: After writing files (Write tool)
- Logic:
  - Check if file written is `task-queue.yaml`
  - Check if `.bmad/sprint-validation-pending` exists
  - If BOTH → Remove marker, unlock Ralph Loop

---

### Archived Sprint Structure

After each sprint completion, data is archived to:

```
.bmad/history/sprint-1/
├── task-queue.yaml       # Original task queue
├── sprint-review.md      # Generated report (stories, commits, learnings)
├── quality-report.json   # Results from typecheck/lint/test/coverage
└── commits.log           # List of git commit hashes
```

This preserves full history across all sprints.

---

### User Flow

**Sprint 1 → Sprint 2 transition:**

1. Ralph completes last task of Sprint 1
2. Stop hook blocks Ralph with message:
   ```
   🏁 SPRINT 1 COMPLETED
   ✅ All tasks completed
   📦 Archived to: .bmad/history/sprint-1/
   🔍 Quality gates: PASSED
   🌐 Browser opened for manual validation

   📋 NEXT STEP: Run /validate-sprint
   ```
3. User tests application in browser
4. User runs `/validate-sprint`
5. validate-sprint generates task-queue.yaml for Sprint 2
6. PostToolUse hook removes validation marker
7. Ralph Loop auto-resumes with Sprint 2 tasks

---

### Key Benefits

✅ **Enforcement over instructions** — Hooks physically block Ralph until validation completes
✅ **Manual validation checkpoint** — User tests before next sprint
✅ **Full sprint history** — All sprints archived with reviews and quality reports
✅ **Zero context loss** — Ralph picks up exactly where it left off
✅ **Quality gates** — typecheck/lint/test must pass before archiving

---

## Output Format

**Sprint Complete (Blocked):**
```xml
<promise>SPRINT_BLOCKED_FOR_VALIDATION</promise>
<summary>
Sprint 1 completed!
- Stories: 8/8 done
- Tasks: 67/67 done
- Archived to: .bmad/history/sprint-1/
</summary>
<next_action>
Run /validate-sprint to continue to Sprint 2
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
