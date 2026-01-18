#!/bin/bash
set -e

# Provide Starter Kit Installer
# Автономная разработка full-stack приложений с Claude Code
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/lindwerg/claude-starter/main/install.sh | bash
#
# Creates:
#   1. ~/.claude/ — конфигурация Claude Code (skills, rules, hooks, agents)
#   2. ./backend/, ./frontend/, etc. — структура проекта в текущей папке

REPO_URL="https://github.com/lindwerg/claude-starter"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$HOME/.claude-backup-$(date +%Y%m%d%H%M%S)"
TEMP_DIR=""
PROJECT_DIR="$(pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
  echo -e "${RED}[✗]${NC} $1"
}

log_step() {
  echo -e "${BLUE}[→]${NC} $1"
}

# Print banner
print_banner() {
  echo ""
  echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║                                                           ║${NC}"
  echo -e "${CYAN}║   ${BOLD}${GREEN}PROVIDE STARTER KIT${NC}${CYAN}                                    ║${NC}"
  echo -e "${CYAN}║   ${NC}Автономная разработка full-stack приложений${CYAN}            ║${NC}"
  echo -e "${CYAN}║                                                           ║${NC}"
  echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# 1. Check prerequisites
check_prerequisites() {
  log_step "Проверяю зависимости..."

  local missing=0

  if ! command -v node &> /dev/null; then
    log_error "Node.js не найден"
    echo "    → Установи: https://nodejs.org/ (версия 18+)"
    missing=1
  else
    local node_version=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$node_version" -lt 18 ]; then
      log_error "Node.js версия < 18 (текущая: $(node --version))"
      echo "    → Обнови до версии 18+"
      missing=1
    else
      log_info "Node.js $(node --version)"
    fi
  fi

  if ! command -v git &> /dev/null; then
    log_error "Git не найден"
    echo "    → Установи: https://git-scm.com/"
    missing=1
  else
    log_info "Git $(git --version | cut -d' ' -f3)"
  fi

  if ! command -v pnpm &> /dev/null; then
    log_warn "pnpm не найден — устанавливаю..."
    npm install -g pnpm 2>/dev/null || {
      log_error "Не удалось установить pnpm"
      echo "    → Установи вручную: npm install -g pnpm"
      missing=1
    }
    if command -v pnpm &> /dev/null; then
      log_info "pnpm установлен"
    fi
  else
    log_info "pnpm $(pnpm --version)"
  fi

  if ! command -v jq &> /dev/null; then
    log_warn "jq не найден — settings будут заменены, не объединены"
    echo "    → Рекомендуется: brew install jq (macOS) или apt install jq (Linux)"
  fi

  if ! command -v claude &> /dev/null; then
    log_warn "Claude Code не найден"
    echo "    → Установи после: npm install -g @anthropic-ai/claude-code"
  else
    log_info "Claude Code найден"
  fi

  if [ $missing -eq 1 ]; then
    echo ""
    log_error "Установка прервана. Установи недостающие зависимости."
    exit 1
  fi
}

# 2. Backup existing config
backup_existing() {
  if [ -d "$CLAUDE_DIR" ]; then
    log_step "Сохраняю backup ~/.claude → $BACKUP_DIR"
    cp -r "$CLAUDE_DIR" "$BACKUP_DIR"
    echo "$BACKUP_DIR" > "$HOME/.claude-starter-last-backup"
    log_info "Backup создан"
  else
    log_info "Чистая установка (нет существующего ~/.claude)"
  fi
}

# 3. Clone repo with submodules
clone_repo() {
  log_step "Скачиваю Provide Starter Kit..."
  TEMP_DIR=$(mktemp -d)

  if git clone --depth 1 --recurse-submodules "$REPO_URL" "$TEMP_DIR/claude-starter" 2>/dev/null; then
    log_info "Репозиторий загружен"
  else
    log_error "Не удалось скачать репозиторий: $REPO_URL"
    exit 1
  fi
}

# 4. Install Claude Code config (skills, rules, hooks, agents)
install_claude_config() {
  log_step "Устанавливаю конфигурацию Claude Code..."

  # Create directories
  mkdir -p "$CLAUDE_DIR"/{skills,rules,hooks,commands,agents,templates,scripts,orchestrator}

  # Copy components
  local components=("skills" "rules" "hooks" "commands" "agents" "orchestrator")

  for component in "${components[@]}"; do
    local src_dir="$TEMP_DIR/claude-starter/.claude/$component"
    local dst_dir="$CLAUDE_DIR/$component"

    if [ -d "$src_dir" ] && [ "$(ls -A "$src_dir" 2>/dev/null)" ]; then
      cp -r "$src_dir/"* "$dst_dir/" 2>/dev/null || true
    fi
  done

  # Make hook scripts executable
  chmod +x "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true
  chmod +x "$CLAUDE_DIR/orchestrator/ralph" 2>/dev/null || true
  chmod +x "$CLAUDE_DIR/orchestrator/lib/"*.sh 2>/dev/null || true

  log_info "Skills, rules, hooks, agents установлены"
}

# 5. Merge settings.json
merge_settings() {
  local src_settings="$TEMP_DIR/claude-starter/.claude/settings.json"
  local dst_settings="$CLAUDE_DIR/settings.json"

  if [ ! -f "$src_settings" ]; then
    return
  fi

  if command -v jq &> /dev/null && [ -f "$dst_settings" ]; then
    log_step "Объединяю settings.json..."
    jq -s 'reduce .[] as $item ({}; . * $item)' \
      "$src_settings" "$dst_settings" > "$CLAUDE_DIR/settings.merged.json"
    mv "$CLAUDE_DIR/settings.merged.json" "$dst_settings"
    log_info "Settings объединены"
  else
    cp "$src_settings" "$dst_settings"
    log_info "Settings установлен"
  fi
}

# 6. Merge mcp_config.json
merge_mcp() {
  local src_mcp="$TEMP_DIR/claude-starter/.claude/mcp_config.json"
  local dst_mcp="$CLAUDE_DIR/mcp_config.json"

  if [ ! -f "$src_mcp" ]; then
    return
  fi

  if command -v jq &> /dev/null && [ -f "$dst_mcp" ]; then
    log_step "Объединяю mcp_config.json..."
    jq -s '.[0].mcpServers as $src | .[1].mcpServers as $dst | {mcpServers: ($src + $dst)}' \
      "$src_mcp" "$dst_mcp" > "$CLAUDE_DIR/mcp_config.merged.json"
    mv "$CLAUDE_DIR/mcp_config.merged.json" "$dst_mcp"
    log_info "MCP config объединён"
  else
    cp "$src_mcp" "$dst_mcp"
    log_info "MCP config установлен"
  fi
}

# 7. Install templates
install_templates() {
  local src_templates="$TEMP_DIR/claude-starter/templates"

  if [ -d "$src_templates" ]; then
    cp -r "$src_templates/"* "$CLAUDE_DIR/templates/" 2>/dev/null || true
    log_info "Шаблоны установлены"
  fi
}

# 8. Install TDD Guard
install_tdd_guard() {
  if ! command -v tdd-guard &> /dev/null; then
    log_step "Устанавливаю TDD Guard..."
    npm install -g tdd-guard 2>/dev/null && log_info "TDD Guard установлен" || log_warn "Не удалось установить tdd-guard"
  fi
}

# ═══════════════════════════════════════════════════════════════════
# 9. CREATE PROJECT STRUCTURE — Главная новая функция!
# ═══════════════════════════════════════════════════════════════════

create_project_structure() {
  log_step "Создаю структуру full-stack проекта..."

  local templates="$CLAUDE_DIR/templates"

  # ─────────────────────────────────────────────────────────────────
  # Backend (VSA — Vertical Slice Architecture)
  # ─────────────────────────────────────────────────────────────────
  mkdir -p "$PROJECT_DIR/backend/src/features"
  mkdir -p "$PROJECT_DIR/backend/src/shared/middleware"
  mkdir -p "$PROJECT_DIR/backend/src/shared/utils"
  mkdir -p "$PROJECT_DIR/backend/src/shared/types"
  mkdir -p "$PROJECT_DIR/backend/src/shared/config"
  mkdir -p "$PROJECT_DIR/backend/prisma"

  # Backend placeholder files
  cat > "$PROJECT_DIR/backend/src/index.ts" << 'BACKEND_INDEX'
import express from 'express';

const app = express();
const PORT = process.env.PORT || 3001;

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`🚀 Backend running on http://localhost:${PORT}`);
});
BACKEND_INDEX

  cat > "$PROJECT_DIR/backend/prisma/schema.prisma" << 'PRISMA_SCHEMA'
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
PRISMA_SCHEMA

  cat > "$PROJECT_DIR/backend/src/openapi.yaml" << 'OPENAPI_SPEC'
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
  description: Generated by Provide Starter Kit

