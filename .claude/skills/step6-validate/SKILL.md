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

## Следующий шаг

После валидации запускай автономную разработку:

```
/step7-build
```
