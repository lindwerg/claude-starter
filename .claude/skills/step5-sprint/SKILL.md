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

## Call BMAD Backend

Sprint planning в основном читает из PRD и Architecture документов. Нужно собрать только несколько уточняющих параметров.

### Шаг 1: Собери уточняющие параметры

Спроси пользователя:

1. **Team Velocity**: "Сколько story points команда может выполнить за 2-недельный спринт? (15-20 обычно)"
2. **Sprint Duration**: "Длительность спринта в неделях? (обычно 2 недели)"
3. **Sprint Goal**: "Цель первого спринта? (например, 'MVP с core chatbot functionality')"
4. **Priority Adjustments**: "Нужно изменить приоритеты каких-либо epic? (если нет, оставь пустым)"
5. **External Dependencies**: "Есть внешние зависимости? (например, 'Zendesk API sandbox access needed by Week 2')"
6. **Sprint Start Date**: "Когда начнётся Sprint 1? (YYYY-MM-DD)"

### Шаг 2: Создай YAML файл с ответами

Создай файл `/tmp/step5-answers.yaml`:

```yaml
# Metadata
collected_at: "{current_timestamp_ISO8601}"
collected_by: "step5-sprint"

# Sprint planning parameters (minimal - most data from PRD/Architecture)
team_velocity: "{ответ_story_points_per_sprint}"
sprint_duration: "{ответ_длительность_в_неделях}"
sprint_goal: "{ответ_цель_спринта}"
priority_adjustments: "{ответ_корректировки_или_пусто}"
dependencies_external: "{ответ_внешние_зависимости}"
sprint_start_date: "{ответ_дата_старта}"
```

**Используй Write tool для создания этого файла.**

### Шаг 3: Вызови variable-bridge.sh

```bash
bash ~/.claude/skills/bmad/bmad-v6/utils/variable-bridge.sh \
  sprint-planning \
  /tmp/step5-answers.yaml
```

**Что происходит:**
1. variable-bridge.sh загружает YAML
2. Экспортирует 6 переменных как BMAD_*
3. Устанавливает BMAD_BATCH_MODE=true
4. Вызывает команду /sprint-planning

**Результат:**
- Команда sprint-planning:
  - Загружает PRD (`docs/prd-*.md`)
  - Загружает Architecture (`docs/architecture-*.md`)
  - Извлекает epics, FRs, requirements
  - Разбивает epics на stories
  - Декомпозирует stories на atomic tasks
  - Использует BMAD_* переменные для team capacity и sprint goals
  - Генерирует `docs/sprint-plan-{project}-{date}.md`
  - **Создаёт `.bmad/task-queue.yaml` для Ralph Loop**
  - Обновляет `.bmad/sprint-status.yaml`
  - Обновляет workflow status

### Шаг 4: Сообщи пользователю

```
✓ Sprint Plan создан!

Документы:
- Sprint Plan: docs/sprint-plan-{project}-{date}.md
- Task Queue: .bmad/task-queue.yaml (для Ralph Loop)
- Sprint Status: .bmad/sprint-status.yaml

Summary:
- Sprint 1 Stories: {count}
- Sprint 1 Points: {points}
- Team Capacity: {capacity} points/sprint
- Tasks для Ralph: {task_count}

Следующий шаг: /step6-validate или /step7-build (Ralph Loop)
```

---

## Следующий шаг

После планирования валидируй и генерируй очередь задач:

```
/step6-validate
```
