---
name: add-feature
description: |
  Add a new feature dynamically to existing sprint plan. Use this when:
  - User requests new feature outside current plan
  - Need to insert feature into active sprint
  - Feature should be automatically decomposed and queued
  Triggers: "добавить фичу", "новая фича", "add feature", "/add-feature"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, TodoWrite, AskUserQuestion
---

# Add Feature

Динамическое добавление фичи в существующий sprint plan с автоматической декомпозицией и обновлением документации.

## What It Does

1. **Context Loading** — Загружает sprint plan, architecture, task queue, git status
2. **Feature Analysis** — Определяет domain, type, complexity, impacts, dependencies
3. **Smart Positioning** — Автоматически выбирает epic, story ID, sprint, приоритет
4. **Task Decomposition** — Разбивает на атомарные задачи (30-90 мин)
5. **Document Updates** — Обновляет sprint-plan.md, task-queue.yaml, architecture.md
6. **Validation** — Проверяет корректность изменений
7. **Ralph Integration** — Новые задачи автоматически доступны для Ralph Loop

## Usage

```bash
# Basic usage
/add-feature "Добавить пагинацию к списку товаров"

# With context
/add-feature "Implement user profile editing with avatar upload"

# Complex feature
/add-feature "Add real-time notifications via WebSocket"
```

---

## Workflow

### Phase 0: Load Context

**Goal**: Загрузить все необходимые файлы для анализа.

```bash
# Find sprint plan
ls docs/sprint-plan-*.md 2>/dev/null | tail -1

# Check task queue
ls .bmad/task-queue.yaml 2>/dev/null

# Find architecture doc
ls docs/architecture-*.md 2>/dev/null | tail -1

# Check git status
git status --porcelain
```

**Load Files:**
- Sprint plan (docs/sprint-plan-*.md)
- Task queue (.bmad/task-queue.yaml)
- Architecture doc (docs/architecture-*.md)
- CLAUDE.md (root)

**Extract Data:**
- Current sprint number
- Existing stories (IDs, titles, epics)
- Existing tasks count
- Architectural pattern (FSD/VSA/Modular Monolith)
- Tech stack (backend/frontend frameworks)
- Entities from data model

**Error Handling:**
If any required file missing:
```
❌ CONTEXT LOADING FAILED

Missing required files:
- sprint-plan: [NOT FOUND|FOUND]
- task-queue: [NOT FOUND|FOUND]
- architecture: [NOT FOUND|FOUND]

ACTION REQUIRED:
Run the full BMAD workflow first:
/workflow-init → /product-brief → /prd → /architecture → /sprint-planning → /validate-sprint
```

---

### Phase 1: Feature Analysis

**Goal**: Понять что пользователь хочет добавить и как это вписывается в проект.

#### 1.1 Parse User Input

Extract key information from feature description:
- Core action (CRUD, integration, UI, etc.)
- Target entity/domain (User, Product, Order, etc.)
- Additional requirements (pagination, validation, auth, etc.)

#### 1.2 Domain Classification

Определи к какому domain относится фича:

| Domain Pattern | Examples | Indicators |
|----------------|----------|------------|
| **Authentication** | Login, Registration, Password Reset | auth, login, password, oauth, token |
| **User Management** | Profile, Settings, Permissions | user, profile, account, role, permission |
| **Data Management** | CRUD operations, Filters | list, create, update, delete, filter, search |
| **Integration** | External APIs, Webhooks | api, integration, webhook, external, third-party |
| **UI/UX** | Components, Layouts, Styles | ui, component, layout, style, design |
| **Notification** | Email, Push, In-app | notification, email, push, alert, message |
| **Payment** | Stripe, PayPal, Billing | payment, billing, checkout, invoice |

**Example:**
```
Input: "Добавить пагинацию к списку товаров"
→ Domain: Data Management
→ Entity: Product
→ Action: Pagination (UI pattern)
```

#### 1.3 Feature Type

Определи тип фичи:

