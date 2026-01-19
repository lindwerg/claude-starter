---
name: validate-sprint
description: Validate sprint plan and generate task queue for Ralph Loop
---

# Validate Sprint

Post-validation skill for sprint planning. Run after `/bmad:sprint-planning`.

## What It Does

1. **Validate Sprint Plan** — Check for INF-* stories (forbidden if architecture exists)
2. **Generate Task Queue** — Decompose stories into atomic tasks (30-60 min)
3. **Verify Readiness** — Ensure task-queue.yaml is ready for Ralph Loop

## Usage

```bash
# After sprint-planning
/bmad:sprint-planning

# Then validate and generate task queue
/validate-sprint
```

---

## Workflow

### Step 0: Check for Multi-Sprint Context

**Purpose:** Determine if this is Sprint 1 or a continuation from a previous sprint.

```bash
# Check for validation marker (created by ralph-sprint-completion hook)
ls -la .bmad/sprint-validation-pending 2>/dev/null

# Check for archived sprints
ls -d .bmad/history/sprint-* 2>/dev/null | tail -1
```

**Logic:**

1. **If `.bmad/sprint-validation-pending` exists:**
   - CONTEXT: Continuation from previous sprint
   - Read last archived sprint: `ls -d .bmad/history/sprint-* | tail -1`
   - Extract sprint number from directory name (e.g., `sprint-1` → 1)
   - **NEXT_SPRINT** = LAST_SPRINT + 1

2. **If marker does NOT exist:**
   - CONTEXT: First sprint (fresh start)
   - **NEXT_SPRINT** = 1

**Output:** Set variable `NEXT_SPRINT` for use in Step 5 (task queue generation).

---

### Step 1: Find Sprint Plan

```bash
ls docs/sprint-plan-*.md
```

Read the sprint plan file.

### Step 2: Check Architecture Exists

```bash
# Check if architecture skeleton exists
ls backend/src frontend/src backend/prisma/schema.prisma
```

**If ALL exist** → Architecture is ready, INF-* stories are FORBIDDEN.

### Step 3: Validate Stories

Read sprint plan and check:

**IF architecture exists:**
- [ ] NO INF-* stories (error if found!)
- [ ] NO "Infrastructure Stories" section
- [ ] First story is a BUSINESS FEATURE (Auth, Data Pipeline, etc.)

**Always check:**
- [ ] Stories have acceptance criteria
- [ ] Estimates are 3-8 points
- [ ] Dependencies make sense

**If validation fails** → Report errors and STOP.

### Step 4: Extract Stories for Target Sprint

From the sprint plan, find all stories assigned to **Sprint ${NEXT_SPRINT}** (determined in Step 0).

Parse the stories table:
```markdown
| ID | Story | Points | Sprint |
|----|-------|--------|--------|
| AUTH-001 | TMA Authentication | 5 | 1 |
| DATA-001 | Data Pipeline | 5 | 1 |
```

Filter stories where `Sprint == ${NEXT_SPRINT}`.

### Step 5: Decompose Stories into Atomic Tasks

For EACH story in Sprint ${NEXT_SPRINT}, create atomic tasks:

**Decomposition Rules:**
- 1 task = 30-90 minutes (включая test + реализацию)
- 1 task = 1 feature slice или 1 small change
- Clear outputs (test файл + implementation файлы)
- TDD: RED → GREEN → GATES в одной задаче

**Task Types:**
| Type | Description | Example |
|------|-------------|---------|
| `api` | OpenAPI spec changes | Add endpoint to openapi.yaml |
| `implementation` | Test + Code together | Write test + implement login service |
| `devops` | CI/CD/Docker | Update Dockerfile |
| `e2e` | Playwright E2E tests | Full user flow test |

**НОВЫЙ ПОДХОД: Parallel TDD**

Вместо раздельных задач (`test` → `backend`) теперь **одна задача = тест + код**:

```yaml
# ❌ СТАРОЕ (2 задачи, разорванный контекст)
TASK-001-A: Write test (type: test, 30min)
TASK-001-B: Implement code (type: backend, 45min)

# ✅ НОВОЕ (1 задача, единый контекст)
TASK-001-C: Login service with validation (type: implementation, 65min)
  tdd_phases:
    red: Write FAILING test
    green: Implement code to make test pass
    gates: Quality checks (typecheck/lint/test)
```

