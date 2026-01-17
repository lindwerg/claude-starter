# /init-project

Инициализация нового full-stack проекта с FSD (frontend) и VSA (backend) архитектурой.

## Описание

Создаёт полную структуру проекта с нуля, включая:
- Backend на Node.js/Express с VSA архитектурой
- Frontend на React/TypeScript с FSD архитектурой
- Docker конфигурацию (PostgreSQL, Redis)
- MCP серверы (context7, playwright)
- Базовые конфигурации (TypeScript strict, Tailwind)

## Быстрый старт

Запусти скрипт автоматизации:

```bash
bash ~/.claude/scripts/init-project.sh [project-name]
```

**Что делает скрипт:**
1. Создаёт структуру проекта (FSD + VSA)
2. Создаёт `.mcp.json` с MCP серверами
3. Запускает Docker (PostgreSQL, Redis)
4. Ждёт healthcheck всех сервисов
5. Устанавливает dependencies (pnpm install)
6. Настраивает Prisma
7. Проверяет что backend работает
8. Инициализирует git

## Входные параметры

- `$PROJECT_NAME` — название проекта (по умолчанию: имя текущей папки)
- `--db postgres|mysql|sqlite` — тип базы данных (по умолчанию: postgres)
- `--postgres-port 5433` — порт PostgreSQL (по умолчанию: 5433)

## Структура проекта

### Backend (VSA)

```
backend/
├── src/
│   ├── features/           # Vertical slices
│   │   └── health/
│   │       ├── health.controller.ts
│   │       ├── health.service.ts
│   │       └── index.ts
│   ├── shared/
│   │   ├── middleware/
│   │   │   ├── error-handler.ts
│   │   │   └── validate.ts
│   │   ├── utils/
│   │   │   └── logger.ts
│   │   ├── types/
│   │   └── config/
│   │       └── env.ts
│   ├── openapi.yaml        # API контракт
│   └── app.ts
├── prisma/
│   └── schema.prisma
├── package.json
└── tsconfig.json
```

### Frontend (FSD)

```
frontend/
├── src/
│   ├── app/
│   │   ├── providers/
│   │   ├── styles/
│   │   └── index.tsx
│   ├── pages/
│   │   └── home/
│   ├── widgets/
│   ├── features/
│   ├── entities/
│   ├── shared/
│   │   ├── ui/
│   │   ├── lib/
│   │   ├── hooks/
│   │   ├── api/
│   │   │   └── client.ts
│   │   └── types/
│   └── vite-env.d.ts
├── public/
├── package.json
├── tsconfig.json
├── vite.config.ts
└── tailwind.config.js
```

## MCP серверы

Автоматически создаётся `.mcp.json`:

```json
{
  "mcpServers": {
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--caps=testing"]
    }
  }
}
```

После создания проекта запусти `/mcp` чтобы проверить подключение.

## Docker сервисы

- **PostgreSQL**: localhost:5433 (не 5432 — избегаем конфликтов)
- **Redis**: localhost:6380 (не 6379 — избегаем конфликтов)

## Важные детали

### vite-env.d.ts (ОБЯЗАТЕЛЬНО!)

Файл `frontend/src/vite-env.d.ts` критичен для TypeScript:

```typescript
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
```

### API Client — body: null, не undefined!

В `frontend/src/shared/api/client.ts`:

```typescript
// ПРАВИЛЬНО — используй null, не undefined
body: body !== undefined ? JSON.stringify(body) : null,
```

## Примеры использования

### В новой папке

```bash
mkdir my-app && cd my-app
bash ~/.claude/scripts/init-project.sh
```

### С именем проекта

```bash
mkdir my-app && cd my-app
bash ~/.claude/scripts/init-project.sh awesome-project
```

### С кастомным портом PostgreSQL

```bash
bash ~/.claude/scripts/init-project.sh --postgres-port 5434
```

## Команды после создания

```bash
pnpm dev              # Запустить оба сервера
pnpm dev:backend      # Только backend
pnpm dev:frontend     # Только frontend
pnpm db:studio        # Prisma Studio
pnpm generate-api-types  # Сгенерировать типы из OpenAPI
```

## Критерии успеха

- [ ] Все файлы созданы без ошибок
- [ ] Docker сервисы healthy (PostgreSQL, Redis)
- [ ] `pnpm install` проходит успешно
- [ ] TypeScript компилируется без ошибок
- [ ] Health endpoint возвращает 200
- [ ] `.mcp.json` создан и MCP серверы видны в `/mcp`

## Troubleshooting

### PostgreSQL не запускается

```bash
# Удалить старые volumes
docker compose down -v
docker compose up -d
```

### Порт занят

```bash
# Проверить что занимает порт
lsof -i :3001
lsof -i :5433

# Убить процесс
kill -9 <PID>
```

### MCP серверы не видны

1. Проверь что `.mcp.json` в корне проекта
2. Перезапусти Claude Code
3. Запусти `/mcp` для проверки
