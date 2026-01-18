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
- 1 task = 30-60 minutes MAX
- 1 task = 1 file or 1 small change
- Clear outputs (file paths)
- Testable acceptance criteria

**Task Types:**
| Type | Description | Example |
|------|-------------|---------|
| `api` | OpenAPI spec changes | Add endpoint to openapi.yaml |
| `backend` | Controller/Service/Repository | Implement login service |
| `frontend` | Component/Hook/Page | Create AuthProvider |
| `test` | Unit/Integration/E2E | Write auth tests |
| `devops` | CI/CD/Docker | Update Dockerfile |

**Decomposition Pattern (example):**

```
Story: AUTH-001 "TMA Authentication" (5 points)
├── TASK-001-A: Add User model to Prisma (30min, backend)
├── TASK-001-B: Add auth endpoints to openapi.yaml (30min, api)
├── TASK-001-C: Implement initData validation (45min, backend)
├── TASK-001-D: Implement login controller (30min, backend)
├── TASK-001-E: Implement login service (45min, backend)
├── TASK-001-F: Implement JWT generation (30min, backend)
├── TASK-001-G: Create useAuth hook (30min, frontend)
├── TASK-001-H: Create AuthProvider (45min, frontend)
```

**TDD ORDER (Tests FIRST!):**
1. Write FAILING integration test
2. Schema/Models (Prisma)
3. API spec (OpenAPI)
4. Backend implementation → make tests GREEN
5. Write FAILING frontend test
6. Frontend implementation → make tests GREEN
7. E2E Playwright test LAST

**TDD Example:**
```
Story: AUTH-001 "TMA Authentication"
├── TASK-001-A: Write auth.integration.test.ts (FAILING) (test, 30min)
├── TASK-001-B: Add User model to Prisma (backend, 30min)
├── TASK-001-C: Add auth endpoints to openapi.yaml (api, 30min)
├── TASK-001-D: Implement login service (backend, 45min) ← GREEN
├── TASK-001-E: Write useAuth.test.ts (FAILING) (test, 20min)
├── TASK-001-F: Implement useAuth hook (frontend, 30min) ← GREEN
└── TASK-001-G: auth.e2e.spec.ts (e2e, 45min) ← Playwright
```

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
    title: "Add User model to Prisma"
    type: "backend"
    estimated_minutes: 30
    status: "pending"
    depends_on: []
    outputs:
      - "backend/prisma/schema.prisma"
    acceptance:
      - "User model with id, telegramId, username, createdAt"
      - "Unique constraint on telegramId"
    retries: 0
    max_retries: 3
    receipt: null  # Filled by Ralph after completion

  - id: "TASK-001-B"
    story_id: "AUTH-001"
    title: "Add auth endpoints to openapi.yaml"
    type: "api"
    estimated_minutes: 30
    status: "pending"
    depends_on: ["TASK-001-A"]
    outputs:
      - "backend/src/openapi.yaml"
    acceptance:
      - "POST /api/v1/auth/telegram endpoint defined"
      - "Request schema with initData field"
      - "Response schema with user and token"

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
