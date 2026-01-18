---
name: help
description: "Справка Provide. Используй: 'help', 'помощь', 'справка', 'что делать'"
allowed-tools: [Read]
---

# Справка Provide Starter Kit

Автономная разработка full-stack приложений с Claude Code.

## Основные команды (по порядку)

| Шаг | Команда | Что делает |
|-----|---------|------------|
| 1 | `/step1-init` | Создаёт структуру проекта (FSD + VSA) |
| 2 | `/step2-brief` | Бизнес-анализ требований |
| 3 | `/step3-prd` | Документ требований (PRD) |
| 4 | `/step4-arch` | Проектирует архитектуру |
| 5 | `/step5-sprint` | Планирует спринт |
| 6 | `/step6-validate` | Валидирует и создаёт очередь задач |
| 7 | `/step7-build` | Автономно разрабатывает (Ralph Loop) |

## Быстрый старт

```bash
# 1. Создай папку проекта
mkdir my-app && cd my-app

# 2. Запусти Claude Code
claude

# 3. Выполни по порядку
/step1-init
/step2-brief
/step3-prd
/step4-arch
/step5-sprint
/step6-validate
/step7-build
```

## Дополнительные команды

| Команда | Описание |
|---------|----------|
| `/commit` | Commit изменений |
| `/validate-all` | Проверка VSA + FSD + тесты |

## Advanced команды

Расширенные инструменты для продвинутых пользователей:

| Команда | Описание |
|---------|----------|
| `/advanced:brainstorm` | Мозговой штурм идей |
| `/advanced:research` | Исследование темы |
| `/advanced:create-agent` | Создание нового агента |
| `/advanced:create-workflow` | Создание нового workflow |
| `/advanced:create-story` | Создание user story |
| `/advanced:create-ux-design` | UX дизайн интерфейса |
| `/advanced:dev-story` | Ручная реализация story |
| `/advanced:tech-spec` | Техническая спецификация |
| `/advanced:workflow-init` | Инициализация workflow |
| `/advanced:workflow-status` | Статус прогресса |
| `/advanced:solutioning-gate-check` | Проверка архитектуры |

## Архитектура

### Frontend (FSD)
```
src/
├── app/        # Providers, routing
├── pages/      # Route pages
├── widgets/    # Complex UI blocks
├── features/   # Business features
├── entities/   # Business entities
└── shared/     # UI kit, hooks, api
```

### Backend (VSA)
```
src/
├── features/
│   └── [feature]/
│       └── [slice]/
│           ├── controller.ts
│           ├── service.ts
│           ├── repository.ts
│           └── dto.ts
└── shared/
```

## Quality Gates

Каждая задача проходит проверки:

```bash
✅ pnpm typecheck    # Zero TS errors
✅ pnpm lint         # Zero ESLint warnings
✅ pnpm test         # All tests pass
```

## Полезные ссылки

- Документация: [GitHub Wiki]
- Issues: [GitHub Issues]
- FSD: https://feature-sliced.design
- VSA: Vertical Slice Architecture

## Получить помощь

Если что-то не работает:
1. Проверь статус: `/advanced:workflow-status`
2. Посмотри логи: `.bmad/task-queue.yaml`
3. Создай issue на GitHub