**Decomposition Pattern (Parallel TDD):**

```
Story: AUTH-001 "TMA Authentication" (5 points)

├── TASK-001-A: Prisma User model (35min, implementation)
│   Outputs:
│     - backend/prisma/schema.prisma
│     - backend/src/features/user/user.test.ts
│   Acceptance:
│     [RED] Write user.test.ts: User creation test (expect fail)
│     [GREEN] Add User model to schema.prisma
│     [GREEN] Run prisma generate
│     [GREEN] Test passes
│     [GATES] typecheck + lint + test pass
│
├── TASK-001-B: Auth endpoints spec (20min, api)
│   Outputs:
│     - backend/src/openapi.yaml
│   Acceptance:
│     - Add POST /auth/telegram to openapi.yaml
│     - Request/response schemas defined
│     - Spec validates (openapi-cli lint)
│
├── TASK-001-C: Login service with validation (65min, implementation)
│   Outputs:
│     - backend/src/features/auth/login/auth.integration.test.ts
│     - backend/src/features/auth/login/controller.ts
│     - backend/src/features/auth/login/service.ts
│     - backend/src/features/auth/login/dto.ts
│   Acceptance:
│     [RED] Write auth.integration.test.ts:
│       • POST /auth/telegram with valid initData → 200
│       • Invalid initData → 401
│       • Run pnpm test → expect 2 FAILING
│     [GREEN] Implement controller.ts (Express route)
│     [GREEN] Implement service.ts (initData validation)
│     [GREEN] Implement dto.ts (Zod schemas)
│     [GREEN] Run pnpm test → ALL PASS (2 new tests green)
│     [GATES] pnpm typecheck → exit 0
│     [GATES] pnpm lint → exit 0
│     [GATES] pnpm test → all pass
│
├── TASK-001-D: Frontend useAuth hook (50min, implementation)
│   Outputs:
│     - frontend/src/entities/auth/model/useAuth.test.ts
│     - frontend/src/entities/auth/model/useAuth.ts
│     - frontend/src/entities/auth/ui/AuthProvider.tsx
│   Acceptance:
│     [RED] Write useAuth.test.ts (expect fail)
│     [GREEN] Implement useAuth hook
│     [GREEN] Implement AuthProvider
│     [GREEN] Tests pass
│     [GATES] typecheck + lint + test pass
│
└── TASK-001-E: E2E auth flow (45min, e2e)
    Outputs:
      - e2e/auth.e2e.spec.ts
    Acceptance:
      - Write auth.e2e.spec.ts (Playwright)
      - Full login flow: UI → API → storage
      - E2E test passes
```

**Ключевые изменения:**

| Аспект | Старое | Новое |
|--------|--------|-------|
| Тип задачи | `test` + `backend` | `implementation` |
| Количество задач | 2 (test, code) | 1 (все вместе) |
| Контекст | Разорван | Единый |
| Время | 30 + 45 = 75 мин | 65 мин (оптимизация) |
| Spawns | 2 subagent | 1 subagent |
| Gates проверки | 2 раза | 1 раз (в конце) |

**TDD Workflow внутри задачи:**

Каждая `implementation` задача выполняется **одним subagent** в таком порядке:

```
1. RED Phase (15-20 min)
   └── Write failing test(s)
   └── Run pnpm test → verify FAILURE
   └── Do NOT implement yet!

2. GREEN Phase (30-60 min)
   └── Implement minimal code
   └── Run pnpm test frequently
   └── Verify ALL tests PASS

3. REFACTOR Phase (optional, 10-15 min)
   └── Improve code quality
   └── Tests still pass

4. GATES Phase (mandatory)
   └── pnpm typecheck → must exit 0
   └── pnpm lint → must exit 0
   └── pnpm test → all pass
   └── If ANY fail → fix and retry
   └── Mark DONE only when all pass
```

**Critical:** Subagent does NOT exit until ALL phases complete!