| Type | Description | Layers Affected | Estimated Complexity |
|------|-------------|-----------------|---------------------|
| **api-only** | OpenAPI spec change | API spec | Low (20-30 min) |
| **backend** | Backend logic only | Controller/Service/Repository | Medium (60-120 min) |
| **frontend** | Frontend only | FSD layers | Medium (60-120 min) |
| **fullstack** | Backend + Frontend | All layers | High (120-240 min) |
| **integration** | External service | Backend + Config | High (90-180 min) |
| **infrastructure** | DevOps/Config | Docker/CI/DB | Medium (60-120 min) |

#### 1.4 Complexity Analysis

Оцени сложность по критериям:

**Low Complexity** (1-2 points):
- Простой CRUD endpoint
- UI component без state
- Добавление поля к существующей entity

**Medium Complexity** (3-5 points):
- CRUD с validation и business logic
- UI component с local state
- Новый feature slice

**High Complexity** (5-8 points):
- Complex business logic с transactions
- Интеграция с external API
- Новый epic со multiple stories

#### 1.5 Impact Analysis

Проанализируй что затронет фича:

**Code Impact:**
- Новые файлы (сколько, где)
- Изменения существующих файлов
- Новые зависимости (npm packages)

**Architecture Impact:**
- Новая entity в data model?
- Новый feature slice?
- Изменения API contract?

**Dependencies:**
- Зависит от существующих stories?
- Требует новых infrastructure changes?
- Блокирует другие features?

**Example Analysis:**
```
Feature: "Добавить пагинацию к списку товаров"

Domain: Data Management (Product)
Type: fullstack
Complexity: Medium (3 points)

Impact:
- Backend: Update GET /products endpoint (query params: page, limit)
- Frontend: Update ProductList widget (pagination controls)
- No new entities
- No new dependencies

Dependencies:
- Requires: PRODUCT-001 (Product CRUD) - DONE
- Blocks: None

Estimated Time: 90 minutes total
- API spec: 15 min
- Backend: 35 min (service + repository changes)
- Frontend: 30 min (UI pagination component)
- E2E test: 10 min
```

---

### Phase 2: Smart Positioning

**Goal**: Автоматически определить где разместить фичу в sprint plan.

#### 2.1 Epic Selection

Найди подходящий epic или создай новый:

**Rules:**
1. Если фича относится к существующему epic (по domain) → используй его
2. Если нет подходящего epic → создай новый

**Epic Naming Pattern:**
```
DOMAIN-001: [Domain Name]
Example: AUTH-001, PRODUCT-001, PAYMENT-001
```

**Example:**
```
Existing epics in sprint plan:
- AUTH-001: Authentication
- PRODUCT-001: Product Management
- UI-001: Base UI Components

Feature: "Добавить пагинацию к списку товаров"
→ Domain: Product (Data Management)
→ Epic: PRODUCT-001 ✅ (already exists)
```

**If creating new epic:**
```
Feature: "Добавить Stripe интеграцию"
→ Domain: Payment
→ Epic: PAYMENT-001 (NEW)
```

#### 2.2 Story ID Generation

Сгенерируй уникальный story ID:

**Pattern:** `{EPIC}-{SEQUENCE}`

**Algorithm:**
1. Найди все story IDs для выбранного epic
2. Возьми максимальный sequence number
3. Инкрементируй на 1

**Example:**
```
Existing stories in PRODUCT-001:
- PRODUCT-001: Basic Product CRUD (5 pts)
- PRODUCT-002: Product Filters (3 pts)

New story ID: PRODUCT-003 ✅
```

#### 2.3 Sprint Assignment

Определи в какой sprint добавить:

**Rules:**
1. **Если текущий sprint не запущен** (task-queue.yaml: completed_tasks = 0)
   → Добавь в текущий sprint

2. **Если текущий sprint в процессе** (completed_tasks > 0)
   → **ASK USER**: "Добавить в текущий Sprint N или в следующий Sprint N+1?"

3. **Если текущий sprint завершён** (.bmad/ralph-in-progress отсутствует)
   → Добавь в следующий sprint

**Example:**
```bash
# Check sprint status
COMPLETED=$(yq '.summary.completed_tasks' .bmad/task-queue.yaml)
TOTAL=$(yq '.summary.total_tasks' .bmad/task-queue.yaml)
CURRENT_SPRINT=$(yq '.sprint' .bmad/task-queue.yaml)

if [ "$COMPLETED" -eq 0 ]; then
  SPRINT=$CURRENT_SPRINT
elif [ "$COMPLETED" -lt "$TOTAL" ]; then
  # ASK USER via AskUserQuestion tool
  SPRINT=[user choice]
else
  SPRINT=$((CURRENT_SPRINT + 1))
fi
```