servers:
  - url: http://localhost:3001
    description: Development server

paths:
  /health:
    get:
      operationId: healthCheck
      summary: Health check endpoint
      responses:
        '200':
          description: Service is healthy
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                  timestamp:
                    type: string

components:
  schemas: {}
  securitySchemes: {}
OPENAPI_SPEC

  log_info "Backend (VSA) создан"

  # ─────────────────────────────────────────────────────────────────
  # Frontend (FSD — Feature-Sliced Design)
  # ─────────────────────────────────────────────────────────────────
  mkdir -p "$PROJECT_DIR/frontend/src/app"
  mkdir -p "$PROJECT_DIR/frontend/src/pages"
  mkdir -p "$PROJECT_DIR/frontend/src/widgets"
  mkdir -p "$PROJECT_DIR/frontend/src/features"
  mkdir -p "$PROJECT_DIR/frontend/src/entities"
  mkdir -p "$PROJECT_DIR/frontend/src/shared/ui"
  mkdir -p "$PROJECT_DIR/frontend/src/shared/lib"
  mkdir -p "$PROJECT_DIR/frontend/src/shared/hooks"
  mkdir -p "$PROJECT_DIR/frontend/src/shared/api"
  mkdir -p "$PROJECT_DIR/frontend/src/shared/types"
  mkdir -p "$PROJECT_DIR/frontend/e2e"

  # Frontend placeholder files
  cat > "$PROJECT_DIR/frontend/src/app/App.tsx" << 'APP_TSX'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient();

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <div className="min-h-screen bg-gray-50">
        <main className="container mx-auto px-4 py-8">
          <h1 className="text-3xl font-bold text-gray-900">
            Welcome to Your App
          </h1>
          <p className="mt-4 text-gray-600">
            Built with Provide Starter Kit
          </p>
        </main>
      </div>
    </QueryClientProvider>
  );
}
APP_TSX

  cat > "$PROJECT_DIR/frontend/src/main.tsx" << 'MAIN_TSX'
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './app/App';
import './index.css';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>
);
MAIN_TSX

  cat > "$PROJECT_DIR/frontend/src/index.css" << 'INDEX_CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;
