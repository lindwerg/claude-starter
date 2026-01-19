#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════════════════
# PROVIDE STARTER KIT - ПОЛНАЯ УСТАНОВКА
# ═══════════════════════════════════════════════════════════════════════════
#
# Одна команда делает ВСЁ:
#   mkdir my-app && cd my-app
#   curl -fsSL https://raw.githubusercontent.com/lindwerg/claude-starter/main/install.sh | bash
#
# Результат:
#   1. ~/.claude/ — skills, rules, hooks, agents (глобально)
#   2. Полный full-stack проект с работающими серверами
#   3. PostgreSQL + Redis запущены в Docker
#   4. Зависимости установлены, Prisma настроена
#   5. Backend и Frontend проверены и работают
#
# ═══════════════════════════════════════════════════════════════════════════

REPO_URL="https://github.com/lindwerg/claude-starter"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$HOME/.claude-backup-$(date +%Y%m%d%H%M%S)"
TEMP_DIR=""
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

# Default ports (will be overwritten if busy)
POSTGRES_PORT=5433
REDIS_PORT=6380
BACKEND_PORT=3001
FRONTEND_PORT=5173

# ═══════════════════════════════════════════════════════════════════════════
# FIND FREE PORT
# ═══════════════════════════════════════════════════════════════════════════

find_free_port() {
  local port=$1
  local max_port=$((port + 100))

  while [ $port -lt $max_port ]; do
    if ! lsof -i :$port >/dev/null 2>&1 && ! nc -z localhost $port 2>/dev/null; then
      echo $port
      return 0
    fi
    port=$((port + 1))
  done

  # Fallback to original port
  echo $1
}

