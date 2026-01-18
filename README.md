# Claude Starter — Production-Ready Claude Code Fork

> **Comprehensive development framework** with autonomous task execution, quality enforcement, and multi-sprint support.

## 🎯 Ключевые возможности

- ✅ **Enforcement Over Instructions** — Хуки физически блокируют некорректные действия
- ⚡ **Ralph Loop** — Автономное выполнение до 100+ задач без вмешательства
- 🔒 **Quality Gates** — TypeScript, ESLint, тесты блокируют коммиты
- 🎯 **Multi-Sprint Automation** — Бесшовный переход между спринтами
- 🧪 **TDD Enforcement** — Test → Implementation порядок через depends_on
- 📊 **Full Traceability** — Архивы спринтов с reviews, quality reports, commits

---

## 📐 Архитектура

### Общая схема

```
BMAD Workflow (Planning)
    ↓
/validate-sprint (Декомпозиция stories → atomic tasks)
    ↓
task-queue.yaml (30-60 мин задачи с зависимостями)
    ↓
Ralph Loop (Автономное выполнение)
    ├─ Hooks (Enforcement слой)
    ├─ Subagents (Fresh context per task)
    ├─ Quality Gates (typecheck/lint/test)
    └─ Sprint Completion (Архивация, валидация, продолжение)
```

### Компоненты

| Компонент | Назначение | Ключевые файлы |
|-----------|------------|----------------|
| **Hooks** | Enforcement logic (block/continue) | `.claude/hooks/*.sh`, `.claude/hooks/src/*.ts` |
| **Ralph Loop** | Autonomous task executor | `.claude/skills/ralph-loop/SKILL.md` |
| **BMAD** | Project planning workflow | `.claude/skills/bmad/` |
| **Validate Sprint** | Task queue generator | `.claude/skills/validate-sprint/SKILL.md` |
| **Agents** | Fresh-context implementers | `.claude/agents/*-agent.md` |

---

## 🪝 Система хуков

### Hook Events

| Event | Timing | Use Case |
|-------|--------|----------|
| **PreToolUse** | Перед выполнением tool | Блокировка (gates, validation) |
| **PostToolUse** | После выполнения tool | Автодействия (format, commit, verify) |
| **SessionStart** | Начало сессии | Загрузка контекста (ledger, Ralph resume) |
| **Stop** | Завершение агента | Авто-продолжение, sprint completion |
| **PreCompact** | Перед compaction | Сохранение state |

### Критические хуки

#### 1. `backpressure-gate.sh` (PreToolUse Edit/Write)

**Назначение**: Блокирует редактирование если есть TypeScript/ESLint ошибки.

**Логика**:
```bash
# Активен только во время Ralph Loop
if [ ! -f ".bmad/ralph-in-progress" ]; then
  continue
fi

# Gate 1: TypeScript
if ! pnpm typecheck; then
  BLOCK "Fix typecheck errors first"
fi
```

**Философия**:
> "Don't prescribe how; create gates that reject bad work."

**Результат**: Ralph не может коммитить код с ошибками TypeScript.

#### 2. `subagent-enforcement.sh` (PreToolUse Edit/Write)

**Назначение**: Блокирует прямое редактирование `src/` без subagent.

**Логика**:
- **Whitelist** (Ralph может редактировать напрямую):
  - `.bmad/` — orchestration files
  - `.claude/` — hooks, configs
  - `*.md`, `*.yaml`, `*.json` — documentation, configs
  - `prisma/` — schema files
  - `openapi.yaml` — API spec

- **src/ файлы** требуют `.bmad/subagent-active` marker (< 5 мин старости)
- Если маркер отсутствует → **BLOCK** с инструкцией использовать Task tool

**Результат**: Ralph = orchestrator, subagent = implementer. **Fresh context per task**.

#### 3. `ralph-sprint-completion.sh` (Stop)

**Назначение**: Автоматическая архивация спринта и блокировка до validation.

**Workflow**:

```
Ralph завершает последнюю задачу спринта
        ↓
Stop Hook активируется
        ↓
1. Проверяет: все задачи status == "done"
2. Генерирует Sprint Review (stories, commits, learnings)
3. Запускает Quality Check (typecheck/lint/test/coverage)
4. Архивирует в .bmad/history/sprint-N/
5. Создаёт .bmad/sprint-validation-pending
6. Открывает браузер http://localhost:3000
7. БЛОКИРУЕТ с сообщением:
   "🏁 SPRINT N COMPLETED. Run /validate-sprint"
        ↓
🛑 Ralph ЗАБЛОКИРОВАН до user validation
```

**Результат**: Принудительная manual validation между спринтами.

#### 4. `ralph-validation-enforcer.sh` (PreToolUse Task)

**Назначение**: Блокирует запуск subagent пока пользователь не валидирует спринт.

**Логика**:
```bash
if [ -f ".bmad/sprint-validation-pending" ]; then
  BLOCK "⚠️ SPRINT VALIDATION REQUIRED. Run /validate-sprint"
fi
```