### Step 6: Generate task-queue.yaml

Create `.bmad/task-queue.yaml`:

```yaml
version: "1.0"
project: "{{project_name}}"
sprint: ${NEXT_SPRINT}  # Determined in Step 0 (1 for first sprint, N+1 for continuation)
created_at: "{{ISO date}}"

summary:
  total_stories: {{count}}
  total_tasks: {{count}}
  estimated_hours: {{sum of minutes / 60}}
  completed_tasks: 0
  blocked_tasks: 0

current_task: null

# BACKPRESSURE: Quality gates that MUST pass before any task is marked done
quality_gates:
  - name: "typecheck"
    command: "pnpm typecheck"
    required: true
    description: "TypeScript compilation must have zero errors"

  - name: "lint"
    command: "pnpm lint"
    required: true
    description: "ESLint must pass with zero errors"

  - name: "test"
    command: "pnpm test"
    required: true
    description: "All tests must pass"

# Execution context for future Ralph iterations
execution_context:
  last_updated: null
  tests_status: "unknown"  # passing | failing | unknown
  recent_learnings: []

# Shared memory across Ralph iterations (survives /clear)
scratchpad:
  blockers: []
  decisions: []
  warnings: []
  learnings: []

tasks:
  - id: "TASK-001-A"
    story_id: "AUTH-001"
    title: "Prisma User model"
    type: "implementation"  # ← NEW: test + code together
    estimated_minutes: 35   # ← test + code combined
    status: "pending"
    depends_on: []
    outputs:
      - "backend/prisma/schema.prisma"
      - "backend/src/features/user/user.test.ts"  # ← test file included
    acceptance:
      - "[RED] Write user.test.ts: User creation test (expect fail)"
      - "[GREEN] Add User model to schema.prisma"
      - "[GREEN] Run prisma generate"
      - "[GREEN] Test passes"
      - "[GATES] typecheck + lint + test pass"

    tdd_phases:  # ← NEW: explicit TDD workflow
      red:
        description: "Write FAILING test"
        tasks:
          - "Create user.test.ts"
          - "Write test: User.create() with valid data → expect User object"
        verify:
          command: "pnpm test"
          expected: "fail"  # Tests MUST fail
        max_duration_minutes: 15

      green:
        description: "Implement model"
        tasks:
          - "Add User model to schema.prisma"
          - "Run prisma generate"
        verify:
          command: "pnpm test"
          expected: "pass"  # ALL tests MUST pass
        max_duration_minutes: 20

      gates:
        description: "Quality gates MUST pass"
        required: true
        tasks:
          - "Run pnpm typecheck"
          - "Run pnpm lint"
          - "Run pnpm test"
        verify:
          - command: "pnpm typecheck"
            expected_exit_code: 0
          - command: "pnpm lint"
            expected_exit_code: 0
          - command: "pnpm test"
            expected_exit_code: 0

    retries: 0
    max_retries: 3
    receipt: null

  - id: "TASK-001-B"
    story_id: "AUTH-001"
    title: "Auth endpoints spec"
    type: "api"  # ← API tasks remain simple (no TDD phases)
    estimated_minutes: 20
    status: "pending"
    depends_on: ["TASK-001-A"]
    outputs:
      - "backend/src/openapi.yaml"
    acceptance:
      - "POST /api/v1/auth/telegram endpoint defined"
      - "Request schema with initData field"
      - "Response schema with user and token"
    retries: 0
    max_retries: 3
    receipt: null

  - id: "TASK-001-C"
    story_id: "AUTH-001"
    title: "Login service with validation"
    type: "implementation"  # ← NEW: combined test + code
    estimated_minutes: 65
    status: "pending"
    depends_on: ["TASK-001-A", "TASK-001-B"]
    outputs:
      - "backend/src/features/auth/login/auth.integration.test.ts"
      - "backend/src/features/auth/login/controller.ts"
      - "backend/src/features/auth/login/service.ts"
      - "backend/src/features/auth/login/dto.ts"
    acceptance:
      - "[RED] Write auth.integration.test.ts with 2 test cases"
      - "[RED] Run pnpm test → expect 2 FAILING tests"
      - "[GREEN] Implement login controller (Express route)"
      - "[GREEN] Implement login service (initData validation logic)"
      - "[GREEN] Implement LoginDto (Zod request/response schemas)"
      - "[GREEN] Run pnpm test → ALL PASS (2 new tests green)"
      - "[GATES] pnpm typecheck → exit 0 (no TS errors)"
      - "[GATES] pnpm lint → exit 0 (no lint errors)"
      - "[GATES] pnpm test → all pass (including new tests)"

    tdd_phases:
      red:
        description: "Write FAILING test(s)"
        tasks:
          - "Create auth.integration.test.ts"
          - "Test case 1: POST /auth/telegram with valid initData → expect 200"
          - "Test case 2: POST with invalid initData → expect 401"
        verify:
          command: "pnpm test"
          expected: "fail"
        max_duration_minutes: 20

      green:
        description: "Implement code to make tests pass"
        tasks:
          - "Implement controller.ts: Express route handler"
          - "Implement service.ts: initData validation logic"
          - "Implement dto.ts: Zod schemas for request/response"
        verify:
          command: "pnpm test"
          expected: "pass"
        max_duration_minutes: 40

      refactor:
        description: "Optional: Improve code quality"
        optional: true
        tasks:
          - "Extract validation helpers if needed"
          - "Improve naming"
        verify:
          command: "pnpm test"
          expected: "pass"
        max_duration_minutes: 10

      gates:
        description: "Quality gates MUST pass"
        required: true
        tasks:
          - "Run pnpm typecheck"
          - "Run pnpm lint"
          - "Run pnpm test"
        verify:
          - command: "pnpm typecheck"
            expected_exit_code: 0
          - command: "pnpm lint"
            expected_exit_code: 0
          - command: "pnpm test"
            expected_exit_code: 0

    retries: 0
    max_retries: 3
    receipt: null

  # ... continue for all tasks
```

