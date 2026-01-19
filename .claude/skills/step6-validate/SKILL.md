---
name: step6-validate
description: "Шаг 6: Валидация и генерация задач. Используй: 'validate', 'валидация', 'queue', 'step6'"
allowed-tools: [Read, Write, Edit, Glob, Bash]
---

# Шаг 6: Валидация спринта

Проверка плана и генерация очереди задач.

## Что это?

Финальная проверка sprint plan перед автономной разработкой:
- Валидация структуры stories
- Проверка зависимостей
- Разбивка на atomic tasks
- Генерация `.bmad/task-queue.yaml`

## Когда использовать?

После `/step5-sprint`, перед `/step7-build`.

## Как запустить?

```bash
/step6-validate
```

## Что проверяется?

### 1. Структура Stories
- Каждая story имеет id, title, type, priority
- Acceptance criteria конкретные и тестируемые
- Нет дубликатов ID

### 2. Зависимости
- Нет циклических зависимостей
- Все referenced stories существуют
- P0 stories не зависят от P1/P2

### 3. Типы задач
- Все stories имеют валидный type
- Есть соответствующие агенты для каждого типа

## Что генерируется?

### `.bmad/task-queue.yaml`

```yaml
version: 1
sprint: sprint-1
generated: 2025-01-18T12:00:00Z

tasks:
  - id: TASK-001
    story: STORY-001
    type: api
    title: "OpenAPI endpoint для регистрации"
    status: pending
    depends_on: []
    acceptance_criteria:
      - POST /auth/register endpoint
      - Request/response schemas в openapi.yaml

  - id: TASK-002
    story: STORY-001
    type: backend
    title: "VSA slice для регистрации"
    status: pending
    depends_on: [TASK-001]
    acceptance_criteria:
      - controller.ts с валидацией
      - service.ts с бизнес-логикой
      - repository.ts с Prisma
```

### Quality Gates

Каждая задача проходит проверки:
```yaml
quality_gates:
  - pnpm typecheck    # Zero TS errors
  - pnpm lint         # Zero ESLint warnings
  - pnpm test         # All tests pass
```

## Ошибки валидации

| Ошибка | Решение |
|--------|---------|
| "Missing acceptance criteria" | Добавь конкретные критерии |
| "Circular dependency" | Пересмотри зависимости |
| "Unknown story type" | Используй: api, backend, frontend, test, devops |
| "P0 depends on P1" | Поменяй приоритеты |

---

## PRE-FLIGHT: Проверка предыдущих документов

**BEFORE валидации — убедись что документы созданы:**

### Шаг 1: Проверить Sprint Plan

```bash
ls -t docs/sprint-plan-*.md | head -1
```

**Если файл НЕ найден:**
```
❌ Sprint Plan не найден!

Сначала создай sprint plan:
/step5-sprint
```
STOP — валидация требует sprint plan.

### Шаг 2: Проверить Architecture (опционально)

```bash
ls -t docs/architecture-*.md | head -1
```

**Примечание:** Если Architecture существует, /validate-sprint запретит INF-* stories.

---

## Execution

### Шаг 1: Вызови BMAD команду /validate-sprint

**НЕМЕДЛЕННО вызови команду:**

```bash
/validate-sprint
```

**НЕТ параметров**, **НЕТ YAML файлов**, **НЕТ вопросов пользователю**.

/validate-sprint — fully autonomous command:
1. Находит sprint-plan.md
2. Валидирует stories (NO INF-* if architecture exists!)
3. Декомпозирует Sprint 1 stories на atomic tasks
4. Генерирует `.bmad/task-queue.yaml`
5. Генерирует `.bmad/sprint-status.yaml`
6. Обновляет workflow status

### Шаг 2: Проверь результат

После выполнения /validate-sprint проверь:

```bash
ls .bmad/task-queue.yaml .bmad/sprint-status.yaml
```

**Если файлы НЕ созданы:**
```
❌ Валидация провалилась!

Проверь ошибки в выводе /validate-sprint.
Возможно нужно исправить sprint-plan.md.
```

### Шаг 3: Сообщи пользователю

```
✓ Валидация завершена!

Документы:
- Task Queue: .bmad/task-queue.yaml (X tasks для Ralph)
- Sprint Status: .bmad/sprint-status.yaml

Следующий шаг:
/step7-build  # Запуск Ralph Loop
```

---

## Следующий шаг

После валидации запускай автономную разработку:

```
/step7-build
```