**Результат**: Ralph **физически не может** продолжить без user approval.

#### 5. `ralph-validation-cleanup.sh` (PostToolUse Write)

**Назначение**: Удаляет маркер валидации после создания `task-queue.yaml`.

**Триггер**: После записи `task-queue.yaml` (последний шаг `/validate-sprint`)

**Результат**: Ralph Loop автоматически разблокируется и продолжает работу.

### Полный список хуков

| Hook | Event | Файл | Назначение |
|------|-------|------|------------|
| backpressure-gate | PreToolUse Edit/Write | `.claude/hooks/backpressure-gate.sh` | Блокирует при TypeScript/Lint errors |
| subagent-enforcement | PreToolUse Edit/Write | `.claude/hooks/subagent-enforcement.sh` | Требует Task tool для src/ |
| sprint-plan-validator | PreToolUse Write | `.claude/hooks/sprint-plan-validator.sh` | Блокирует INF-* stories если architecture exists |
| ralph-validation-enforcer | PreToolUse Task | `.claude/hooks/ralph-validation-enforcer.sh` | Блокирует Task tool если pending validation |
| typescript-preflight | PostToolUse Edit/Write | `~/.claude/hooks/typescript-preflight.sh` | Валидация TypeScript после создания файла |
| auto-format | PostToolUse Write | `~/.claude/hooks/auto-format.sh` | Prettier форматирование |
| task-verification | PostToolUse Edit/Write | `.claude/hooks/task-verification.sh` | Автоверификация completion criteria |
| ralph-auto-commit | PostToolUse Edit/Write | `.claude/hooks/ralph-auto-commit.sh` | Автокоммит после каждой задачи |
| sprint-plan-post-validator | PostToolUse Write | `.claude/hooks/sprint-plan-post-validator.sh` | Напоминание создать task-queue.yaml |
| ralph-validation-cleanup | PostToolUse Write | `.claude/hooks/ralph-validation-cleanup.sh` | Удаляет маркер валидации |
| session-start-continuity | SessionStart resume/compact/clear | `~/.claude/hooks/session-start-continuity.sh` | Загрузка continuity ledger |
| session-start-ralph | SessionStart clear | `.claude/hooks/session-start-ralph.sh` | Prompt для resume Ralph Loop |
| pre-compact-save-state | PreCompact | `~/.claude/hooks/pre-compact-save-state.sh` | Сохранение state перед compaction |
| ralph-continue | Stop | `.claude/hooks/ralph-continue.sh` | Авто-продолжение если pending tasks |
| ralph-sprint-completion | Stop | `.claude/hooks/ralph-sprint-completion.sh` | Архивация спринта, блокировка |

### Версионирование Hooks

**Текущая версия**: 2.2.0

См. [`.claude/hooks/CHANGELOG.md`](./.claude/hooks/CHANGELOG.md) для истории изменений и миграционных инструкций.

**Последние улучшения (v2.2.0)**:
- 📊 **Monitoring**: Hook metrics tracking with analyze-metrics.sh
- 🔍 **Glob Support**: Full `**` pattern support via minimatch
- ✅ **Validation**: Zod schemas for type-safe inputs
- 📝 **Error Messages**: Context-rich errors with fix instructions

**v2.1.0 (Previous)**:
- ⚡ **Performance**: 4 hooks migrated to pre-compiled JavaScript (~10x faster)
- 🛡️ **Reliability**: Fixed race condition in `subagent-enforcement.sh` (UUID markers)
- ✅ **Testing**: Automated test suite (80%+ coverage)
- 📚 **Documentation**: Comprehensive README with best practices

### Тестирование Hooks

Критические hooks покрыты автоматическими тестами:

```bash
# Запуск всех тестов
bash .claude/hooks/tests/hooks/*.test.sh

# Конкретный hook
bash .claude/hooks/tests/hooks/subagent-enforcement.test.sh
```

**Пример вывода**:
```
=== Testing subagent-enforcement.sh ===

Suite 1: Ralph Loop Not Active
  Testing: Allow edit when Ralph not active... ✓ PASS

Suite 2: Ralph Active, Whitelisted Files
  Testing: Allow .bmad/ file edits... ✓ PASS
  Testing: Allow .claude/ file edits... ✓ PASS
  ...

Results: 15 passed, 0 failed
```

### Детальная документация

Полная документация по hooks системе:
- [`.claude/hooks/README.md`](./.claude/hooks/README.md) — Архитектура, best practices, development guide
- [`.claude/hooks/CHANGELOG.md`](./.claude/hooks/CHANGELOG.md) — Version history и breaking changes

---

## ⚡ Ralph Loop

### Концепция

**R**elentless **A**utonomous **L**oop for **P**roduct **H**acking

Ralph выполняет atomic tasks из `.bmad/task-queue.yaml` один за другим до завершения спринта или блокера.

### Core Loop

