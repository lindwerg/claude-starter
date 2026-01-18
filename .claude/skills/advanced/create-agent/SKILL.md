---
name: advanced:create-agent
description: "Создание нового агента. Используй: 'create agent', 'новый агент'"
allowed-tools: [Read, Write, Edit, Glob]
---

# Создание агента

Создание нового специализированного агента.

## Что это?

Scaffold для нового агента в `.claude/agents/`.

## Когда использовать?

- Нужен агент для специфичной задачи
- Существующие агенты не подходят

## Как запустить?

```bash
/advanced:create-agent "имя-агента"
```

## Структура агента

```markdown
# Agent Name

Role and responsibilities.

## Capabilities

- What this agent can do
- Tools it has access to

## Workflow

1. Step 1
2. Step 2

## Quality Gates

- Checks before completion
```

## Результат

Файл `.claude/agents/{name}-agent.md` готовый к использованию.