assign_free_ports() {
  log_step "Поиск свободных портов..."

  POSTGRES_PORT=$(find_free_port 5433)
  REDIS_PORT=$(find_free_port 6380)
  BACKEND_PORT=$(find_free_port 3001)
  FRONTEND_PORT=$(find_free_port 5173)

  log_info "PostgreSQL: $POSTGRES_PORT"
  log_info "Redis: $REDIS_PORT"
  log_info "Backend: $BACKEND_PORT"
  log_info "Frontend: $FRONTEND_PORT"
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_step() { echo -e "${BLUE}[→]${NC} $1"; }

# ═══════════════════════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════════════════════

print_banner() {
  echo ""
  echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║                                                               ║${NC}"
  echo -e "${CYAN}║   ${BOLD}${GREEN}PROVIDE STARTER KIT${NC}${CYAN}                                        ║${NC}"
  echo -e "${CYAN}║   ${NC}Автономная разработка full-stack приложений${CYAN}                ║${NC}"
  echo -e "${CYAN}║                                                               ║${NC}"
  echo -e "${CYAN}║   ${NC}Проект: ${GREEN}${PROJECT_NAME}${NC}${CYAN}                                          ${NC}"
  echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# 1. PREREQUISITES
# ═══════════════════════════════════════════════════════════════════════════

check_prerequisites() {
  log_step "Проверяю зависимости..."

  local missing=0

  # Node.js
  if ! command -v node &> /dev/null; then
    log_error "Node.js не найден"
    echo "    → Установи: https://nodejs.org/ (версия 18+)"
    missing=1
  else
    local node_version=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$node_version" -lt 18 ]; then
      log_error "Node.js версия < 18"
      missing=1
    else
      log_info "Node.js $(node --version)"
    fi
  fi

  # Git
  if ! command -v git &> /dev/null; then
    log_error "Git не найден"
    missing=1
  else
    log_info "Git $(git --version | cut -d' ' -f3)"
  fi

  # pnpm
  if ! command -v pnpm &> /dev/null; then
    log_warn "pnpm не найден — устанавливаю..."
    npm install -g pnpm 2>/dev/null || { log_error "Не удалось установить pnpm"; missing=1; }
    command -v pnpm &> /dev/null && log_info "pnpm установлен"
  else
    log_info "pnpm $(pnpm --version)"
  fi

  # Docker
  if ! command -v docker &> /dev/null; then
    log_warn "Docker не найден — БД нужно будет поднять вручную"
  else
    if docker info &>/dev/null; then
      log_info "Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
    else
      log_warn "Docker не запущен — запусти Docker Desktop"
    fi
  fi

  # jq
  if ! command -v jq &> /dev/null; then
    log_warn "jq не найден — settings будут заменены"
  fi

  # Claude Code
  if ! command -v claude &> /dev/null; then
    log_warn "Claude Code не найден"
    echo "    → Установи: npm install -g @anthropic-ai/claude-code"
  else
    log_info "Claude Code найден"
  fi

  if [ $missing -eq 1 ]; then
    echo ""
    log_error "Установка прервана. Установи недостающие зависимости."
    exit 1
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 2. BACKUP & CLONE
# ═══════════════════════════════════════════════════════════════════════════

backup_existing() {
  if [ -d "$CLAUDE_DIR" ]; then
    log_step "Сохраняю backup ~/.claude..."
    cp -r "$CLAUDE_DIR" "$BACKUP_DIR"
    log_info "Backup создан: $BACKUP_DIR"
  fi
}

clone_repo() {
  log_step "Скачиваю Provide Starter Kit..."
  TEMP_DIR=$(mktemp -d)

  if git clone --depth 1 --recurse-submodules "$REPO_URL" "$TEMP_DIR/claude-starter" 2>/dev/null; then
    log_info "Репозиторий загружен"
  else
    log_error "Не удалось скачать репозиторий"
    exit 1
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 3. INSTALL CLAUDE CONFIG (GLOBAL - minimal base config)
# ═══════════════════════════════════════════════════════════════════════════

install_claude_config() {
  log_step "Устанавливаю базовую конфигурацию Claude Code (~/.claude)..."

  # Install only minimal global config (rules + base settings)
  mkdir -p "$CLAUDE_DIR/rules"

  # Copy rules (shared across all projects)
  local src="$TEMP_DIR/claude-starter/.claude/rules"
  if [ -d "$src" ] && [ "$(ls -A "$src" 2>/dev/null)" ]; then
    cp -r "$src/"* "$CLAUDE_DIR/rules/" 2>/dev/null || true
  fi

  # Make scripts executable
  chmod +x "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true
  chmod +x "$CLAUDE_DIR/scripts/"*.sh 2>/dev/null || true
  chmod +x "$CLAUDE_DIR/orchestrator/ralph" 2>/dev/null || true

  # Templates
  if [ -d "$TEMP_DIR/claude-starter/templates" ]; then
    cp -r "$TEMP_DIR/claude-starter/templates/"* "$CLAUDE_DIR/templates/" 2>/dev/null || true
  fi

  # Settings.json
  local src_settings="$TEMP_DIR/claude-starter/.claude/settings.json"
  local dst_settings="$CLAUDE_DIR/settings.json"
  if [ -f "$src_settings" ]; then
    if command -v jq &> /dev/null && [ -f "$dst_settings" ]; then
      jq -s 'reduce .[] as $item ({}; . * $item)' "$src_settings" "$dst_settings" > "$CLAUDE_DIR/settings.merged.json"
      mv "$CLAUDE_DIR/settings.merged.json" "$dst_settings"
    else
      cp "$src_settings" "$dst_settings"
    fi
  fi

  # MCP config
  local src_mcp="$TEMP_DIR/claude-starter/.claude/mcp_config.json"
  local dst_mcp="$CLAUDE_DIR/mcp_config.json"
  if [ -f "$src_mcp" ]; then
    if command -v jq &> /dev/null && [ -f "$dst_mcp" ]; then
      jq -s '.[0].mcpServers as $src | .[1].mcpServers as $dst | {mcpServers: ($src + $dst)}' "$src_mcp" "$dst_mcp" > "$CLAUDE_DIR/mcp.merged.json"
      mv "$CLAUDE_DIR/mcp.merged.json" "$dst_mcp"
    else
      cp "$src_mcp" "$dst_mcp"
    fi
  fi

  # CLAUDE.md
  if [ -f "$TEMP_DIR/claude-starter/CLAUDE.md" ] && [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    cp "$TEMP_DIR/claude-starter/CLAUDE.md" "$CLAUDE_DIR/"
  fi

  log_info "Skills, rules, hooks, agents установлены"
}

# ═══════════════════════════════════════════════════════════════════════════
# 4. CREATE PROJECT STRUCTURE (MONOREPO)
# ═══════════════════════════════════════════════════════════════════════════

create_project_structure() {
  log_step "Создаю структуру full-stack проекта..."

  # Backend (VSA)
  mkdir -p "$PROJECT_DIR/backend/src/features/health"
  mkdir -p "$PROJECT_DIR/backend/src/shared/middleware"
  mkdir -p "$PROJECT_DIR/backend/src/shared/utils"
  mkdir -p "$PROJECT_DIR/backend/src/shared/config"
  mkdir -p "$PROJECT_DIR/backend/src/shared/types"
  mkdir -p "$PROJECT_DIR/backend/prisma"

  # Frontend (FSD)
  mkdir -p "$PROJECT_DIR/frontend/src/app/providers"
  mkdir -p "$PROJECT_DIR/frontend/src/app/styles"
  mkdir -p "$PROJECT_DIR/frontend/src/pages/home/ui"
  mkdir -p "$PROJECT_DIR/frontend/src/widgets"
  mkdir -p "$PROJECT_DIR/frontend/src/features"
  mkdir -p "$PROJECT_DIR/frontend/src/entities"
  mkdir -p "$PROJECT_DIR/frontend/src/shared/ui"
  mkdir -p "$PROJECT_DIR/frontend/src/shared/lib"
  mkdir -p "$PROJECT_DIR/frontend/src/shared/hooks"
  mkdir -p "$PROJECT_DIR/frontend/src/shared/api"
  mkdir -p "$PROJECT_DIR/frontend/src/shared/types"
  mkdir -p "$PROJECT_DIR/frontend/public"

  # Other
  mkdir -p "$PROJECT_DIR/docs"
  mkdir -p "$PROJECT_DIR/.bmad"
  mkdir -p "$PROJECT_DIR/.claude/hooks"

  log_info "Структура каталогов создана"
}

# ═══════════════════════════════════════════════════════════════════════════
# 5. CREATE CONFIG FILES
# ═══════════════════════════════════════════════════════════════════════════

create_config_files() {
  log_step "Создаю конфигурационные файлы..."

  # ─────────────────────────────────────────────────────────────────────────
  # Root package.json (Monorepo)
  # ─────────────────────────────────────────────────────────────────────────
  cat > "$PROJECT_DIR/package.json" << EOF
{
  "name": "${PROJECT_NAME}",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "concurrently \"pnpm --filter backend dev\" \"pnpm --filter frontend dev\"",
    "dev:backend": "pnpm --filter backend dev",
    "dev:frontend": "pnpm --filter frontend dev",
    "build": "pnpm -r build",
    "lint": "pnpm -r lint",
    "test": "pnpm -r test",
    "typecheck": "pnpm -r typecheck",
    "db:generate": "pnpm --filter backend db:generate",
    "db:push": "pnpm --filter backend db:push",
    "db:migrate": "pnpm --filter backend db:migrate",
    "db:studio": "pnpm --filter backend db:studio",
    "generate-api-types": "openapi-typescript backend/src/openapi.yaml -o frontend/src/shared/api/types.ts"
  },
  "devDependencies": {
    "concurrently": "^9.1.2",
    "openapi-typescript": "^7.5.2"
  },
  "engines": {
    "node": ">=18"
  }
}
EOF

  # pnpm-workspace.yaml
  cat > "$PROJECT_DIR/pnpm-workspace.yaml" << 'EOF'
packages:
  - 'backend'
  - 'frontend'
EOF

  # ─────────────────────────────────────────────────────────────────────────
  # Backend package.json
  # ─────────────────────────────────────────────────────────────────────────
  cat > "$PROJECT_DIR/backend/package.json" << EOF
{
  "name": "${PROJECT_NAME}-backend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/app.ts",
    "build": "tsc",
    "start": "node dist/app.js",
    "typecheck": "tsc --noEmit",
    "lint": "eslint src",
    "test": "vitest",
    "db:generate": "prisma generate",
    "db:push": "prisma db push",
    "db:migrate": "prisma migrate dev",
    "db:studio": "prisma studio"
  },
  "dependencies": {
    "@prisma/client": "^6.2.1",
    "cors": "^2.8.5",
    "express": "^4.22.1",
    "helmet": "^8.0.0",
    "pino": "^9.6.0",
    "pino-pretty": "^13.0.0",
    "zod": "^3.24.1"
  },
  "devDependencies": {
    "@eslint/js": "^9.18.0",
    "@types/cors": "^2.8.17",
    "@types/express": "^5.0.0",
    "@types/node": "^22.10.7",
    "eslint": "^9.18.0",
    "prisma": "^6.2.1",
    "tsx": "^4.19.2",
    "typescript": "^5.7.3",
    "typescript-eslint": "^8.22.0",
    "vitest": "^3.0.4"
  }
}
EOF

  # Backend tsconfig.json
  cat > "$PROJECT_DIR/backend/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

  # Backend vitest.config.ts
  cat > "$PROJECT_DIR/backend/vitest.config.ts" << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['**/*.test.ts', '**/*.spec.ts'],
  },
});
EOF

  # ─────────────────────────────────────────────────────────────────────────
  # Frontend package.json
  # ─────────────────────────────────────────────────────────────────────────
  cat > "$PROJECT_DIR/frontend/package.json" << EOF
{
  "name": "${PROJECT_NAME}-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "typecheck": "tsc --noEmit",
    "lint": "eslint src",
    "test": "vitest"
  },
  "dependencies": {
    "@tanstack/react-query": "^5.64.1",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "zustand": "^5.0.3"
  },
  "devDependencies": {
    "@eslint/js": "^9.18.0",
    "@testing-library/jest-dom": "^6.6.3",
    "@testing-library/react": "^16.2.0",
    "@types/react": "^18.3.18",
    "@types/react-dom": "^18.3.5",
    "@vitejs/plugin-react": "^4.3.4",
    "autoprefixer": "^10.4.20",
    "eslint": "^9.18.0",
    "eslint-plugin-react": "^7.37.4",
    "eslint-plugin-react-hooks": "^5.1.0",
    "jsdom": "^26.0.0",
    "postcss": "^8.5.1",
    "tailwindcss": "^3.4.17",
    "typescript": "^5.7.3",
    "typescript-eslint": "^8.22.0",
    "vite": "^6.0.7",
    "vitest": "^3.0.4"
  }
}
EOF

  # Frontend tsconfig.json
  cat > "$PROJECT_DIR/frontend/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

  cat > "$PROJECT_DIR/frontend/tsconfig.node.json" << 'EOF'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true,
    "strict": true
  },
  "include": ["vite.config.ts"]
}
EOF

  # ─────────────────────────────────────────────────────────────────────────
  # Docker Compose
  # ─────────────────────────────────────────────────────────────────────────
  cat > "$PROJECT_DIR/docker-compose.yml" << EOF