```
┌─────────────────────────────────────────────────────┐
│                  RALPH LOOP                         │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
        1. Load task-queue.yaml
                        │
                        ▼
        2. Find next pending task
           (depends_on all done)
                        │
                        ▼
        3. Update status → in_progress
                        │
                        ▼
        4. Spawn subagent via Task tool
           (backend-agent, frontend-agent, test-agent)
                        │
                        ▼
        5. Subagent creates .bmad/subagent-active
                        │
                        ▼
        6. Subagent implements
                        │
                        ▼
        7. Subagent removes .bmad/subagent-active
                        │
                        ▼
        8. Verify acceptance criteria
                        │
                        ▼
        9. QUALITY GATES (BACKPRESSURE) ←─┐
           ├─ pnpm typecheck (MUST PASS)   │
           ├─ pnpm lint (MUST PASS)        │
           └─ pnpm test (MUST PASS)        │
                        │                  │
                ┌───────┴───────┐          │
                │               │          │
                ▼               ▼          │
           ALL PASS        ANY FAIL        │
                │               │          │
                │               ▼          │
                │         Increment        │
                │          retries         │
                │               │          │
                │         ┌─────┴─────┐   │
                │         │           │   │
                │         ▼           ▼   │
                │     retries     retries │
                │       < 3        >= 3   │
                │         │           │   │
                │         ▼           │   │
                │      RETRY ─────────┘   │
                │                     │   │
                │                     ▼   │
                │             Adaptive    │
                │            Unblocking   │
                │                 │       │
                │         ┌───────┴──────┐│
                │         │              ││
                │         ▼              ▼│
                │     Success      Fail  │
                │         │              ││
                │         ▼              ▼│
                │    Unblock        BLOCKED
                │     task         (human)
                │         │
                ▼         ▼
         Update status → done
         Record receipt
         Auto-commit
                │
                ▼
         Move to next task
         (ralph-continue.sh)
                │
                ▼
        [ REPEAT until ALL DONE or BLOCKED ]
```

### Task Types → Agent Mapping

| Task Type | Subagent | Focus |
|-----------|----------|-------|
| `api` | api-agent | Update openapi.yaml, ensure spec validity |
| `backend` | backend-agent | VSA slice: controller, service, repository, dto |
| `frontend` | frontend-agent | FSD feature: UI, model, api hooks |
| `test` | test-agent | Unit/Integration tests, TDD |
| `e2e` | test-agent | Playwright E2E tests |
| `devops` | devops-agent | CI/CD, Docker, deploy configs |

### Quality Gates (BACKPRESSURE)

**Обязательны ПЕРЕД маркировкой задачи как `done`:**

```bash
# Gate 1: TypeScript (MUST PASS)
pnpm typecheck
# Empty output = SUCCESS (no errors to print)

# Gate 2: Lint (MUST PASS)
pnpm lint
# Exit code 0 = SUCCESS

# Gate 3: Tests (MUST PASS)
pnpm test
# All tests green = SUCCESS
```

**Если хотя бы один fail:**
- Task **НЕ МОЖЕТ** быть `done`
- Остаётся `in_progress`
- Increment `retries`
- Fix errors **НЕМЕДЛЕННО**

**Философия**:
> "Empty output ≠ failure. Check exit code."

**CRITICAL**: `tsc --noEmit` возвращает пустой output когда **НЕТ ОШИБОК** (это успех!). Не retry на пустом output.

### Adaptive Unblocking

**Проблема**: Task падает с 401 Unauthorized после 3 попыток.

**Решение**: Ralph автоматически создаёт **STORY-000: Basic JWT Auth** с 6 задачами:

```
TASK-000-A: Add /auth to openapi.yaml (api, 30min)
TASK-000-B: Implement JWT service (backend, 45min)
TASK-000-C: Create auth controllers (backend, 30min)
TASK-000-D: Add JWT middleware (backend, 30min)
TASK-000-E: Frontend auth hooks (frontend, 45min)
TASK-000-F: Auth integration tests (test, 30min)
```

**Workflow**:

```
Task fails with 401 (retry 3/3)
        ↓
Analyze blocker type: "missing_auth"
        ↓
Generate STORY-000 with 6 auth tasks
        ↓
Insert BEFORE blocked task
        ↓
Blocked task.depends_on = ["TASK-000-F"]
        ↓
Reset blocked task: status="pending", retries=0
        ↓
Ralph executes auth tasks
        ↓
Returns to blocked task → NOW PASSES ✅
```

**Supported blockers:**

| Blocker Type | Detection Signal | Auto-Resolution |
|--------------|------------------|-----------------|
| `missing_auth` | 401 Unauthorized, "authentication required" | Generate STORY-000 (JWT Auth) |
| `missing_dependency` | "cannot find module", "import not found" | Create `npm install` task |
| `schema_mismatch` | "column not found", Prisma errors | Create Prisma migration task |
| `missing_endpoint` | 404, "endpoint not found" | Create API endpoint task |

**Unknown blockers** → Mark as `blocked`, require human intervention.

---

## 🔄 Multi-Sprint Continuation

### Workflow