#### 2.4 Priority Assignment

Определи приоритет автоматически:

| Priority | When to Use | Example |
|----------|-------------|---------|
| **Critical** | Блокирует другие stories, security fix | Auth bypass fix |
| **High** | Ключевая бизнес-фича, dependencies для других | Payment integration |
| **Medium** | Обычная фича, улучшения | Pagination, filters |
| **Low** | Nice-to-have, косметика | UI tweaks, tooltips |

**Default:** Medium (если не указано иное)

#### 2.5 Story Point Estimation

Оцени story points на основе complexity:

| Complexity | Tasks Count | Story Points |
|------------|-------------|--------------|
| Low | 1-3 tasks | 1-2 points |
| Medium | 3-6 tasks | 3-5 points |
| High | 6-10 tasks | 5-8 points |

**Example:**
```
Feature: "Добавить пагинацию к списку товаров"
Complexity: Medium
Tasks: 4 (API spec, backend, frontend, E2E)
Story Points: 3 ✅
```

---

### Phase 3: Task Decomposition

**Goal**: Разбить фичу на атомарные задачи (30-90 мин каждая) с TDD workflow.

#### 3.1 Decomposition Strategy

**Standard Pattern (Fullstack Feature):**
```
1. API Spec (type: api)           → 15-30 min
2. Backend (type: implementation) → 60-90 min [RED → GREEN → GATES]
3. Frontend (type: implementation) → 60-90 min [RED → GREEN → GATES]
4. E2E Test (type: e2e)           → 30-45 min
```

**Backend-Only Pattern:**
```
1. API Spec (type: api)           → 15-30 min
2. Backend (type: implementation) → 60-90 min [RED → GREEN → GATES]
```

**Frontend-Only Pattern:**
```
1. Frontend (type: implementation) → 60-90 min [RED → GREEN → GATES]
2. E2E Test (type: e2e)           → 30-45 min
```

**Integration Pattern:**
```
1. API Spec (type: api)              → 20-30 min
2. Integration Service (type: implementation) → 90-120 min [RED → GREEN → GATES]
3. Config/Env (type: devops)         → 30 min
4. E2E Test (type: e2e)              → 45 min
```

#### 3.2 Task ID Generation

**Pattern:** `{STORY_ID}-{LETTER}`

**Example:**
```
Story: PRODUCT-003
Tasks:
- TASK-PRODUCT-003-A: API spec for pagination
- TASK-PRODUCT-003-B: Backend pagination implementation
- TASK-PRODUCT-003-C: Frontend pagination UI
- TASK-PRODUCT-003-D: E2E pagination test
```

#### 3.3 Generate Task Structure

Для каждой задачи создай полную структуру:

**API Task Template:**
```yaml
- id: "TASK-{STORY_ID}-A"
  story_id: "{STORY_ID}"
  title: "{Feature} API specification"
  type: "api"
  estimated_minutes: 20
  status: "pending"
  depends_on: []
  outputs:
    - "backend/src/openapi.yaml"
  acceptance:
    - "Add {METHOD} {PATH} endpoint to openapi.yaml"
    - "Define request schema with {params}"
    - "Define response schema with {fields}"
    - "Run openapi-cli lint → no errors"
  retries: 0
  max_retries: 3
  receipt: null
```