services:
  postgres:
    image: postgres:16-alpine
    container_name: ${PROJECT_NAME}-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ${PROJECT_NAME}
    ports:
      - '${POSTGRES_PORT}:5432'
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 5s
      timeout: 5s
      retries: 10

  redis:
    image: redis:7-alpine
    container_name: ${PROJECT_NAME}-redis
    restart: unless-stopped
    ports:
      - '${REDIS_PORT}:6379'
    volumes:
      - redis_data:/data
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 5s
      timeout: 5s
      retries: 10

volumes:
  postgres_data:
  redis_data:
EOF

  # ─────────────────────────────────────────────────────────────────────────
  # .mcp.json
  # ─────────────────────────────────────────────────────────────────────────
  cat > "$PROJECT_DIR/.mcp.json" << 'EOF'
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
EOF

  # ─────────────────────────────────────────────────────────────────────────
  # .gitignore
  # ─────────────────────────────────────────────────────────────────────────
  cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Dependencies
node_modules/
.pnpm-store/

# Build
dist/
build/

# Environment
.env
.env.local
.env.*.local

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store

# Logs
*.log

# Testing
coverage/

# BMAD state
.bmad/ralph-in-progress
.bmad/subagent-active
.bmad/sprint-validation-pending
EOF

  # ─────────────────────────────────────────────────────────────────────────
  # Environment files
  # ─────────────────────────────────────────────────────────────────────────
  cat > "$PROJECT_DIR/backend/.env" << EOF
