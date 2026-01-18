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
/step1-init        # Создание структуры проекта
```

## 7 шагов разработки

| Шаг | Команда | Описание |
|-----|---------|----------|
| 1 | `/step1-init` | Создание структуры проекта |
| 2 | `/step2-brief` | Бизнес-анализ требований |
| 3 | `/step3-prd` | Документ требований (PRD) |
| 4 | `/step4-arch` | Техническая архитектура |
| 5 | `/step5-sprint` | Планирование спринта |
| 6 | `/step6-validate` | Валидация и очередь задач |
| 7 | `/step7-build` | Автономная разработка |

## Дополнительные команды

- `/help` — Справка
- `/commit` — Git commit (без Claude attribution)
- `/validate-all` — Полная валидация

## Advanced команды

- `/advanced:brainstorm` — Мозговой штурм
- `/advanced:research` — Исследование темы
- `/advanced:workflow-status` — Статус прогресса
