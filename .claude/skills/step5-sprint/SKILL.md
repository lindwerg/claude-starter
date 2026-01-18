---
name: step5-sprint
description: "Шаг 5: Планирование спринта. Используй: 'спринт', 'sprint', 'планирование', 'step5'"
allowed-tools: [Read, Write, Edit, Glob, TodoWrite, AskUserQuestion]
---

# Шаг 5: Планирование спринта

Разбивка PRD на конкретные задачи.

## Что это?

Sprint Planning — преобразование requirements в actionable tasks:
- Epics (большие блоки работы)
- Stories (user-facing фичи)
- Tasks (технические задачи)
- Acceptance criteria

## Когда использовать?

После `/step4-arch`, перед `/step6-validate`.

## Как запустить?

```bash
/step5-sprint
```

## Что получим?

Документ `docs/sprint-plan-{project}-{date}.md` с:

### 1. Epics
Большие блоки работы (1-2 недели):
```
EPIC-001: Система аутентификации
EPIC-002: Управление пользователями
EPIC-003: Dashboard
```

### 2. Stories
User-facing фичи (1-3 дня):
```
STORY-001: Регистрация пользователя
  Epic: EPIC-001
  Приоритет: P0
  Acceptance Criteria:
    - Given новый пользователь
    - When заполняет форму регистрации
    - Then создаётся аккаунт
```

### 3. Задачи по типам

| Тип | Описание | Агент |
|-----|----------|-------|
| `api` | OpenAPI endpoints | api-agent |
| `backend` | VSA slices | backend-agent |
| `frontend` | FSD components | frontend-agent |
| `test` | Tests | test-agent |
| `devops` | Infrastructure | devops-agent |

### 4. Зависимости
```
STORY-002 depends on STORY-001
TASK-003 depends on TASK-001, TASK-002
```

## Story Format

```yaml
id: STORY-001
title: Регистрация пользователя
type: frontend  # api | backend | frontend | test | devops
priority: P0    # P0 | P1 | P2
epic: EPIC-001
depends_on: []
acceptance_criteria:
  - Форма с полями email, password
  - Валидация на клиенте
  - Показ ошибок сервера
  - Редирект после успеха
```

## Следующий шаг

После планирования валидируй и генерируй очередь задач:

```
/step6-validate
```
