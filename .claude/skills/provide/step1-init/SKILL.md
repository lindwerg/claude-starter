---
name: step1-init
description: "Шаг 1: Создание структуры проекта. Используй: 'новый проект', 'создай проект', 'step1', 'init'"
allowed-tools: [Bash, Read, Write, Glob]
---

# Шаг 1: Инициализация проекта

Создаёт полную структуру full-stack приложения с нуля.

## Что это?

Первый шаг разработки — scaffolding проекта с правильной архитектурой:
- **Backend**: VSA (Vertical Slice Architecture) + Express + Prisma
- **Frontend**: FSD (Feature-Sliced Design) + React + TanStack Query
- **Инфраструктура**: Docker Compose + PostgreSQL + Redis

## Когда использовать?

- Начинаешь новый проект с нуля
- Говоришь "создай проект", "новый проект", "init"

## Как запустить?

```bash
# Интерактивный режим (спросит имя проекта)
/step1-init

# С именем проекта
/step1-init my-app
```

## Что создаётся?

```
my-app/
├── backend/
│   ├── src/
│   │   ├── features/health/     # Health check endpoint
│   │   ├── shared/              # Middleware, utils, types
│   │   └── app.ts
│   ├── prisma/schema.prisma
│   └── package.json
├── frontend/
│   ├── src/
│   │   ├── app/                 # Providers, global styles
│   │   ├── pages/               # Route pages
│   │   ├── widgets/             # Complex UI blocks
│   │   ├── features/            # Business features
│   │   ├── entities/            # Business entities
│   │   └── shared/              # UI kit, hooks, api
│   └── package.json
├── docker-compose.yml
├── .mcp.json                    # MCP servers config
└── .env
```

## Опции

| Флаг | Описание |
|------|----------|
| `--no-docker` | Пропустить Docker setup |
| `--no-git` | Пропустить git init |
| `--no-deps` | Не устанавливать зависимости |

## После выполнения

1. Проверь Docker: `docker compose ps`
2. Запусти backend: `cd backend && pnpm dev`
3. Запусти frontend: `cd frontend && pnpm dev`
4. Health check: `curl http://localhost:3000/api/health`

## Следующий шаг

После создания структуры переходи к бизнес-анализу:

```
/step2-brief
```