```
Sprint N → All tasks DONE
        ↓
Stop Hook: ralph-sprint-completion.sh
        ↓
1. Quality Check (typecheck/lint/test/coverage)
2. Archive to .bmad/history/sprint-N/
   ├─ task-queue.yaml
   ├─ sprint-review.md
   ├─ quality-report.json
   └─ commits.log
3. Create .bmad/sprint-validation-pending
4. Open browser http://localhost:3000
5. BLOCK Ralph with message:
   "🏁 SPRINT N COMPLETED. Run /validate-sprint"
        ↓
🛑 User validates manually in browser
        ↓
User: /validate-sprint
        ↓
validate-sprint:
  - Detects .bmad/sprint-validation-pending
  - Multi-sprint context: NEXT_SPRINT = N+1
  - Reads .bmad/history/sprint-N/ for context
  - Generates task-queue.yaml for Sprint N+1
        ↓
PostToolUse Hook: ralph-validation-cleanup.sh
  - Removes .bmad/sprint-validation-pending
        ↓
Stop Hook: ralph-continue.sh
  - Detects pending tasks → CONTINUE
        ↓
Sprint N+1 → Ralph resumes automatically
```

### Archived Sprint Structure

```
.bmad/history/sprint-1/
├── task-queue.yaml       # Original task queue with receipts
├── sprint-review.md      # Stories, commits, learnings
├── quality-report.json   # typecheck/lint/test/coverage results
└── commits.log           # Git commit hashes (SHA-1)
```

**Benefits**:

✅ **Full history preservation** — можно вернуться к любому спринту
✅ **Manual validation checkpoint** — пользователь тестирует перед продолжением
✅ **Zero context loss** — Ralph продолжает точно с места остановки
✅ **Enforcement** — Hooks блокируют переход без validation

---

## 📋 BMAD Workflow

### Full Pipeline

| Step | Command | Output | Notes |
|------|---------|--------|-------|
| 1 | `/init-project` | FSD/VSA structure | Creates backend/, frontend/, docs/ |
| 2 | `/workflow-init` | .bmad/ initialization | BMAD state tracking |
| 3 | `/product-brief` | Business requirements | User needs analysis |
| 4 | `/prd` (Level 2+) | Product Requirements Doc | Detailed specifications |
| 5 | `/architecture` (Level 2+) | backend/src/, frontend/src/, prisma/, docker-compose.yml | **MANDATORY for Level 2+** |
| 6 | `/sprint-planning` | docs/sprint-plan-*.md | Stories with acceptance criteria |
| 7 | `/validate-sprint` | .bmad/task-queue.yaml, .bmad/e2e-scenarios.yaml | **Ready for Ralph** |
| 8 | `/ralph-loop` | Autonomous execution | DONE or BLOCKED |

### Критические правила

**Level 2+ проекты** (5+ stories):
- `/architecture` **ОБЯЗАТЕЛЕН**
- После `/architecture` — **INF-* stories ЗАПРЕЩЕНЫ**
- `sprint-plan-validator.sh` блокирует создание infrastructure stories если архитектура уже есть

**Level 0-1 проекты** (1-4 stories):
- `/architecture` опциональен
- Можно использовать `/tech-spec` вместо `/prd`

---

## 🎯 Sprint Planning & Validation

### /validate-sprint Workflow

#### Step 0: Multi-Sprint Detection

```bash
# Проверка маркера валидации
ls .bmad/sprint-validation-pending

# Если существует:
#   → Continuation (NEXT_SPRINT = LAST_SPRINT + 1)
# Если нет:
#   → First sprint (NEXT_SPRINT = 1)
```

**Multi-Sprint Context**:
- Читает `.bmad/history/sprint-N/` для определения последнего спринта
- Генерирует task-queue.yaml для **Sprint N+1**

#### Step 1: Find Sprint Plan

```bash
ls docs/sprint-plan-*.md
```

#### Step 2: Check Architecture

```bash
ls backend/src frontend/src backend/prisma/schema.prisma
```

**Если ВСЕ существуют** → INF-* stories **FORBIDDEN**.

#### Step 3: Validate Stories

**Проверки:**
- [ ] NO INF-* stories (error if architecture exists!)
- [ ] NO "Infrastructure Stories" section
- [ ] First story is **BUSINESS FEATURE** (Auth, Data Pipeline, etc.)
- [ ] Stories have acceptance criteria
- [ ] Estimates are 3-8 points

**Если validation fails** → `/validate-sprint` блокируется с error message.

#### Step 4: Extract Stories for Target Sprint

Из sprint plan таблицы:
```markdown
| ID | Story | Points | Sprint |
|----|-------|--------|--------|
| AUTH-001 | TMA Authentication | 5 | 1 |
| DATA-001 | Data Pipeline | 5 | 1 |
```

Filter stories where `Sprint == NEXT_SPRINT`.

#### Step 5: Decompose Stories → Atomic Tasks

**Правила декомпозиции:**
- **1 task = 30-60 минут MAX**
- **1 task = 1 file** или 1 малое изменение
- **Чёткие outputs** (file paths)
- **Testable acceptance criteria**

