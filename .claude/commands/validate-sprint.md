# /validate-sprint

Валидация sprint-plan и генерация task-queue.yaml для Ralph Loop.

## Описание

Запускается ПОСЛЕ `/bmad:sprint-planning`. Проверяет sprint-plan на корректность
и генерирует `.bmad/task-queue.yaml` с atomic tasks для автономной работы Ralph Loop.

**Workflow:**
```
/bmad:sprint-planning → /validate-sprint → /ralph-loop
```

## Что делает

1. **Валидирует sprint-plan** — проверяет на INF-* stories (запрещены если architecture exists)
2. **Генерирует task-queue** — декомпозирует stories в atomic tasks (30-60 min)
3. **Проверяет готовность** — убеждается что всё готово для Ralph Loop

## Workflow

### Step 1: Найти sprint-plan

```bash
ls docs/sprint-plan-*.md
```

Прочитать найденный файл.

### Step 2: Проверить architecture

```bash
ls backend/src frontend/src backend/prisma/schema.prisma
```

**Если ВСЕ существуют** → Architecture готова, INF-* stories ЗАПРЕЩЕНЫ.

### Step 3: Валидация stories

**Если architecture exists:**
- [ ] НЕТ INF-* stories (ошибка если найдены!)
- [ ] НЕТ "Infrastructure Stories" секции
- [ ] Первая story — БИЗНЕС-ФИЧА (Auth, Data Pipeline и т.д.)

**Всегда проверять:**
- [ ] Stories имеют acceptance criteria
- [ ] Оценки 3-8 points
- [ ] Dependencies логичны

**Если валидация провалена** → Сообщить ошибки и ОСТАНОВИТЬСЯ.

### Step 4: Query Context7 for Best Practices

**BEFORE декомпозиции stories — запроси актуальные best practices:**

1. **Agile task decomposition:**
   ```
   mcp__context7__resolve-library-id: "agile scrum"
   mcp__context7__query-docs: "user story decomposition into atomic tasks best practices"
   ```

2. **Technology-specific workflows** (из architecture):

   Для React/TypeScript projects:
   ```
   mcp__context7__resolve-library-id: "react"
   mcp__context7__query-docs: "React component development workflow step by step"

   mcp__context7__resolve-library-id: "prisma"
   mcp__context7__query-docs: "Prisma schema development and migration workflow"

   mcp__context7__resolve-library-id: "vitest"
   mcp__context7__query-docs: "Vitest integration testing workflow for API and components"
   ```

3. **Task estimation:**
   ```
   mcp__context7__query-docs: "software task estimation best practices for 30-60 minute tasks"
   ```

**Why:** Task decomposition должна соответствовать РЕАЛЬНОМУ dev workflow библиотек. Например:
- Prisma task: schema → migrate → generate → implement
- React component: interface → component → test → integration
- API endpoint: OpenAPI → controller → service → repository → test

**Include in task-queue:**
- Actual workflow steps from library docs
- Version-specific gotchas
- Dependency order validated against docs

### Step 5: Извлечь Sprint 1 stories

Из sprint-plan найти все stories назначенные на Sprint 1.

### Step 6: Декомпозировать в atomic tasks

Для КАЖДОЙ story в Sprint 1 создать atomic tasks:

**Правила декомпозиции:**
- 1 task = 30-60 минут MAX
- 1 task = 1 файл или 1 маленькое изменение
- Чёткие outputs (пути к файлам)
- Тестируемые acceptance criteria

**Типы tasks:**
| Type | Описание | Пример |
|------|----------|--------|
| `api` | Изменения OpenAPI | Добавить endpoint в openapi.yaml |
| `backend` | Controller/Service/Repository | Реализовать login service |
| `frontend` | Component/Hook/Page | Создать AuthProvider |
| `test` | Unit/Integration/E2E | Написать auth тесты |
| `devops` | CI/CD/Docker | Обновить Dockerfile |

**Порядок зависимостей:**
1. Schema/Models первыми (Prisma)
2. API spec (OpenAPI)
3. Backend (Controller → Service → Repository)
4. Frontend
5. Tests последними

### Step 7: Создать task-queue.yaml

Записать `.bmad/task-queue.yaml`:

```yaml
version: "1.0"
project: "{{project_name}}"
sprint: 1
created_at: "{{ISO date}}"

summary:
  total_stories: {{count}}
  total_tasks: {{count}}
  estimated_hours: {{hours}}
  completed_tasks: 0
  blocked_tasks: 0

current_task: null

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
      - "User model with id, telegramId, createdAt"
      - "Unique constraint on telegramId"
    retries: 0
    max_retries: 3
```

### Step 8: Финальная проверка

```bash
cat .bmad/task-queue.yaml | yq '.summary'
yq '.tasks | length' .bmad/task-queue.yaml
```

## Output

### Успех

```
## Validation Results

### Sprint Plan: docs/sprint-plan-sniper-bet-2026-01-17.md

Architecture exists: YES
INF-* stories found: NO ✅

### Sprint 1 Stories
1. AUTH-001: TMA Authentication (5 pts)
2. DATA-001: Data Pipeline (5 pts)

### Task Queue Generated

File: .bmad/task-queue.yaml
Stories: 2
Tasks: 18
Estimated hours: 12.5

### Ready for Ralph Loop ✅

Run: /ralph-loop
```

### Ошибка: INF-* stories найдены

```
❌ VALIDATION FAILED

Architecture exists но sprint-plan содержит infrastructure stories:
- INF-001: Project Setup
- INF-002: Database Schema

/architecture УЖЕ создал:
- backend/src/ (VSA skeleton)
- frontend/src/ (FSD skeleton)
- backend/prisma/schema.prisma

ТРЕБУЕТСЯ:
1. Удалить текущий sprint-plan
2. Перезапустить /bmad:sprint-planning
3. Начать с БИЗНЕС-ФИЧ (Auth, Data Pipeline)
```

## Примеры использования

```bash
# После sprint-planning
/bmad:sprint-planning
/validate-sprint

# Затем Ralph Loop
/ralph-loop
```
