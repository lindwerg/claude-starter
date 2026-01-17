# /init-project

Инициализация нового full-stack проекта с FSD (frontend) и VSA (backend) архитектурой.

## Описание

Создаёт полную структуру проекта с нуля, включая:
- Backend на Node.js/Express с VSA архитектурой
- Frontend на React/TypeScript с FSD архитектурой
- Docker конфигурацию
- CI/CD пайплайны
- Базовые конфигурации (ESLint, Prettier, TypeScript)

## Входные параметры

- `$PROJECT_NAME` — название проекта (kebab-case)
- `$DB_TYPE` — тип базы данных (postgres | mysql | sqlite), по умолчанию postgres

## Workflow

### 1. Создать Backend структуру (VSA)

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
├── tests/
├── package.json
└── tsconfig.json
```

### 2. Создать Frontend структуру (FSD)

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
│   │   │   └── client.ts     # API client (body: null, not undefined!)
│   │   └── types/
│   └── vite-env.d.ts         # ОБЯЗАТЕЛЬНО для import.meta.env
├── public/
├── package.json
├── tsconfig.json
├── vite.config.ts
└── tailwind.config.js
```

### 3. Скопировать templates

- `.editorconfig`
- `.prettierrc`
- `.eslintrc.js` (backend + frontend)
- `tsconfig.json` (strict mode)
- `.gitignore`

### 4. Установить dependencies

**Backend:**
```bash
pnpm add express zod prisma @prisma/client pino
pnpm add -D typescript @types/express @types/node vitest
```

**Frontend:**
```bash
pnpm add react react-dom @tanstack/react-query zustand
pnpm add -D typescript vite @vitejs/plugin-react tailwindcss
```

### 5. Инициализировать git

```bash
git init
git add .
git commit -m "chore: initial project setup"
```

### 6. Создать .env.example и .env

**ВАЖНО:** Использовать порт 5433 для PostgreSQL (5432 часто занят)!

```env
# Backend
NODE_ENV=development
PORT=3001
DATABASE_URL=postgresql://postgres:postgres@localhost:5433/myapp
CORS_ORIGIN=http://localhost:5173

# Frontend
VITE_API_URL=http://localhost:3001
```

После создания `.env.example` — **скопировать в `.env`**:
```bash
cp backend/.env.example backend/.env
```

### 6.1. Создать vite-env.d.ts (ОБЯЗАТЕЛЬНО!)

Файл `frontend/src/vite-env.d.ts`:
```typescript
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
```

### 6.2. API Client — правильная типизация body

В `frontend/src/shared/api/client.ts` для POST/PUT:
```typescript
// ПРАВИЛЬНО — используй null, не undefined
const body = data !== undefined ? JSON.stringify(data) : null;
```

### 7. Настроить Docker

- `docker-compose.yml` — dev окружение (db, redis)
- `backend/Dockerfile` — production image
- `frontend/Dockerfile` — production image (nginx)
- `.dockerignore`

## Output

После выполнения:
- Проект готов к разработке
- `pnpm dev` запускает оба сервера
- База данных настроена через Docker
- OpenAPI spec готов для первого endpoint

## Примеры использования

### Базовая инициализация
```
/init-project my-awesome-app
```

### С MySQL
```
/init-project my-app --db mysql
```

### С кастомным портом
```
/init-project my-app --port 8080
```

## Критерии успеха

- [ ] Все файлы созданы без ошибок
- [ ] `pnpm install` проходит успешно
- [ ] TypeScript компилируется без ошибок
- [ ] ESLint не показывает ошибок
- [ ] Docker Compose поднимается
- [ ] Health endpoint возвращает 200
