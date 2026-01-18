---
name: step4-arch
description: "Шаг 4: Архитектура системы. Используй: 'архитектура', 'architecture', 'дизайн системы', 'step4'"
allowed-tools: [Read, Write, Edit, Glob, TodoWrite, AskUserQuestion, Task]
---

# Шаг 4: Архитектура системы

Техническое проектирование на основе требований.

## Что это?

System Design — преобразование PRD в технические решения:
- Выбор технологий
- Структура компонентов
- API контракты
- Модели данных
- Инфраструктура

## Когда использовать?

После `/step3-prd`, перед `/step5-sprint`.

## Как запустить?

```bash
/step4-arch
```

## Что получим?

Документ `docs/architecture-{project}-{date}.md` с:

### 1. Обзор системы
- High-level диаграмма
- Ключевые компоненты
- Потоки данных

### 2. Frontend (FSD)
```
src/
├── app/          # Providers, routing
├── pages/        # Route pages
├── widgets/      # Complex UI blocks
├── features/     # Business features
├── entities/     # Business entities
└── shared/       # UI kit, hooks, api
```

### 3. Backend (VSA)
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

### 4. API Контракт
- OpenAPI 3.1 спецификация
- Endpoints с request/response schemas
- Error codes

### 5. Модель данных
- Prisma schema
- Связи между entities
- Индексы

### 6. Инфраструктура
- Docker services
- Environment variables
- CI/CD pipeline

## Принципы

- **FSD** для frontend (импорты только вниз)
- **VSA** для backend (vertical slices)
- **API-First** (OpenAPI как источник правды)
- **TypeScript strict** (no any, Zod validation)

## Следующий шаг

После архитектуры переходи к планированию спринта:

```
/step5-sprint
```
