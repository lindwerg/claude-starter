---
name: advanced:dev-story
description: "Реализация story. Используй: 'dev story', 'implement story'"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, TodoWrite, Task]
---

# Реализация Story

Пошаговая реализация конкретной user story.

## Что это?

Guided implementation одной story:
- Чтение acceptance criteria
- Создание файлов по архитектуре
- Написание тестов
- Проверка quality gates

## Когда использовать?

- Хочешь реализовать одну story вручную
- Ralph Loop заблокирован

## Как запустить?

```bash
/advanced:dev-story STORY-001
```

## Процесс

1. **Чтение** — загружает story из sprint plan
2. **Планирование** — разбивает на tasks
3. **TDD** — пишет failing tests
4. **Реализация** — код до green tests
5. **Валидация** — quality gates
6. **Commit** — фиксация изменений

## Quality Gates

```bash
pnpm typecheck  # TS errors = 0
pnpm lint       # ESLint warnings = 0
pnpm test       # All tests pass
```

## Результат

Story реализована, тесты проходят, код закоммичен.