**TDD ORDER (ENFORCED via depends_on):**

```
1. Write FAILING test (test task)
2. Schema/Models (backend task)
3. API spec (api task)
4. Backend implementation → GREEN (backend task)
5. Frontend test FAILING (test task)
6. Frontend implementation → GREEN (frontend task)
7. E2E Playwright test (e2e task) LAST
```

**Пример декомпозиции:**

```
Story: AUTH-001 "TMA Authentication" (5 pts)
│
├── TASK-001-A: Write auth.integration.test.ts FAILING (test, 30min)
│   outputs: backend/src/features/auth/auth.integration.test.ts
│   acceptance:
│     - Test file created
│     - pnpm test shows 1 FAILING test
│
├── TASK-001-B: Add User model to Prisma (backend, 30min)
│   depends_on: [TASK-001-A]
│   outputs: backend/prisma/schema.prisma
│
├── TASK-001-C: Add auth endpoints to openapi.yaml (api, 30min)
│   depends_on: [TASK-001-B]
│   outputs: backend/src/openapi.yaml
│
├── TASK-001-D: Implement login service (backend, 45min)
│   depends_on: [TASK-001-C]
│   outputs: backend/src/features/auth/login/service.ts
│   acceptance:
│     - AuthService validates initData
│     - pnpm test shows ALL PASSING ← GREEN!
│
├── TASK-001-E: Write useAuth.test.ts FAILING (test, 20min)
│   depends_on: [TASK-001-D]
│
├── TASK-001-F: Implement useAuth hook (frontend, 30min)
│   depends_on: [TASK-001-E]
│   acceptance:
│     - useAuth hook created
│     - pnpm test shows ALL PASSING ← GREEN!
│
└── TASK-001-G: auth.e2e.spec.ts (e2e, 45min)
    depends_on: [TASK-001-F]
    outputs: frontend/e2e/auth.spec.ts
    acceptance:
      - Playwright test for login flow
      - pnpm test:e2e passes
```

**Dependency graph ensures TDD!**

#### Step 6: Generate task-queue.yaml

**Ключевые поля:**

```yaml
version: "1.0"
project: "project-name"
sprint: 1  # или N+1 для multi-sprint
created_at: "2026-01-18T10:00:00Z"

summary:
  total_stories: 3
  total_tasks: 27
  estimated_hours: 18.5
  completed_tasks: 0
  blocked_tasks: 0

current_task: null

# BACKPRESSURE: Quality gates that MUST pass before task is done
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

# Execution context (для future Ralph iterations)
execution_context:
  last_updated: null
  tests_status: "unknown"  # passing | failing | unknown
  recent_learnings: []

# Shared memory (survives /clear)
scratchpad:
  blockers: []
  decisions: []
  warnings: []
  learnings: []

tasks:
  - id: "TASK-001-A"
    story_id: "AUTH-001"
    title: "Write auth.integration.test.ts FAILING"
    type: "test"
    estimated_minutes: 30
    status: "pending"
    depends_on: []
    outputs:
      - "backend/src/features/auth/auth.integration.test.ts"
    acceptance:
      - "Test file created"
      - "pnpm test shows 1 FAILING test"
    retries: 0
    max_retries: 3
    receipt: null  # Filled by Ralph after completion

  - id: "TASK-001-B"
    story_id: "AUTH-001"
    title: "Add User model to Prisma"
    type: "backend"
    estimated_minutes: 30
    status: "pending"
    depends_on: ["TASK-001-A"]
    outputs:
      - "backend/prisma/schema.prisma"
    acceptance:
      - "User model with id, telegramId, username, createdAt"
      - "Unique constraint on telegramId"

  # ... остальные задачи
```

#### Step 7: Generate e2e-scenarios.yaml (Автоматически!)

**Источник**: Acceptance criteria из stories.

**Механизм**: AI анализирует acceptance criteria и генерирует **декларативные Playwright сценарии**.

**Пример:**

**Acceptance criteria:**
```
- User can login with Telegram
- User sees dashboard after login
```

**Генерируется `.bmad/e2e-scenarios.yaml`:**
```yaml
version: "1.0"
scenarios:
  - id: "E2E-001"
    name: "User can login with Telegram"
    story_id: "AUTH-001"
    steps:
      - action: navigate
        url: "/login"
      - action: click
        selector: '[data-testid="telegram-login"]'
      - action: waitForNavigation
        url: "/dashboard"
      - action: expect
        selector: 'h1'
        text: "Dashboard"
        state: visible
```

**test-agent (type: e2e) превращает в Playwright:**
```typescript
import { test, expect } from '@playwright/test';

test('User can login with Telegram', async ({ page }) => {
  await page.goto('/login');
  await page.click('[data-testid="telegram-login"]');
  await page.waitForURL('/dashboard');
  await expect(page.locator('h1')).toHaveText('Dashboard');
});
```

**Результат**: **E2E тесты генерируются автоматически** из acceptance criteria при `/validate-sprint`.

---

## 🔧 Troubleshooting

### Ralph Loop stuck