NODE_ENV=development
PORT=${BACKEND_PORT}
DATABASE_URL=postgresql://postgres:postgres@localhost:${POSTGRES_PORT}/${PROJECT_NAME}
CORS_ORIGIN=http://localhost:${FRONTEND_PORT}
EOF

  cp "$PROJECT_DIR/backend/.env" "$PROJECT_DIR/backend/.env.example"

  cat > "$PROJECT_DIR/frontend/.env" << EOF
VITE_API_URL=http://localhost:${BACKEND_PORT}
EOF

  cp "$PROJECT_DIR/frontend/.env" "$PROJECT_DIR/frontend/.env.example"

  log_info "Конфигурационные файлы созданы"
}

# ═══════════════════════════════════════════════════════════════════════════
# 6. CREATE BACKEND FILES
# ═══════════════════════════════════════════════════════════════════════════

create_backend_files() {
  log_step "Создаю backend файлы..."

  # app.ts
  cat > "$PROJECT_DIR/backend/src/app.ts" << 'EOF'
import express, { type Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { env } from './shared/config/env.js';
import { logger } from './shared/utils/logger.js';
import { errorHandler } from './shared/middleware/error-handler.js';
import { healthRouter } from './features/health/index.js';

const app: Express = express();

// Security middleware
app.use(helmet());
app.use(cors({ origin: env.CORS_ORIGIN, credentials: true }));

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/health', healthRouter);

// Error handling
app.use(errorHandler);

// Start server
app.listen(env.PORT, () => {
  logger.info(`Server running on http://localhost:${env.PORT}`);
  logger.info(`Environment: ${env.NODE_ENV}`);
});

export { app };
EOF

  # env.ts
  cat > "$PROJECT_DIR/backend/src/shared/config/env.ts" << EOF
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(${BACKEND_PORT}),
  DATABASE_URL: z.string().default('postgresql://postgres:postgres@localhost:${POSTGRES_PORT}/${PROJECT_NAME}'),
  CORS_ORIGIN: z.string().default('http://localhost:${FRONTEND_PORT}'),
});

export const env = envSchema.parse(process.env);
EOF

  # logger.ts
  cat > "$PROJECT_DIR/backend/src/shared/utils/logger.ts" << 'EOF'
import pino from 'pino';
import { env } from '../config/env.js';

export const logger = pino({
  level: env.NODE_ENV === 'production' ? 'info' : 'debug',
  ...(env.NODE_ENV === 'development' && {
    transport: {
      target: 'pino-pretty',
      options: { colorize: true, translateTime: 'SYS:standard' },
    },
  }),
});
EOF

  # error-handler.ts
  cat > "$PROJECT_DIR/backend/src/shared/middleware/error-handler.ts" << 'EOF'
import type { ErrorRequestHandler } from 'express';
import { logger } from '../utils/logger.js';

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  logger.error(err);
  const status = err.status ?? 500;
  const message = err.message ?? 'Internal Server Error';
  res.status(status).json({ error: { message, status } });
};
EOF

  # validate.ts
  cat > "$PROJECT_DIR/backend/src/shared/middleware/validate.ts" << 'EOF'
import type { Request, Response, NextFunction } from 'express';
import { type ZodSchema, ZodError } from 'zod';

export const validate = (schema: ZodSchema) => (req: Request, res: Response, next: NextFunction): void => {
  try {
    schema.parse({ body: req.body, query: req.query, params: req.params });
    next();
  } catch (error) {
    if (error instanceof ZodError) {
      res.status(400).json({ error: { message: 'Validation error', details: error.errors } });
      return;
    }
    next(error);
  }
};
EOF

  # Health feature
  cat > "$PROJECT_DIR/backend/src/features/health/health.service.ts" << 'EOF'
import { env } from '../../shared/config/env.js';

interface HealthStatus {
  status: 'ok' | 'error';
  timestamp: string;
  uptime: number;
  environment: string;
}

export function getHealthStatus(): HealthStatus {
  return {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: env.NODE_ENV,
  };
}
EOF

  cat > "$PROJECT_DIR/backend/src/features/health/health.controller.ts" << 'EOF'
import { Router, type Router as RouterType } from 'express';
import { getHealthStatus } from './health.service.js';

const router: RouterType = Router();

router.get('/', (_req, res) => {
  res.json(getHealthStatus());
});

