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

## PRE-FLIGHT: Проверка предыдущих документов

**BEFORE сбора параметров — убедись что документы созданы:**

### Шаг 1: Проверить Architecture

```bash
ls -t docs/architecture-*.md | head -1
```

**Если файл НЕ найден:**
```
❌ Architecture не найдена!

Сначала создай архитектуру:
/step4-arch
```
STOP — sprint planning требует архитектуру.

### Шаг 2: Проверить PRD

```bash
ls -t docs/prd-*.md | head -1
```

**Если файл НЕ найден:**
```
❌ PRD не найден!

Сначала создай requirements:
/step3-prd
```
STOP — sprint planning требует PRD.

**Примечание:** BMAD команда `sprint-planning` автоматически прочитает эти документы для извлечения epics, features, и requirements.

---

## Call BMAD Backend

Sprint planning в основном читает из PRD и Architecture документов. Нужно собрать только несколько уточняющих параметров.

### Шаг 1: Собери уточняющие параметры

**🚨 FIRST ACTION: Вызови AskUserQuestion tool СЕЙЧАС! 🚨**

НЕ выводи текст с вопросами. НЕ проси пользователя написать ответы. НЕМЕДЛЕННО вызови AskUserQuestion tool с этими 6 вопросами:

```
AskUserQuestion with questions:
  1. Team Velocity:
     question: "Сколько story points команда может выполнить за 2-недельный спринт?"
     header: "Velocity"
     options:
       - label: "15 SP (соло, 0.5 FTE)"
         description: "Один разработчик part-time"
       - label: "30 SP (соло, full-time)"
         description: "Один разработчик full-time"
       - label: "50 SP (команда 2-3)"
         description: "Небольшая команда"
       - label: "80+ SP (команда 4+)"
         description: "Полноценная команда"

  2. Sprint Duration:
     question: "Длительность спринта?"
     header: "Duration"
     options:
       - label: "1 неделя"
         description: "Быстрые итерации"
       - label: "2 недели (Recommended)"
         description: "Стандартный Scrum sprint"
       - label: "3 недели"
         description: "Для больших команд"

  3. Sprint Goal:
     question: "Цель первого спринта?"
     header: "Goal"
     options:
       - label: "MVP core functionality"
         description: "Базовые функции для первых пользователей"
       - label: "Infrastructure + auth"
         description: "Фундамент системы"
       - label: "Key feature complete"
         description: "Одна ключевая фича end-to-end"
       - label: "Production ready"
         description: "Готовность к деплою в prod"

  4. Priority Adjustments:
     question: "Нужны корректировки приоритетов epic?"
     header: "Priorities"
     options:
       - label: "Нет, всё хорошо"
         description: "Приоритеты из PRD подходят"
       - label: "Да, нужны изменения"
         description: "Опиши какие epic нужно поднять/опустить"

  5. External Dependencies:
     question: "Есть внешние зависимости или блокеры?"
     header: "Dependencies"
     options:
       - label: "Нет зависимостей"
         description: "Команда полностью автономна"
       - label: "Да, есть зависимости"
         description: "Опиши (API access, hardware, third-party, etc.)"

  6. Sprint Start Date:
     question: "Когда начнётся Sprint 1?"
     header: "Start Date"
     options:
       - label: "Сегодня"
         description: "Начинаем немедленно"
       - label: "Следующий понедельник"
         description: "Начало рабочей недели"
       - label: "Через 2 недели"
         description: "Нужна подготовка"
       - label: "Конкретная дата"
         description: "Укажи YYYY-MM-DD"
```

**После получения ответов через AskUserQuestion:**
- Сохрани ответы в переменные
- Если выбрано "Other" для любого вопроса, используй текст от пользователя
- Для Sprint Start Date: если "Конкретная дата" → попроси указать в формате YYYY-MM-DD

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

### Шаг 3: Вызови BMAD команду /sprint-planning

Теперь просто вызови Skill для генерации документа:

```bash
/sprint-planning
```

**Что происходит:**
1. Команда /sprint-planning проверяет существование `/tmp/step5-answers.yaml`
2. Находит файл → переходит в batch mode
3. Читает YAML напрямую через Read tool (все 6 переменных)
4. Читает Architecture и PRD документы для извлечения epics, features
5. Загружает template из `.claude/skills/bmad/bmad-v6/templates/sprint-plan.md`
6. Подставляет переменные в template
7. Генерирует `docs/sprint-plan-{project}-{date}.md`
8. Создаёт `docs/sprint-status.yaml` для Ralph tracking
9. Обновляет workflow status

**Преимущества:**
- ✅ YAML читается напрямую (не зависит от environment variables)
- ✅ Работает после /compact (YAML файл сохраняется)
- ✅ Простой и надёжный подход

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