**Symptom**: Задача остаётся `in_progress` бесконечно.

**Diagnose**:
```bash
# Текущая задача
cat .bmad/task-queue.yaml | yq '.current_task'

# Последние выполненные задачи
cat .bmad/ralph-execution-log.jsonl | tail -5

# Pending/Blocked tasks
yq '.tasks[] | select(.status == "in_progress" or .status == "blocked")' .bmad/task-queue.yaml
```

**Solutions**:

1. **Проверить gates**:
   ```bash
   pnpm typecheck  # TypeScript errors?
   pnpm lint       # ESLint errors?
   pnpm test       # Test failures?
   ```

2. **Если gates fail** → fix errors manually

3. **Reset task**:
   ```bash
   # Reset status to pending
   yq -i '(.tasks[] | select(.id == "TASK-001-C")).status = "pending"' .bmad/task-queue.yaml

   # Reset retries
   yq -i '(.tasks[] | select(.id == "TASK-001-C")).retries = 0' .bmad/task-queue.yaml
   ```

4. **Resume Ralph**:
   ```bash
   /ralph-loop --resume
   ```

---

### TypeScript errors при commit

**Symptom**: `backpressure-gate.sh` блокирует Edit/Write.

```
❌ BACKPRESSURE BLOCKED: TypeScript errors!

TS2741: Property 'foo' is missing in type 'Bar'

Fix typecheck errors before editing more files.
```

**Cause**: TypeScript compilation errors.

**Solution**:
```bash
# See full errors
pnpm typecheck

# Fix errors in affected files
# ...

# Ralph auto-continues after fix
```

---

### Sprint не архивируется

**Symptom**: Ralph завершается без архивации.

**Diagnose**:
```bash
# Проверить незавершённые задачи
cat .bmad/task-queue.yaml | yq '.tasks[] | select(.status != "done")'
```

**Причина**: Есть pending/in_progress/blocked задачи.

**Solution**:
- Завершить все задачи
- **ИЛИ** mark blocked tasks as done manually (если blocker resolved)

```bash
# Manually mark task as done
yq -i '(.tasks[] | select(.id == "TASK-005-D")).status = "done"' .bmad/task-queue.yaml
```

---

### E2E tests fail

**Symptom**: Playwright tests падают при `ralph-sprint-completion.sh`.

**Common causes**:
- Infrastructure не запущена (backend/frontend not running)
- Database не инициализирована
- Missing test data (40 images, dataset, etc.)

**Diagnose**:
```bash
# Check backend healthcheck
curl http://localhost:3001/health

# Check frontend healthcheck
curl http://localhost:3000

# Check Playwright report
npx playwright show-report
```

**Solution**:
- Запустить infrastructure: `docker compose up -d`
- Инициализировать DB: `pnpm prisma migrate dev`
- Подготовить test data (если требуется)

---

## 🐛 Проблемы и улучшения

### Problem 1: Data-Dependencies Not Detected

**Case Study**: Проект AI-генерации изображений девушек.

**Что упущено**: Система не создала задачу **"Prepare 40 training images for Lora"**.

**Root Cause**:
- Sprint-planning декомпозирует stories на **код** (backend/frontend/test)
- **НЕ анализирует** acceptance criteria на **data requirements**
- Acceptance: "Train Lora model" → AI создаёт task "Implement training endpoint"
- **НО пропускает** task "Prepare 40 images"

**Impact**:
- E2E test падает: `"Cannot upload images, uploader not found"`
- Приходится **менять task queue и спринты**
- Всё ломается, **потеря времени**

---

### ✅ Solution 1: Data Preparation Detector Hook

**Создать новый PreToolUse hook** для sprint-planning.

**Файл**: `.claude/hooks/data-preparation-detector.sh`

**Trigger**: PreToolUse Write на `sprint-plan-*.md`

**Логика**:

```bash
#!/bin/bash
set -e

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

# Only check sprint plans
if [[ "$FILE_PATH" != *"sprint-plan"* ]]; then
  echo '{"result":"continue"}'
  exit 0
fi

# Read file content (before write)
# Check if acceptance criteria mention data requirements
if grep -qE "\d+\s+(images|files|records|dataset|training data)" "$FILE_PATH"; then

  # Check if there's a corresponding data-preparation task
  if ! grep -qiE "prepare|upload|collect|dataset|training.*data" "$FILE_PATH"; then
    cat << 'EOF'
{"result":"block","message":"⚠️ DATA DEPENDENCY DETECTED\n\nAcceptance criteria mention data requirements (N images/files/records), but no data-preparation task found.\n\nREQUIRED ACTION:\nAdd story or task for data preparation:\n- 'Prepare 40 training images'\n- 'Upload dataset to storage'\n- 'Collect user records'\n\nWithout this, E2E tests will fail."}
EOF
    exit 0
  fi
fi

echo '{"result":"continue"}'
```