### Step 7: Final Verification

```bash
# Verify file created
cat .bmad/task-queue.yaml | head -20

# Count tasks
yq '.tasks | length' .bmad/task-queue.yaml

# Show summary
yq '.summary' .bmad/task-queue.yaml
```

### Step 8: Create Ralph Progress Marker

**MANDATORY** — Create marker file for Ralph Loop auto-commit hook:

```bash
mkdir -p .bmad && echo "$(date -Iseconds)" > .bmad/ralph-in-progress
```

This enables:
- Auto-commit after each Edit/Write
- Context warnings specific to Ralph
- Resume prompt after /clear

---

## Output Summary

After running `/validate-sprint`, report:

```
## Validation Results

### Sprint Plan: docs/sprint-plan-sniper-bet-2026-01-17.md

Architecture exists: YES
INF-* stories found: NO ✅

### Sprint 1 Stories (extracted)
1. AUTH-001: TMA Authentication (5 pts)
2. DATA-001: Data Pipeline Integration (5 pts)
3. UI-001: Base UI Components (3 pts)

### Task Queue Generated

File: .bmad/task-queue.yaml
Stories: 3
Tasks: 27
Estimated hours: 18.5

### Ready for Ralph Loop ✅

Run: /ralph-loop
```

---

## Error Handling

### Error: INF-* Stories Found

```
❌ VALIDATION FAILED

Architecture exists but sprint plan contains infrastructure stories:
- INF-001: Project Setup
- INF-002: Database Schema

These stories are redundant - /architecture already created:
- backend/src/ (VSA skeleton)
- frontend/src/ (FSD skeleton)
- backend/prisma/schema.prisma

ACTION REQUIRED:
1. Delete current sprint plan
2. Re-run /bmad:sprint-planning
3. Start with BUSINESS features (Auth, Data Pipeline, etc.)
```

### Error: No Sprint Plan Found

```
❌ VALIDATION FAILED

No sprint plan found in docs/sprint-plan-*.md

ACTION REQUIRED:
Run /bmad:sprint-planning first
```

---

## Quick Reference

```bash
# Full workflow
/bmad:sprint-planning    # Create sprint plan
/validate-sprint         # Validate + generate task queue
/ralph-loop              # Execute tasks
```