**Implementation Task Template (Parallel TDD):**
```yaml
- id: "TASK-{STORY_ID}-B"
  story_id: "{STORY_ID}"
  title: "{Feature} backend implementation"
  type: "implementation"
  estimated_minutes: 75
  status: "pending"
  depends_on: ["TASK-{STORY_ID}-A"]
  outputs:
    - "backend/src/features/{domain}/{slice}/{slice}.integration.test.ts"
    - "backend/src/features/{domain}/{slice}/controller.ts"
    - "backend/src/features/{domain}/{slice}/service.ts"
    - "backend/src/features/{domain}/{slice}/repository.ts"
    - "backend/src/features/{domain}/{slice}/dto.ts"
  acceptance:
    - "[RED] Write {slice}.integration.test.ts with {N} test cases"
    - "[RED] Run pnpm test → expect {N} FAILING tests"
    - "[GREEN] Implement controller.ts ({description})"
    - "[GREEN] Implement service.ts ({business logic})"
    - "[GREEN] Implement repository.ts ({data access})"
    - "[GREEN] Implement dto.ts (Zod schemas)"
    - "[GREEN] Run pnpm test → ALL PASS ({N} new tests green)"
    - "[GATES] pnpm typecheck → exit 0"
    - "[GATES] pnpm lint → exit 0"
    - "[GATES] pnpm test → all pass"

  tdd_phases:
    red:
      description: "Write FAILING test(s)"
      tasks:
        - "Create {slice}.integration.test.ts"
        - "Test case 1: {scenario} → expect {result}"
        - "Test case 2: {scenario} → expect {result}"
      verify:
        command: "pnpm test"
        expected: "fail"
      max_duration_minutes: 20

    green:
      description: "Implement code to make tests pass"
      tasks:
        - "Implement controller.ts: {description}"
        - "Implement service.ts: {description}"
        - "Implement repository.ts: {description}"
        - "Implement dto.ts: Zod schemas"
      verify:
        command: "pnpm test"
        expected: "pass"
      max_duration_minutes: 50

    refactor:
      description: "Optional: Improve code quality"
      optional: true
      tasks:
        - "Extract helpers if needed"
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
```

**E2E Task Template:**
```yaml
- id: "TASK-{STORY_ID}-D"
  story_id: "{STORY_ID}"
  title: "{Feature} E2E test"
  type: "e2e"
  estimated_minutes: 40
  status: "pending"
  depends_on: ["TASK-{STORY_ID}-C"]
  outputs:
    - "e2e/{feature}.e2e.spec.ts"
  acceptance:
    - "Write {feature}.e2e.spec.ts (Playwright)"
    - "Full user flow: {step 1} → {step 2} → {step 3}"
    - "E2E test passes"
  retries: 0
  max_retries: 3
  receipt: null
```

#### 3.4 Dependency Management

Определи dependencies между задачами:

**Rules:**
1. API spec всегда первая (depends_on: [])
2. Backend depends на API spec
3. Frontend depends на Backend (если есть API changes)
4. E2E depends на Frontend

**Example:**
```yaml
tasks:
  - id: "TASK-PRODUCT-003-A"
    depends_on: []  # API spec первая

  - id: "TASK-PRODUCT-003-B"
    depends_on: ["TASK-PRODUCT-003-A"]  # Backend после API

  - id: "TASK-PRODUCT-003-C"
    depends_on: ["TASK-PRODUCT-003-B"]  # Frontend после Backend

  - id: "TASK-PRODUCT-003-D"
    depends_on: ["TASK-PRODUCT-003-C"]  # E2E после Frontend
```

---

### Phase 4: Document Updates

**Goal**: Атомарно обновить sprint-plan.md, task-queue.yaml, architecture.md (если нужно).

#### 4.1 Update Sprint Plan

**File:** `docs/sprint-plan-*.md`

**Changes:**

1. **If new epic** → Add to "Sprint Epics" section:
```markdown
### {EPIC_ID}: {Epic Name}
**Domain:** {Domain}
**Priority:** {Priority}
**Description:** {Description}
```

2. **Add story to table:**
```markdown
| {STORY_ID} | {Story Title} | {Points} | {Sprint} | {Priority} | {Status} |
|------------|---------------|----------|----------|------------|----------|
| PRODUCT-003 | Product Pagination | 3 | 1 | Medium | Todo |
```

3. **Add detailed story description:**
```markdown
#### {STORY_ID}: {Story Title} ({Points} points)
**Epic:** {EPIC_ID}
**Priority:** {Priority}
**Dependencies:** {Dependency list or "None"}

**Description:**
{Feature description from analysis}

**Acceptance Criteria:**
- [ ] {Criterion 1}
- [ ] {Criterion 2}
- [ ] {Criterion 3}

**Technical Notes:**
- Backend: {Changes}
- Frontend: {Changes}
- Database: {Changes if any}
```

**Implementation:**
```bash
SPRINT_PLAN=$(ls docs/sprint-plan-*.md | tail -1)

# Add story to table (find table, insert before closing)
# Use Edit tool with old_string/new_string pattern
```

