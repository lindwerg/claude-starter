# Provide Starter Kit - Глобальные инструкции

> **Язык**: Всегда отвечай на русском.

## Основные принципы

1. **Architecture First** — FSD (frontend) + VSA (backend). Без исключений.
2. **Spec-Driven** — OpenAPI.yaml — единственный источник правды для API.
3. **Production-Ready** — TypeScript strict, тесты, error handling с первого дня.
4. **Inverted Pyramid** — 70% интеграционных, 20% unit, 10% E2E.

## Технологический стек

- **Frontend**: React 18+, TypeScript (strict), TanStack Query, Zustand, Tailwind CSS
- **Backend**: Node.js, Express/Fastify, Prisma, PostgreSQL, Zod validation
- **Инструменты**: pnpm, Vite, Docker, Vitest, Playwright

## FSD Архитектура (Frontend)

```
src/
├── app/          # Инициализация, providers, global styles
├── pages/        # Полные страницы (1 page = 1 route)
├── widgets/      # Независимые UI блоки со state
├── features/     # Бизнес-фичи (переиспользуемые)
├── entities/     # Бизнес-сущности (User, Product)
└── shared/       # Общий код (ui/, lib/, hooks/, api/, types/)
```

### Правила импортов FSD

```
МОЖНО:                      НЕЛЬЗЯ:
pages → всё ниже            features → features
widgets → features+ниже     entities → features/widgets/pages
features → entities+shared  shared → что-либо выше
entities → только shared
```

## VSA Архитектура (Backend)

```
src/
├── features/           # Vertical slices
│   └── [feature]/
│       └── [slice]/    # createUser, getUsers, etc.
│           ├── controller.ts
│           ├── service.ts
│           ├── repository.ts
│           ├── dto.ts (Zod)
│           └── index.ts
├── shared/             # middleware/, utils/, types/, config/
├── openapi.yaml        # API контракт (source of truth)
└── prisma/schema.prisma
```

## Правила качества кода

### Всегда

- Полная TypeScript типизация (no `any`, no `as unknown`)
- Тесты рядом с кодом (integration first)
- Error handling везде
- Zod валидация для всех inputs
- Обновлять openapi.yaml при изменении API

### Никогда

- Нарушать FSD/VSA архитектуру
- Пропускать null/undefined проверки
- Использовать `@ts-ignore` или `!` non-null assertion
- Хардкодить значения (magic numbers/strings)

## Быстрый старт

```bash
mkdir my-app && cd my-app
/init-project      # Создание структуры проекта
/workflow-init     # Инициализация BMAD
```

## Workflow разработки

### Основной процесс (BMAD Method)

| Шаг | Команда | Описание |
|-----|---------|----------|
| 1 | `/init-project` | Создание структуры проекта |
| 2 | `/workflow-init` | Инициализация BMAD |
| 3 | `/product-brief` | Бизнес-анализ требований |
| 4 | `/prd` | Документ требований (PRD) |
| 5 | `/architecture` | Техническая архитектура |
| 6 | `/sprint-planning` | Планирование спринта |
| 7 | `/validate-sprint` | Валидация и очередь задач |
| 8 | `/ralph-loop` | Автономная разработка |

## Дополнительные команды

### Разработка
- `/create-story` — Создать отдельную story
- `/dev-story` — Разработать одну story вручную
- `/tech-spec` — Техническая спецификация (для Level 0-1 проектов)

### Статус и валидация
- `/workflow-status` — Статус прогресса проекта
- `/validate-all` — Полная валидация архитектуры
- `/validate-sprint` — Валидация спринта + генерация task-queue

### Утилиты
- `/help` — Справка по командам
- `/commit` — Git commit (без Claude attribution)

### Advanced
- `/bmad:brainstorm` — Мозговой штурм
- `/bmad:research` — Исследование темы
- `/bmad:create-ux-design` — Создание UX дизайна
- `/bmad:solutioning-gate-check` — Проверка готовности к разработке