INDEX_CSS

  cat > "$PROJECT_DIR/frontend/index.html" << 'INDEX_HTML'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>App</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
INDEX_HTML

  log_info "Frontend (FSD) создан"

  # ─────────────────────────────────────────────────────────────────
  # Docs & BMAD
  # ─────────────────────────────────────────────────────────────────
  mkdir -p "$PROJECT_DIR/docs"
  mkdir -p "$PROJECT_DIR/.bmad"
  mkdir -p "$PROJECT_DIR/.claude"

  # Copy doc templates if available
  if [ -f "$templates/docs/PRD.md" ]; then
    cp "$templates/docs/PRD.md" "$PROJECT_DIR/docs/"
  fi
  if [ -f "$templates/docs/ARCHITECTURE.md" ]; then
    cp "$templates/docs/ARCHITECTURE.md" "$PROJECT_DIR/docs/"
  fi
  if [ -f "$templates/docs/API_SPEC.yaml" ]; then
    cp "$templates/docs/API_SPEC.yaml" "$PROJECT_DIR/docs/"
  fi

  log_info "Docs создан"

  # ─────────────────────────────────────────────────────────────────
  # Root config files
  # ─────────────────────────────────────────────────────────────────

  # Copy templates if available
  if [ -f "$templates/project/docker-compose.yml" ]; then
    cp "$templates/project/docker-compose.yml" "$PROJECT_DIR/"
  fi
  if [ -f "$templates/project/vitest.config.ts" ]; then
    cp "$templates/project/vitest.config.ts" "$PROJECT_DIR/"
  fi
  if [ -f "$templates/project/playwright.config.ts" ]; then
    cp "$templates/project/playwright.config.ts" "$PROJECT_DIR/"
  fi
  if [ -f "$templates/project/.mcp.json" ]; then
    cp "$templates/project/.mcp.json" "$PROJECT_DIR/"
  fi

  # tsconfig.json
  cat > "$PROJECT_DIR/tsconfig.json" << 'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true,
    "noEmit": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./frontend/src/*"],
      "@backend/*": ["./backend/src/*"]
    }
  },
  "include": ["frontend/src", "backend/src"],
  "exclude": ["node_modules", "dist"]
}
TSCONFIG

  # package.json
  cat > "$PROJECT_DIR/package.json" << 'PACKAGE_JSON'
{
  "name": "my-app",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "concurrently \"pnpm dev:backend\" \"pnpm dev:frontend\"",
    "dev:backend": "cd backend && tsx watch src/index.ts",
    "dev:frontend": "cd frontend && vite",
    "build": "pnpm build:backend && pnpm build:frontend",
    "build:backend": "cd backend && tsc",
    "build:frontend": "cd frontend && vite build",
    "typecheck": "tsc --noEmit",
    "lint": "eslint . --ext .ts,.tsx",
    "lint:fix": "eslint . --ext .ts,.tsx --fix",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:e2e": "playwright test",
    "db:generate": "cd backend && prisma generate",
    "db:migrate": "cd backend && prisma migrate dev",
    "db:push": "cd backend && prisma db push",
    "db:studio": "cd backend && prisma studio",
    "generate-api-types": "openapi-typescript backend/src/openapi.yaml -o frontend/src/shared/api/types.ts"
  },
  "dependencies": {
    "@prisma/client": "^5.22.0",
    "@tanstack/react-query": "^5.59.0",
    "express": "^4.21.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "zod": "^3.23.8",
    "zustand": "^5.0.0"
  },
  "devDependencies": {
    "@playwright/test": "^1.48.0",
    "@testing-library/react": "^16.0.1",
    "@types/express": "^5.0.0",
    "@types/node": "^22.7.5",
    "@types/react": "^18.3.11",
    "@types/react-dom": "^18.3.1",
    "@typescript-eslint/eslint-plugin": "^8.8.1",
    "@typescript-eslint/parser": "^8.8.1",
    "@vitejs/plugin-react": "^4.3.2",
    "autoprefixer": "^10.4.20",
    "concurrently": "^9.0.1",
    "eslint": "^9.12.0",
    "openapi-typescript": "^7.4.1",
    "postcss": "^8.4.47",
    "prisma": "^5.22.0",
    "tailwindcss": "^3.4.13",
    "tsx": "^4.19.1",
    "typescript": "^5.6.3",
    "vite": "^5.4.8",
    "vitest": "^2.1.2"
  },
  "engines": {
    "node": ">=18"
  }
}
PACKAGE_JSON

  # .gitignore
  cat > "$PROJECT_DIR/.gitignore" << 'GITIGNORE'
# Dependencies
node_modules/
.pnpm-store/

# Build
dist/
build/
.cache/

# Environment
.env
.env.local
.env.*.local

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Testing
coverage/
playwright-report/
test-results/

# Prisma
backend/prisma/*.db
backend/prisma/*.db-journal

# Logs
*.log
npm-debug.log*

# BMAD
.bmad/ralph-in-progress
.bmad/subagent-active
.bmad/sprint-validation-pending
GITIGNORE

  # .env.example
  cat > "$PROJECT_DIR/.env.example" << 'ENV_EXAMPLE'
# Database
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/myapp?schema=public"

# Backend
PORT=3001
NODE_ENV=development

# Frontend (Vite)
VITE_API_URL=http://localhost:3001
ENV_EXAMPLE

  # CLAUDE.md for project
  cat > "$PROJECT_DIR/CLAUDE.md" << 'PROJECT_CLAUDE_MD'
# Project Instructions

> Inherits from `~/.claude/CLAUDE.md` (FSD + VSA standards)

## Communication

Always respond in **Russian**. Be direct, explain the "why", focus on architecture.

## Project Structure

- `backend/` — VSA (Vertical Slice Architecture)
- `frontend/` — FSD (Feature-Sliced Design)
- `docs/` — PRD, Architecture, API spec
- `.bmad/` — Sprint state and task queue

## Quick Commands

```bash
pnpm dev          # Start both backend and frontend
pnpm typecheck    # TypeScript check
pnpm test         # Run tests
pnpm db:migrate   # Run Prisma migrations
```

## Workflow

1. `/product-brief` — Business requirements
2. `/architecture` — Tech design
3. `/validate-sprint` — Generate task queue
4. `/ralph-loop` — Autonomous development
PROJECT_CLAUDE_MD

  log_info "Config files созданы"

  # ─────────────────────────────────────────────────────────────────
  # Tailwind & PostCSS
  # ─────────────────────────────────────────────────────────────────
  cat > "$PROJECT_DIR/tailwind.config.js" << 'TAILWIND_CONFIG'
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./frontend/index.html', './frontend/src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {},
  },
  plugins: [],
};
TAILWIND_CONFIG

  cat > "$PROJECT_DIR/postcss.config.js" << 'POSTCSS_CONFIG'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
POSTCSS_CONFIG

  # Vite config
  cat > "$PROJECT_DIR/frontend/vite.config.ts" << 'VITE_CONFIG'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  root: './frontend',
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true,
      },
    },
  },
});
VITE_CONFIG

  log_info "Tailwind & Vite настроены"
}

# 10. Install dependencies
install_dependencies() {
  log_step "Устанавливаю зависимости (pnpm install)..."

  cd "$PROJECT_DIR"

  if pnpm install 2>/dev/null; then
    log_info "Зависимости установлены"
  else
    log_warn "pnpm install завершился с ошибками — попробуй запустить вручную"
  fi
}

# 11. Initialize git
init_git() {
  if [ ! -d "$PROJECT_DIR/.git" ]; then
    log_step "Инициализирую git репозиторий..."
    cd "$PROJECT_DIR"
    git init -q
    git add .
    git commit -m "Initial commit from Provide Starter Kit" -q
    log_info "Git репозиторий создан"
  fi
}

# Cleanup
cleanup() {
  if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}

trap cleanup EXIT

# Print success message
print_success() {
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}                                                             ${NC}"
  echo -e "${GREEN}   ✅  PROVIDE STARTER KIT УСТАНОВЛЕН!                       ${NC}"
  echo -e "${GREEN}                                                             ${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${CYAN}📁 Создана структура проекта:${NC}"
  echo ""
  echo "     backend/          — VSA (Vertical Slice Architecture)"
  echo "     frontend/         — FSD (Feature-Sliced Design)"
  echo "     docs/             — PRD, Architecture templates"
  echo "     docker-compose.yml — PostgreSQL + Redis"
  echo ""
  echo -e "  ${CYAN}🚀 Следующие шаги:${NC}"
  echo ""
  echo "     1. Запусти Docker (опционально):"
  echo "        docker compose up -d"
  echo ""
  echo "     2. Запусти Claude Code:"
  echo "        claude"
  echo ""
  echo "     3. Начни разработку:"
  echo -e "        ${GREEN}/product-brief${NC}    → Бизнес-требования"
  echo -e "        ${GREEN}/architecture${NC}     → Техническая архитектура"
  echo -e "        ${GREEN}/validate-sprint${NC}  → Генерация задач"
  echo -e "        ${GREEN}/ralph-loop${NC}       → Автономная разработка"
  echo ""
  echo -e "  ${CYAN}💡 Подсказка:${NC} используй ${GREEN}/help${NC} для справки"
  echo ""
  echo -e "  ${CYAN}📚 Документация:${NC} https://github.com/lindwerg/claude-starter"
  echo ""
}

# Main
main() {
  print_banner
  check_prerequisites
  backup_existing
  clone_repo
  install_claude_config
  merge_settings
  merge_mcp
  install_templates
  install_tdd_guard

  # NEW: Create project structure
  create_project_structure
  install_dependencies
  init_git

  print_success
}

main "$@"