**Регистрация в `.claude/settings.json`:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/data-preparation-detector.sh"
          }
        ]
      }
    ]
  }
}
```

**Результат**:
1. Sprint-planning пытается написать план **без data-preparation task**
2. Hook **блокирует**
3. AI **вынужден** добавить story/task на подготовку данных
4. **E2E тесты проходят** ✅

---

### ✅ Solution 2: Enhanced E2E Validation

**Problem**: E2E scenarios генерируются из acceptance criteria, но AI может **пропустить критичные шаги**.

**Example**:
```yaml
# Acceptance:
- "User can train Lora model"

# AI может сгенерировать:
steps:
  - click: '[data-testid="train-button"]'  # БЕЗ проверки 40 images!
```

**Solution**: E2E Scenario Validator

**Файл**: `.claude/hooks/src/lib/e2e-scenario-validator.ts`

**Функция**: `validateE2EScenarios(scenarios, acceptanceCriteria)`

**Логика**:

```typescript
interface E2EScenario {
  id: string;
  name: string;
  story_id: string;
  steps: E2EStep[];
}

interface E2EStep {
  action: 'navigate' | 'click' | 'fill' | 'uploadFiles' | 'expect' | 'waitForNavigation';
  selector?: string;
  count?: number;
  // ... other fields
}

interface ValidationResult {
  valid: boolean;
  errors: string[];
}

function validateE2EScenarios(
  scenarios: E2EScenario[],
  acceptanceCriteria: string[]
): ValidationResult {

  const errors: string[] = [];

  for (const criterion of acceptanceCriteria) {
    // Extract data requirements
    const dataMatch = criterion.match(/(\d+)\s+(images|files|records)/i);

    if (dataMatch) {
      const [_, count, type] = dataMatch;

      // Check if scenario has upload/preparation step
      const hasUploadStep = scenarios.some(s =>
        s.steps.some(step =>
          step.action === 'uploadFiles' &&
          step.count !== undefined &&
          step.count >= parseInt(count)
        )
      );

      if (!hasUploadStep) {
        errors.push(
          `E2E missing for "${criterion}": No uploadFiles step for ${count} ${type}`
        );
      }
    }

    // Check for other critical patterns
    const authMatch = criterion.match(/login|authenticate|sign in/i);
    if (authMatch) {
      const hasAuthStep = scenarios.some(s =>
        s.steps.some(step => step.action === 'click' && step.selector?.includes('login'))
      );

      if (!hasAuthStep) {
        errors.push(`E2E missing for "${criterion}": No login/auth step`);
      }
    }

    // ... more validations
  }

  return {
    valid: errors.length === 0,
    errors
  };
}

export { validateE2EScenarios };
```

**Интеграция в validate-sprint**:

```typescript
// After generating e2e-scenarios.yaml
const scenarios = await loadE2EScenarios('.bmad/e2e-scenarios.yaml');
const acceptanceCriteria = extractAcceptanceCriteria(stories);

const validation = validateE2EScenarios(scenarios, acceptanceCriteria);

if (!validation.valid) {
  throw new Error(
    `❌ E2E validation failed:\n\n${validation.errors.join('\n')}`
  );
}
```

**Результат**:
- Если acceptance criteria = "Train with 40 images"
- Но E2E scenario не имеет `uploadFiles` step с `count: 40`
- `/validate-sprint` **БЛОКИРУЕТСЯ** с ошибкой
- AI **вынужден** добавить upload step в сценарий
- **E2E тесты проходят** ✅

---

### ⚡ Solution 3: Parallel Task Execution (Performance)

**Problem**: Задачи выполняются **последовательно**, даже если независимы.

**Example**:
```yaml
TASK-001-A: Backend endpoint (45min) → depends_on: []
TASK-001-E: Frontend hook (30min) → depends_on: [TASK-001-D]

# Frontend блокируется на 120 минут!
# Но TASK-001-A и TASK-001-E НЕЗАВИСИМЫ
```

**Solution**: Parallel Groups в task-queue.yaml

**Schema v2:**

```yaml
tasks:
  - id: "TASK-001-A"
    parallel_group: "group-1"
    # ... other fields

  - id: "TASK-001-E"
    parallel_group: "group-1"
    # ... other fields

parallel_groups:
  - group_id: "group-1"
    max_concurrent: 2
    tasks: ["TASK-001-A", "TASK-001-E"]
```

**Ralph Loop Execution:**

```typescript
// In Ralph Loop task picker
const nextTask = findNextPendingTask(tasks);

// Check if task is in parallel group
const group = parallelGroups.find(g => g.tasks.includes(nextTask.id));