export { router as healthRouter };
EOF

  cat > "$PROJECT_DIR/backend/src/features/health/index.ts" << 'EOF'
export { healthRouter } from './health.controller.js';
export { getHealthStatus } from './health.service.js';
EOF

  # OpenAPI spec
  cat > "$PROJECT_DIR/backend/src/openapi.yaml" << EOF
openapi: 3.1.0
info:
  title: ${PROJECT_NAME} API
  version: 1.0.0

servers:
  - url: http://localhost:${BACKEND_PORT}

paths:
  /api/health:
    get:
      operationId: getHealth
      summary: Health check
      responses:
        '200':
          description: Service is healthy
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/HealthStatus'

components:
  schemas:
    HealthStatus:
      type: object
      required: [status, timestamp, uptime, environment]
      properties:
        status:
          type: string
          enum: [ok, error]
        timestamp:
          type: string
          format: date-time
        uptime:
          type: number
        environment:
          type: string
EOF

  # Prisma schema
  cat > "$PROJECT_DIR/backend/prisma/schema.prisma" << EOF
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// Add your models here
// model User {
//   id        String   @id @default(uuid())
//   email     String   @unique
//   createdAt DateTime @default(now())
// }
EOF

  # ESLint config (flat config for ESLint 9)
  cat > "$PROJECT_DIR/backend/eslint.config.mjs" << 'EOF'
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    ignores: ['dist/**', 'node_modules/**'],
  },
  {
    rules: {
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    },
  }
);
EOF

  # Vitest config
  cat > "$PROJECT_DIR/backend/vitest.config.ts" << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.test.ts'],
  },
});
EOF

  # Example test for health service
  cat > "$PROJECT_DIR/backend/src/features/health/health.service.test.ts" << 'EOF'
import { describe, it, expect } from 'vitest';
import { getHealthStatus } from './health.service.js';

describe('Health Service', () => {
  it('should return health status with required fields', () => {
    const status = getHealthStatus();

    expect(status).toHaveProperty('status', 'ok');
    expect(status).toHaveProperty('timestamp');
    expect(status).toHaveProperty('uptime');
    expect(typeof status.uptime).toBe('number');
  });

  it('should return valid ISO timestamp', () => {
    const status = getHealthStatus();
    const date = new Date(status.timestamp);

    expect(date.toString()).not.toBe('Invalid Date');
  });
});
EOF

  log_info "Backend файлы созданы"
}

# ═══════════════════════════════════════════════════════════════════════════
# 7. CREATE FRONTEND FILES
# ═══════════════════════════════════════════════════════════════════════════

create_frontend_files() {
  log_step "Создаю frontend файлы..."

  # vite.config.ts
  cat > "$PROJECT_DIR/frontend/vite.config.ts" << EOF
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: ${FRONTEND_PORT},
  },
});
EOF

  # vite-env.d.ts
  cat > "$PROJECT_DIR/frontend/src/vite-env.d.ts" << 'EOF'
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
EOF

  # index.html
  cat > "$PROJECT_DIR/frontend/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${PROJECT_NAME}</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/app/index.tsx"></script>
  </body>
</html>
EOF

  # App entry
  cat > "$PROJECT_DIR/frontend/src/app/index.tsx" << 'EOF'
import React from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClientProvider } from './providers/query-provider';
import { HomePage } from '../pages/home';
import './styles/index.css';

const container = document.getElementById('root');
if (!container) throw new Error('Root element not found');

createRoot(container).render(
  <React.StrictMode>
    <QueryClientProvider>
      <HomePage />
    </QueryClientProvider>
  </React.StrictMode>
);
EOF

  # Query provider
  cat > "$PROJECT_DIR/frontend/src/app/providers/query-provider.tsx" << 'EOF'
import { QueryClient, QueryClientProvider as TanStackQueryProvider } from '@tanstack/react-query';
import type { ReactNode } from 'react';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 1000 * 60, retry: 1 },
  },
});

export function QueryClientProvider({ children }: { children: ReactNode }): JSX.Element {
  return <TanStackQueryProvider client={queryClient}>{children}</TanStackQueryProvider>;
}
EOF

  cat > "$PROJECT_DIR/frontend/src/app/providers/index.tsx" << 'EOF'
export { QueryClientProvider } from './query-provider';
EOF

  # Styles
  cat > "$PROJECT_DIR/frontend/src/app/styles/index.css" << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  @apply bg-gray-50 text-gray-900;
}
EOF

  # HomePage
  cat > "$PROJECT_DIR/frontend/src/pages/home/ui/HomePage.tsx" << 'EOF'
import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/shared/api';
import type { HealthResponse } from '@/shared/types';

export function HomePage(): JSX.Element {
  const { data, isLoading, error } = useQuery({
    queryKey: ['health'],
    queryFn: () => apiClient.get<HealthResponse>('/api/health'),
  });

  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-4xl font-bold mb-4">Welcome!</h1>
        <p className="text-gray-500 mb-6">Built with Provide Starter Kit</p>
        {isLoading && <p className="text-gray-500">Loading...</p>}
        {error && <p className="text-red-500">Error connecting to backend</p>}
        {data && (
          <div className="bg-green-100 p-4 rounded-lg">
            <p className="text-green-800 font-semibold">Backend is healthy!</p>
            <p className="text-sm text-green-600">Uptime: {Math.floor(data.uptime)}s</p>
          </div>
        )}
      </div>
    </div>
  );
}
EOF

  cat > "$PROJECT_DIR/frontend/src/pages/home/index.ts" << 'EOF'