#### 4.2 Update Task Queue

**File:** `.bmad/task-queue.yaml`

**Changes:**

1. **Update summary:**
```yaml
summary:
  total_stories: {{current + 1}}
  total_tasks: {{current + new_tasks_count}}
  estimated_hours: {{recalculate}}
```

2. **Append tasks to tasks array:**
```yaml
tasks:
  # ... existing tasks ...

  # NEW TASKS FROM ADD-FEATURE
  - id: "TASK-PRODUCT-003-A"
    story_id: "PRODUCT-003"
    # ... full task structure ...
```

**Implementation:**
```bash
# Read current values
CURRENT_STORIES=$(yq '.summary.total_stories' .bmad/task-queue.yaml)
CURRENT_TASKS=$(yq '.summary.total_tasks' .bmad/task-queue.yaml)
CURRENT_HOURS=$(yq '.summary.estimated_hours' .bmad/task-queue.yaml)

# Calculate new values
NEW_STORIES=$((CURRENT_STORIES + 1))
NEW_TASKS=$((CURRENT_TASKS + ${#tasks[@]}))
NEW_MINUTES=$((sum of new task estimates))
NEW_HOURS=$(echo "scale=1; ($CURRENT_HOURS * 60 + $NEW_MINUTES) / 60" | bc)

# Update summary using yq
yq -i ".summary.total_stories = $NEW_STORIES" .bmad/task-queue.yaml
yq -i ".summary.total_tasks = $NEW_TASKS" .bmad/task-queue.yaml
yq -i ".summary.estimated_hours = $NEW_HOURS" .bmad/task-queue.yaml

# Append tasks (use yq to add to array)
for task in "${tasks[@]}"; do
  echo "$task" | yq -i '.tasks += [env(task)]' .bmad/task-queue.yaml
done
```

#### 4.3 Update Architecture (If Needed)

**File:** `docs/architecture-*.md`

**Only update if:**
- New entity added to data model
- New feature slice created
- New external integration

**Changes:**

1. **Data Model** (if new entity):
```markdown
## Data Model

### Core Entities

{N+1}. **{EntityName}**
   - Purpose: {Description}
   - Key Fields:
     - `id`: UUID primary key
     - `{field}`: {type} - {description}
   - Relationships:
     - {Relationship description}
```

2. **API Endpoints** (if new endpoints):
```markdown
### Endpoints

- {METHOD} `/api/v1/{path}` - {Description}
  - Request: {Schema}
  - Response: {Schema}
  - Auth: {Required/Optional}
```

**Implementation:**
```bash
ARCH_FILE=$(ls docs/architecture-*.md | tail -1)

# Use Edit tool to insert new entity/endpoint in appropriate section
```

#### 4.4 Atomic Update Strategy

**CRITICAL:** Обновляй файлы атомарно и безопасно.

**Order:**
1. Create backup copies (optional, for safety)
2. Update sprint-plan.md
3. Update task-queue.yaml
4. Update architecture.md (if needed)
5. Verify all changes

**Rollback Strategy:**
If any update fails:
```bash
# Git status shows uncommitted changes
git diff docs/sprint-plan-*.md
git diff .bmad/task-queue.yaml

# Manual rollback if needed
git checkout -- docs/sprint-plan-*.md
git checkout -- .bmad/task-queue.yaml
```

---

### Phase 5: Validation

**Goal**: Проверить что все изменения корректны.

#### 5.1 Validate Sprint Plan

```bash
SPRINT_PLAN=$(ls docs/sprint-plan-*.md | tail -1)

# Check story added
grep -q "$STORY_ID" "$SPRINT_PLAN" || echo "❌ Story not found in sprint plan"

# Check table format
grep "$STORY_ID.*|.*|.*|.*|" "$SPRINT_PLAN" || echo "❌ Story table row malformed"

# Check acceptance criteria
grep -A 5 "#### $STORY_ID" "$SPRINT_PLAN" | grep -q "Acceptance Criteria" || echo "❌ Acceptance criteria missing"
```

#### 5.2 Validate Task Queue