if (group) {
  // Find all pending tasks in this group
  const groupTasks = tasks.filter(t =>
    group.tasks.includes(t.id) &&
    t.status === 'pending'
  );

  // Spawn multiple subagents in parallel
  const results = await Promise.all(
    groupTasks.slice(0, group.max_concurrent).map(task =>
      Task({
        subagent_type: getAgentType(task.type),
        description: `Execute ${task.id}`,
        prompt: buildTaskPrompt(task)
      })
    )
  );

  // Process results concurrently
  // ...
} else {
  // Single task execution (default)
  // ...
}
```

**Benefit**: Сокращение времени выполнения спринта на **30-50%**.

**Trade-off**: Увеличение сложности task queue generation.

---

## 🎓 Заключение

**Claude Starter** — это **полностью автоматизированная система разработки** с:

✅ **Real enforcement** (не instructions, а gates!)
✅ **Multi-sprint automation** (Sprint 1 → Sprint 2 → ... → Project Complete)
✅ **TDD by design** (test → implementation порядок через depends_on)
✅ **Full traceability** (архивы спринтов, execution logs, receipts)
✅ **Quality gates** (typecheck/lint/test БЛОКИРУЮТ bad work)
✅ **Fresh context per task** (no hallucinations!)

**С реализованными улучшениями:**

### ✅ Phase 1 (IMPLEMENTED)

🎉 **Data-preparation detector** — предотвращает пропуск data-зависимостей
  - Обнаруживает: "N images", "dataset", "training data"
  - Блокирует sprint-planning если нет preparatory tasks
  - Файл: `.claude/hooks/data-preparation-detector.sh`

🎉 **Infrastructure-readiness detector** — обнаруживает ЛЮБЫЕ infrastructure dependencies
  - Generic patterns: ComfyUI, FLUX, ffmpeg, S3 bucket, etc.
  - Работает для ЛЮБОГО проекта (AI, data, media, cloud)
  - Блокирует если нет preparatory tasks (PREP-*, SETUP-*, INF-*)
  - Файл: `.claude/hooks/infrastructure-readiness-detector.sh`

🎉 **Docker-first enforcer** — все dependencies ОБЯЗАТЕЛЬНО в Docker
  - Проверяет task-queue.yaml vs docker-compose.yml
  - Блокирует если сервис упомянут но не в Docker
  - No manual installation allowed
  - Файл: `.claude/hooks/docker-first-enforcer.sh`

🎉 **Readiness verification gate** — блокирует Ralph Loop если infrastructure не готова
  - Проверяет Docker services UP
  - Проверяет Python dependencies (workers/)
  - Проверяет models directory (ML projects)
  - Health checks (PostgreSQL, Redis, ComfyUI)
  - Файл: `.claude/hooks/readiness-verification-gate.sh`

🎉 **Local testability enforcer** — автоматическая проверка docker-compose.yml
  - Validates syntax после каждого изменения
  - Starts services (docker-compose up -d)
  - Health checks всех сервисов
  - Гарантирует что проект ВСЕГДА запускается локально
  - Файл: `.claude/hooks/local-testability-enforcer.sh`

### 🚧 Phase 2 (Planned)

🚀 **E2E scenario validator** — обеспечивает complete E2E coverage
🚀 **Parallel execution** — ускоряет спринты на 30-50%

---

### 🎯 Результат Phase 1

После реализации Phase 1 для **ЛЮБОГО проекта**:

✅ Sprint planning БЛОКИРУЕТСЯ если упомянут ComfyUI/FLUX/ffmpeg но нет preparatory tasks
✅ docker-compose.yml ОБЯЗАТЕЛЕН для всех external dependencies
✅ Ralph Loop НЕ МОЖЕТ запуститься если infrastructure не готова
✅ docker-compose up ВСЕГДА работает после каждого изменения

**Итог**: Пользователь ВСЕГДА может тестить проект локально. Нет ситуаций "код написан, но не работает".

---

## 📚 Дополнительные ресурсы

- **BMAD Method Documentation**: `.claude/skills/bmad/docs/`
- **Hook Development Guide**: `.claude/rules/hooks.md`
- **Agent Development Guide**: `.claude/agents/README.md`
- **Continuity Ledger Rules**: `.claude/rules/continuity.md`
- **FSD Architecture**: `.claude/rules/fsd-architecture.md`
- **VSA Architecture**: `.claude/rules/vsa-architecture.md`

---

## 🤝 Contributing

Contributions welcome! Основные области для улучшений:

### ✅ Completed
1. ~~**Data-preparation detector**~~ — IMPLEMENTED ✅
2. ~~**Infrastructure-readiness detector**~~ — IMPLEMENTED ✅
3. ~~**Docker-first enforcer**~~ — IMPLEMENTED ✅
4. ~~**Readiness verification gate**~~ — IMPLEMENTED ✅
5. ~~**Local testability enforcer**~~ — IMPLEMENTED ✅

### 🚧 In Progress / Planned
1. **E2E scenario validator** — расширение паттернов валидации для data requirements
2. **Parallel execution** — дизайн и реализация parallel groups в task-queue.yaml
3. **Adaptive unblocking** — поддержка новых blocker types (missing_model, missing_cli_tool)
4. **Quality gates** — добавление coverage threshold, security scans (SAST/DAST)
5. **Docker-compose auto-generation** — обновить /architecture skill для автогенерации docker-compose.yml

---

## 📝 License

MIT — see LICENSE file for details.

---

**Построено на Claude Code** — The best AI pair programmer.

**Версия**: 2.0.0
**Последнее обновление**: 2026-01-18