export { HomePage } from './ui/HomePage';
EOF

  # API client
  cat > "$PROJECT_DIR/frontend/src/shared/api/client.ts" << EOF
const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:${BACKEND_PORT}';

async function request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(\`\${API_URL}\${endpoint}\`, {
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
  });

  if (!response.ok) {
    throw new Error(\`HTTP error! status: \${response.status}\`);
  }

  return response.json() as Promise<T>;
}

export const apiClient = {
  get: <T>(endpoint: string) => request<T>(endpoint),
  post: <T>(endpoint: string, body: unknown) => request<T>(endpoint, { method: 'POST', body: JSON.stringify(body) }),
  put: <T>(endpoint: string, body: unknown) => request<T>(endpoint, { method: 'PUT', body: JSON.stringify(body) }),
  delete: <T>(endpoint: string) => request<T>(endpoint, { method: 'DELETE' }),
};
EOF

  cat > "$PROJECT_DIR/frontend/src/shared/api/index.ts" << 'EOF'
export { apiClient } from './client';
EOF

  # Barrel exports
  for dir in ui lib hooks; do
    echo "// Export shared ${dir} here" > "$PROJECT_DIR/frontend/src/shared/$dir/index.ts"
  done

  # Shared types
  cat > "$PROJECT_DIR/frontend/src/shared/types/index.ts" << 'EOF'
export interface HealthResponse {
  status: string;
  timestamp: string;
  uptime: number;
}
EOF

  # Tailwind config
  cat > "$PROJECT_DIR/frontend/tailwind.config.js" << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: { extend: {} },
  plugins: [],
};
EOF

  cat > "$PROJECT_DIR/frontend/postcss.config.js" << 'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
EOF

  # ESLint config (flat config for ESLint 9)
  cat > "$PROJECT_DIR/frontend/eslint.config.mjs" << 'EOF'
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import reactPlugin from 'eslint-plugin-react';
import reactHooksPlugin from 'eslint-plugin-react-hooks';

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    ignores: ['dist/**', 'node_modules/**'],
  },
  {
    files: ['**/*.{ts,tsx}'],
    plugins: {
      react: reactPlugin,
      'react-hooks': reactHooksPlugin,
    },
    settings: {
      react: { version: 'detect' },
    },
    rules: {
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',
    },
  }
);
EOF

  # Vitest config
  cat > "$PROJECT_DIR/frontend/vitest.config.ts" << 'EOF'
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    include: ['src/**/*.test.{ts,tsx}'],
    passWithNoTests: true,
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
EOF

  # Test setup
  mkdir -p "$PROJECT_DIR/frontend/src/test"
  cat > "$PROJECT_DIR/frontend/src/test/setup.ts" << 'EOF'
import '@testing-library/jest-dom';
EOF

  # Example test for shared types
  cat > "$PROJECT_DIR/frontend/src/shared/types/types.test.ts" << 'EOF'
import { describe, it, expect } from 'vitest';
import type { HealthResponse } from './index';

describe('HealthResponse type', () => {
  it('should have correct shape', () => {
    const response: HealthResponse = {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: 123,
    };

    expect(response.status).toBe('ok');
    expect(typeof response.uptime).toBe('number');
    expect(response.timestamp).toBeDefined();
  });
});
EOF

  log_info "Frontend файлы созданы"
}

# ═══════════════════════════════════════════════════════════════════════════
# 8. CREATE PROJECT CLAUDE.MD & COPY HOOKS
# ═══════════════════════════════════════════════════════════════════════════

setup_project_claude() {
  log_step "Устанавливаю полную конфигурацию Claude в проект..."

  # Create local .claude structure
  mkdir -p "$PROJECT_DIR/.claude"/{skills,commands,agents,hooks,templates,scripts}

  # Copy EVERYTHING from repo to project (full local installation)
  local components=("skills" "commands" "agents" "hooks" "templates" "scripts")
  for component in "${components[@]}"; do
    local src="$TEMP_DIR/claude-starter/.claude/$component"
    local dst="$PROJECT_DIR/.claude/$component"
    if [ -d "$src" ] && [ "$(ls -A "$src" 2>/dev/null)" ]; then
      cp -r "$src/"* "$dst/" 2>/dev/null || true
    fi
  done

  # Make scripts executable
  chmod +x "$PROJECT_DIR/.claude/hooks/"*.sh 2>/dev/null || true
  chmod +x "$PROJECT_DIR/.claude/scripts/"*.sh 2>/dev/null || true
  find "$PROJECT_DIR/.claude/skills" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

  # Install hooks dependencies
  if [ -f "$PROJECT_DIR/.claude/hooks/package.json" ]; then
    log_step "Устанавливаю зависимости для хуков..."
    (cd "$PROJECT_DIR/.claude/hooks" && pnpm install --ignore-workspace >/dev/null 2>&1) || true
  fi

  # Copy settings.json from repo (not from global ~/.claude)
  if [ -f "$TEMP_DIR/claude-starter/.claude/settings.json" ]; then
    cp "$TEMP_DIR/claude-starter/.claude/settings.json" "$PROJECT_DIR/.claude/"
  fi

  # Project CLAUDE.md
  cat > "$PROJECT_DIR/CLAUDE.md" << 'EOF'
# Project Instructions

> Inherits from `~/.claude/CLAUDE.md` (FSD + VSA standards)

## Communication

Always respond in **Russian**. Be direct, focus on architecture.

## Project Structure

- `backend/` — VSA (Vertical Slice Architecture)
- `frontend/` — FSD (Feature-Sliced Design)
- `docs/` — PRD, Architecture, API spec
- `.bmad/` — Sprint state and task queue

## Quick Commands

```bash
pnpm dev           # Start backend + frontend
pnpm typecheck     # TypeScript check
pnpm test          # Run tests
pnpm db:migrate    # Prisma migrations
pnpm db:studio     # Prisma Studio GUI
```

## Workflow

1. `/product-brief` — Business requirements
2. `/architecture` — Tech design
3. `/validate-sprint` — Generate task queue
4. `/ralph-loop` — Autonomous development
EOF

  log_info "Project .claude/ настроен"
}

# ═══════════════════════════════════════════════════════════════════════════
# 9. START DOCKER & WAIT FOR SERVICES
# ═══════════════════════════════════════════════════════════════════════════

start_docker_services() {
  if ! command -v docker &> /dev/null || ! docker info &>/dev/null; then
    log_warn "Docker не доступен — пропускаю запуск контейнеров"
    return
  fi

  log_step "Запускаю Docker контейнеры..."

  cd "$PROJECT_DIR"

  # Stop existing containers if any
  docker compose down -v 2>/dev/null || true

  # Start
  docker compose up -d

  log_info "Docker контейнеры запущены"

  # Wait for PostgreSQL
  log_step "Жду готовности PostgreSQL..."
  local max=30
  local attempt=0
  while [ $attempt -lt $max ]; do
    if docker compose exec -T postgres pg_isready -U postgres &>/dev/null; then
      log_info "PostgreSQL готов"
      break
    fi
    sleep 1
    ((attempt++))
  done

  # Wait for Redis
  attempt=0
  while [ $attempt -lt $max ]; do
    if docker compose exec -T redis redis-cli ping &>/dev/null; then
      log_info "Redis готов"
      break
    fi
    sleep 1
    ((attempt++))
  done
}

# ═══════════════════════════════════════════════════════════════════════════
# 10. INSTALL DEPENDENCIES & SETUP DB
# ═══════════════════════════════════════════════════════════════════════════

install_and_setup() {
  log_step "Устанавливаю зависимости (pnpm install)..."

  cd "$PROJECT_DIR"
  pnpm install

  log_info "Зависимости установлены"

  # Prisma generate & push
  if command -v docker &> /dev/null && docker info &>/dev/null; then
    log_step "Настраиваю Prisma..."
    cd "$PROJECT_DIR/backend"
    pnpm db:generate 2>/dev/null || true
    pnpm db:push 2>/dev/null || true
    cd "$PROJECT_DIR"
    log_info "Prisma настроена"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 11. VERIFY SERVERS
# ═══════════════════════════════════════════════════════════════════════════

verify_servers() {
  log_step "Проверяю что backend запускается..."

  cd "$PROJECT_DIR/backend"
  pnpm dev &
  local pid=$!

  sleep 3

  local attempt=0
  while [ $attempt -lt 15 ]; do
    if curl -s "http://localhost:${BACKEND_PORT}/api/health" | grep -q '"status":"ok"'; then
      log_info "Backend работает: http://localhost:${BACKEND_PORT}/api/health"
      kill $pid 2>/dev/null || true
      cd "$PROJECT_DIR"
      return
    fi
    sleep 1
    ((attempt++))
  done

  kill $pid 2>/dev/null || true
  cd "$PROJECT_DIR"
  log_warn "Backend не ответил — проверь вручную"
}

# ═══════════════════════════════════════════════════════════════════════════
# 12. INIT GIT
# ═══════════════════════════════════════════════════════════════════════════

init_git() {
  if [ ! -d "$PROJECT_DIR/.git" ]; then
    log_step "Инициализирую git..."
    cd "$PROJECT_DIR"
    git init -q
    git add .
    git commit -m "chore: initial project setup with FSD/VSA architecture" -q
    log_info "Git репозиторий создан"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# CLEANUP
# ═══════════════════════════════════════════════════════════════════════════

cleanup() {
  if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}

trap cleanup EXIT

# ═══════════════════════════════════════════════════════════════════════════
# SUCCESS MESSAGE
# ═══════════════════════════════════════════════════════════════════════════

print_success() {
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}                                                                 ${NC}"
  echo -e "${GREEN}   ✅  PROVIDE STARTER KIT УСТАНОВЛЕН!                           ${NC}"
  echo -e "${GREEN}                                                                 ${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${CYAN}📁 Структура проекта:${NC}"
  echo ""
  echo "     backend/           VSA (Express + Prisma + Zod)"
  echo "     frontend/          FSD (React + TanStack Query + Tailwind)"
  echo "     docker-compose.yml PostgreSQL + Redis"
  echo "     .claude/           Hooks для проекта"
  echo ""
  echo -e "  ${CYAN}🔌 Сервисы:${NC}"
  echo ""
  echo "     PostgreSQL   localhost:${POSTGRES_PORT}"
  echo "     Redis        localhost:${REDIS_PORT}"
  echo "     Backend      http://localhost:${BACKEND_PORT}"
  echo "     Frontend     http://localhost:${FRONTEND_PORT}"
  echo ""
  echo -e "  ${CYAN}🚀 Запуск:${NC}"
  echo ""
  echo "     pnpm dev        # Backend + Frontend"
  echo "     docker ps       # Проверить контейнеры"
  echo ""
  echo -e "  ${CYAN}🤖 Claude Code:${NC}"
  echo ""
  echo "     claude"
  echo ""
  echo -e "     ${GREEN}/product-brief${NC}    → Бизнес-требования"
  echo -e "     ${GREEN}/architecture${NC}     → Техническая архитектура"
  echo -e "     ${GREEN}/validate-sprint${NC}  → Генерация задач"
  echo -e "     ${GREEN}/ralph-loop${NC}       → Автономная разработка"
  echo ""
  echo -e "  ${CYAN}💡 Подсказка:${NC} используй ${GREEN}/help${NC} для справки"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# DETECT PROJECT TYPE
# ═══════════════════════════════════════════════════════════════════════════

detect_project_type() {
  # Check if project already exists (has files)
  local file_count=$(ls -A "$PROJECT_DIR" 2>/dev/null | wc -l | xargs)

  if [ "$file_count" -eq 0 ]; then
    # Empty directory → Full installation
    echo "FULL"
    return
  fi

  # Check if it's already a Node.js project
  if [ -f "$PROJECT_DIR/package.json" ] || \
     [ -d "$PROJECT_DIR/backend" ] || \
     [ -d "$PROJECT_DIR/frontend" ] || \
     [ -d "$PROJECT_DIR/src" ]; then
    # Existing project → Hooks only
    echo "HOOKS_ONLY"
    return
  fi

  # Has some files but not a project → Ask user
  echo "UNKNOWN"
}

# ═══════════════════════════════════════════════════════════════════════════
# HOOKS ONLY MODE
# ═══════════════════════════════════════════════════════════════════════════

install_hooks_only() {
  log_step "Режим: установка хуков в существующий проект"

  backup_existing
  clone_repo
  install_claude_config
  setup_project_claude

  # Success message for hooks only
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}                                                                 ${NC}"
  echo -e "${GREEN}   ✅  ХУКИ УСТАНОВЛЕНЫ В ПРОЕКТ!                                ${NC}"
  echo -e "${GREEN}                                                                 ${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${CYAN}📁 Установлено:${NC}"
  echo ""
  echo "     ~/.claude/           Глобальные настройки (skills, rules, hooks)"
  echo "     .claude/hooks/       25 хуков для проекта"
  echo "     .claude/settings.json"
  echo "     CLAUDE.md            Проектные инструкции"
  echo ""
  echo -e "  ${CYAN}🪝 Активные хуки:${NC}"
  echo ""
  echo "     quality-check       TypeScript strict mode"
  echo "     auto-format         Prettier/ESLint autofix"
  echo "     ralph-*             Ralph Loop automation (7 хуков)"
  echo "     check-tests-pass    Блокировка если тесты fail"
  echo ""
  echo -e "  ${CYAN}🤖 Claude Code:${NC}"
  echo ""
  echo "     claude"
  echo ""
  echo -e "     ${GREEN}/product-brief${NC}    → Бизнес-требования"
  echo -e "     ${GREEN}/architecture${NC}     → Техническая архитектура"
  echo -e "     ${GREEN}/validate-sprint${NC}  → Генерация задач"
  echo -e "     ${GREEN}/ralph-loop${NC}       → Автономная разработка"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
  print_banner
  check_prerequisites

  # Detect project type
  MODE=$(detect_project_type)

  case "$MODE" in
    HOOKS_ONLY)
      log_step "Обнаружен существующий проект"
      install_hooks_only
      ;;
    FULL)
      log_step "Пустая папка → полная установка"
      assign_free_ports
      backup_existing
      clone_repo
      install_claude_config
      create_project_structure
      create_config_files
      create_backend_files
      create_frontend_files
      setup_project_claude
      start_docker_services
      install_and_setup
      verify_servers
      init_git
      print_success
      ;;
    UNKNOWN)
      log_warn "Папка содержит файлы, но не похожа на Node.js проект"
      echo ""
      echo "Выбери режим установки:"
      echo "  1) Полная установка (создать структуру проекта)"
      echo "  2) Только хуки (не изменять существующие файлы)"
      echo ""
      read -p "Введи номер (1 или 2): " choice

      case "$choice" in
        1)
          log_step "Режим: полная установка"
          assign_free_ports
          backup_existing
          clone_repo
          install_claude_config
          create_project_structure
          create_config_files
          create_backend_files
          create_frontend_files
          setup_project_claude
          start_docker_services
          install_and_setup
          verify_servers
          init_git
          print_success
          ;;
        2)
          install_hooks_only
          ;;
        *)
          log_error "Неверный выбор. Установка отменена."
          exit 1
          ;;
      esac
      ;;
  esac
}

main "$@"