```bash
# Check tasks added
for task_id in "${task_ids[@]}"; do
  yq ".tasks[] | select(.id == \"$task_id\")" .bmad/task-queue.yaml > /dev/null || echo "❌ Task $task_id not found"
done

# Check summary updated
NEW_STORIES=$(yq '.summary.total_stories' .bmad/task-queue.yaml)
NEW_TASKS=$(yq '.summary.total_tasks' .bmad/task-queue.yaml)

echo "Summary updated:"
echo "  Stories: $NEW_STORIES"
echo "  Tasks: $NEW_TASKS"

# Validate YAML syntax
yq eval '.tasks' .bmad/task-queue.yaml > /dev/null || echo "❌ Invalid YAML syntax"
```

#### 5.3 Validate Task Dependencies

```bash
# Check all dependencies exist
for task in $(yq '.tasks[].id' .bmad/task-queue.yaml); do
  DEPS=$(yq ".tasks[] | select(.id == \"$task\") | .depends_on[]" .bmad/task-queue.yaml)

  for dep in $DEPS; do
    yq ".tasks[] | select(.id == \"$dep\")" .bmad/task-queue.yaml > /dev/null || echo "❌ Dependency $dep not found for task $task"
  done
done
```

#### 5.4 Validate TDD Phases

```bash
# Check implementation tasks have tdd_phases
for task in $(yq '.tasks[] | select(.type == "implementation") | .id' .bmad/task-queue.yaml); do
  yq ".tasks[] | select(.id == \"$task\") | .tdd_phases" .bmad/task-queue.yaml > /dev/null || echo "❌ Task $task missing tdd_phases"
done
```

---

## Integration with Ralph Loop

После успешного добавления фичи, новые задачи автоматически доступны для Ralph Loop.

**How it works:**
1. `/add-feature` обновляет `.bmad/task-queue.yaml`
2. Ralph Loop читает task queue и обнаруживает новые задачи
3. Ralph выполняет задачи в порядке dependencies

**User Action:**
```bash
# После /add-feature просто продолжи Ralph
/ralph-loop

# Ralph автоматически обнаружит новые задачи:
# "Обнаружено 4 новых задачи в очереди (TASK-PRODUCT-003-A...D)"
# "Начинаю выполнение следующей задачи: TASK-PRODUCT-003-A"
```

**No manual intervention needed!**

---

## Output Summary

После выполнения `/add-feature`, выведи summary:

```
## Feature Added: {Feature Title}

### Analysis
- **Domain:** {Domain}
- **Type:** {Type}
- **Complexity:** {Complexity} ({Points} points)
- **Epic:** {EPIC_ID} ({New/Existing})
- **Story ID:** {STORY_ID}
- **Sprint:** {Sprint Number}
- **Priority:** {Priority}

### Tasks Created ({N} tasks, {Total Minutes} minutes)
1. {TASK_ID_A}: {Title} (type: api, {X} min)
2. {TASK_ID_B}: {Title} (type: implementation, {Y} min)
3. {TASK_ID_C}: {Title} (type: implementation, {Z} min)
4. {TASK_ID_D}: {Title} (type: e2e, {W} min)

### Documents Updated ✅
- sprint-plan.md: Story added to Sprint {N}
- task-queue.yaml: {N} tasks appended (total: {Total})
- architecture.md: {Updated/Not modified}

### Dependencies
- **Requires:** {Dependencies or "None"}
- **Blocks:** {Blocked stories or "None"}

### Validation Results ✅
- Sprint plan format: OK
- Task queue YAML: Valid
- Task dependencies: Resolved
- TDD phases: Present

### Next Steps

**Option 1: Continue with Ralph Loop**
```bash
/ralph-loop
# Ralph will automatically pick up new tasks
```

**Option 2: Review changes first**
```bash
git diff docs/sprint-plan-*.md
git diff .bmad/task-queue.yaml
```

**Option 3: Add more features**
```bash
/add-feature "Another feature description"
```
```

---

## Error Handling

### Error: No Sprint Plan Found

```
❌ ADD-FEATURE FAILED

No sprint plan found in docs/sprint-plan-*.md

You must complete the initial BMAD workflow first:
1. /workflow-init
2. /product-brief
3. /prd
4. /architecture
5. /sprint-planning
6. /validate-sprint

Then you can add features dynamically.
```

