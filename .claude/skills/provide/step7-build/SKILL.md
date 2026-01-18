---
name: step7-build
description: "Шаг 7: Автономная разработка. Используй: 'build', 'ralph', 'разработка', 'step7'"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, TodoWrite, Task]
---

# Шаг 7: Автономная разработка

Ralph Loop — автоматическая реализация задач.

## Что это?

Автономный цикл разработки, который:
- Читает задачи из `.bmad/task-queue.yaml`
- Маршрутизирует каждую задачу нужному агенту
- Проверяет качество (typecheck, lint, test)
- Автоматически коммитит после каждой задачи
- Обрабатывает ошибки и блокеры

## Когда использовать?

После `/step6-validate`, когда task-queue.yaml готов.

## Как запустить?

```bash
/step7-build
```

## Как работает?

```
for each task in queue:
  ├─ Выбор агента по типу задачи
  ├─ Выполнение задачи
  ├─ Quality Gates:
  │   ├─ pnpm typecheck
  │   ├─ pnpm lint
  │   └─ pnpm test
  ├─ Auto-commit
  └─ Следующая задача или BLOCKED
```

## Агенты

| Тип задачи | Агент | Что делает |
|------------|-------|------------|
| `api` | api-agent | Обновляет openapi.yaml |
| `backend` | backend-agent | Создаёт VSA slices |
| `frontend` | frontend-agent | Создаёт FSD components |
| `test` | test-agent | Пишет тесты (TDD) |
| `devops` | devops-agent | Docker, CI/CD |

## Quality Gates (Backpressure)

Задача НЕ завершается, пока:

```bash
✅ pnpm typecheck    # Zero TypeScript errors
✅ pnpm lint         # Zero ESLint warnings
✅ pnpm test         # All tests passing
```

Это enforced hooks, не просто инструкции.

## Статусы задач

| Статус | Значение |
|--------|----------|
| `pending` | Ожидает выполнения |
| `in_progress` | Выполняется |
| `completed` | Завершена успешно |
| `blocked` | Требует вмешательства |
| `skipped` | Пропущена (зависимость blocked) |

## При блокировке

Если задача blocked:
1. Читай `.bmad/task-queue.yaml` — там описание проблемы
2. Исправь вручную
3. Запусти `/step7-build` снова — продолжит с blocked задачи

## Прогресс

Следи за прогрессом:
```bash
cat .bmad/task-queue.yaml | grep status
```

## После завершения

Когда все задачи completed:
```bash
/commit  # Финальный коммит
```

## Команды управления

| Команда | Описание |
|---------|----------|
| `/step7-build` | Запуск/продолжение |
| `/step7-build --status` | Показать статус |
| `/step7-build --skip TASK-001` | Пропустить задачу |
| `/step7-build --retry TASK-001` | Повторить задачу |
