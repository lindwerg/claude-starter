---
name: advanced:create-story
description: "Создание user story. Используй: 'create story', 'новая история'"
allowed-tools: [Read, Write, Edit, AskUserQuestion]
---

# Создание User Story

Создание детальной user story.

## Что это?

Интерактивное создание story с:
- Описанием
- Acceptance criteria
- Техническими задачами

## Когда использовать?

- Добавляешь новую фичу после sprint planning
- Нужна детальная story

## Как запустить?

```bash
/advanced:create-story
```

## Формат

```yaml
id: STORY-XXX
title: Название story
type: frontend | backend | api | test
priority: P0 | P1 | P2
epic: EPIC-XXX
description: |
  Как [роль], я хочу [действие], чтобы [результат]
acceptance_criteria:
  - Given [предусловие]
  - When [действие]
  - Then [результат]
tasks:
  - TASK-001: Описание
  - TASK-002: Описание
```

## Результат

Story добавлена в sprint plan.