### Error: No Task Queue Found

```
❌ ADD-FEATURE FAILED

No task queue found at .bmad/task-queue.yaml

ACTION REQUIRED:
Run /validate-sprint to generate task queue from sprint plan.
```

### Error: Sprint In Progress

```
⚠️  SPRINT IN PROGRESS

Current sprint status:
- Sprint: {N}
- Completed: {X}/{Y} tasks
- Ralph active: {Yes/No}

Where should I add the new feature?

OPTIONS:
1. Current Sprint {N} (will be executed soon)
2. Next Sprint {N+1} (after current sprint completes)

Please choose option 1 or 2.
```

**Handle user choice via AskUserQuestion tool.**

### Error: Ambiguous Feature Description

```
⚠️  FEATURE DESCRIPTION TOO VAGUE

I received: "{User input}"

I need more details to decompose this feature:

1. What entity/domain is affected? (User, Product, Order, etc.)
2. What action is needed? (Create, Update, Delete, List, etc.)
3. Any specific requirements? (Pagination, Validation, Auth, etc.)

Please provide a clearer description.

GOOD EXAMPLES:
- "Add pagination to product list"
- "Implement user profile editing with avatar upload"
- "Add Stripe payment integration for checkout"

BAD EXAMPLES:
- "Make it better"
- "Add feature"
- "Fix stuff"
```

### Error: File Update Failed

```
❌ DOCUMENT UPDATE FAILED

Failed to update: {filename}
Error: {error message}

Current state:
- sprint-plan.md: {Updated/Unchanged}
- task-queue.yaml: {Updated/Unchanged}
- architecture.md: {Updated/Unchanged}

ROLLBACK RECOMMENDED:
```bash
git status
git diff
git checkout -- {filename}
```

Please fix the issue and try again.
```

---

## Quick Reference

### Common Use Cases

```bash
# Add simple CRUD feature
/add-feature "Add user profile editing"

# Add UI feature
/add-feature "Create pagination component for product list"

# Add backend feature
/add-feature "Implement product search with filters"

# Add integration
/add-feature "Integrate Stripe for payments"

# Add fullstack feature
/add-feature "Add commenting system for blog posts"
```

### Feature Description Best Practices

**DO:**
- Be specific about entity/domain
- Mention key requirements (pagination, validation, etc.)
- Use clear action verbs (Add, Implement, Create, Integrate)

**DON'T:**
- Use vague descriptions ("improve", "fix", "make better")
- Omit the target entity ("add feature" instead of "add user profile")
- Include multiple unrelated features in one request

### File Paths Reference

```
docs/
├── sprint-plan-{project}-{date}.md  # Sprint stories
└── architecture-{project}-{date}.md  # System architecture

.bmad/
├── task-queue.yaml                   # Task queue for Ralph
└── ralph-in-progress                 # Ralph execution marker

backend/src/
├── openapi.yaml                      # API specification
└── features/                         # VSA slices

frontend/src/
└── {fsd-layers}/                     # FSD architecture
```

---

## Advanced Usage

### Adding Feature to Specific Epic

If user specifies epic explicitly:

```
User: "Добавить оплату через Stripe в PAYMENT-001 epic"
```

Skip epic selection in Phase 2, use specified epic directly.

### Adding Feature with Custom Story ID

If user wants specific ID:

```
User: "Create story AUTH-005 for OAuth integration"
```

Validate that ID doesn't exist, then use it directly.

### Adding Infrastructure Feature

For devops/infrastructure features:

```
User: "Add Redis caching layer"

→ Type: infrastructure
→ Epic: INF-001 (Infrastructure)
→ Tasks: Config + Docker + Integration
```

**Note:** Infrastructure features may not follow standard decomposition pattern.

---

## Checklist

Before marking task as DONE:

- [ ] All 5 phases completed (Context → Analysis → Positioning → Decomposition → Updates → Validation)
- [ ] sprint-plan.md updated with story
- [ ] task-queue.yaml updated with tasks
- [ ] architecture.md updated (if needed)
- [ ] All tasks have valid dependencies
- [ ] All implementation tasks have tdd_phases
- [ ] YAML syntax valid
- [ ] Summary output shown to user
- [ ] No uncommitted changes (or user aware of changes)
