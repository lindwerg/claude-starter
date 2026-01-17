#!/bin/bash
set -e

# Claude Starter Kit - Project Initializer
# Автоматизирует создание full-stack проекта с FSD/VSA архитектурой
#
# Usage: ./init-project.sh [project-name] [--db postgres|mysql|sqlite]

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Default values
PROJECT_NAME="${1:-$(basename "$PWD")}"
DB_TYPE="postgres"
POSTGRES_PORT=5433
REDIS_PORT=6380
BACKEND_PORT=3001
FRONTEND_PORT=5173

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --db)
      DB_TYPE="$2"
      shift 2
      ;;
    --postgres-port)
      POSTGRES_PORT="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Check prerequisites
check_prerequisites() {
  log_step "Checking prerequisites..."

  local missing=()

  command -v node &>/dev/null || missing+=("node")
  command -v pnpm &>/dev/null || missing+=("pnpm")
  command -v docker &>/dev/null || missing+=("docker")

  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Missing required tools: ${missing[*]}"
    echo ""
    echo "Install missing tools:"
    [[ " ${missing[*]} " =~ " node " ]] && echo "  - Node.js: https://nodejs.org/"
    [[ " ${missing[*]} " =~ " pnpm " ]] && echo "  - pnpm: npm install -g pnpm"
    [[ " ${missing[*]} " =~ " docker " ]] && echo "  - Docker: https://docker.com/"
    exit 1
  fi

  # Check Docker is running
  if ! docker info &>/dev/null; then
    log_error "Docker is not running. Please start Docker Desktop."
    exit 1
  fi

  log_info "All prerequisites met"
}

# Create project structure
create_structure() {
  log_step "Creating project structure..."

  # Root files
  mkdir -p backend/src/{features/health,shared/{middleware,utils,config,types}}
  mkdir -p backend/prisma
  mkdir -p frontend/src/{app/providers,pages/home/ui,widgets,features,entities,shared/{ui,lib,hooks,api,types}}
  mkdir -p frontend/public

  log_info "Directory structure created"
}

# Create .mcp.json
create_mcp_config() {
  log_step "Creating .mcp.json for MCP servers..."

  cat > .mcp.json << 'EOF'
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

  log_info ".mcp.json created"
}

# Create docker-compose.yml
create_docker_compose() {
  log_step "Creating docker-compose.yml..."

  cat > docker-compose.yml << EOF
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

  log_info "docker-compose.yml created"
}

# Create package.json files
create_package_json() {
  log_step "Creating package.json files..."

  # Root package.json
  cat > package.json << EOF
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
    "db:generate": "pnpm --filter backend db:generate",
    "db:push": "pnpm --filter backend db:push",
    "db:migrate": "pnpm --filter backend db:migrate",
    "generate-api-types": "openapi-typescript backend/src/openapi.yaml -o frontend/src/shared/api/types.ts"
  },
  "devDependencies": {
    "concurrently": "^9.1.2",
    "openapi-typescript": "^7.5.2"
  }
}
EOF

  # pnpm-workspace.yaml
  cat > pnpm-workspace.yaml << 'EOF'
packages:
  - 'backend'
  - 'frontend'
EOF

  # Backend package.json
  cat > backend/package.json << EOF
{
  "name": "${PROJECT_NAME}-backend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/app.ts",
    "build": "tsc",
    "start": "node dist/app.js",
    "lint": "eslint src --ext .ts",
    "test": "vitest",
    "db:generate": "prisma generate",
    "db:push": "prisma db push",
    "db:migrate": "prisma migrate dev"
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
    "@types/cors": "^2.8.17",
    "@types/express": "^5.0.0",
    "@types/node": "^22.10.7",
    "prisma": "^6.2.1",
    "tsx": "^4.19.2",
    "typescript": "^5.7.3",
    "vitest": "^2.1.8"
  }
}
EOF

  # Frontend package.json
  cat > frontend/package.json << EOF
{
  "name": "${PROJECT_NAME}-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint src --ext .ts,.tsx"
  },
  "dependencies": {
    "@tanstack/react-query": "^5.64.1",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "zustand": "^5.0.3"
  },
  "devDependencies": {
    "@types/react": "^18.3.18",
    "@types/react-dom": "^18.3.5",
    "@vitejs/plugin-react": "^4.3.4",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.5.1",
    "tailwindcss": "^3.4.17",
    "typescript": "^5.7.3",
    "vite": "^6.0.7"
  }
}
EOF

  log_info "package.json files created"
}

# Create TypeScript configs
create_tsconfig() {
  log_step "Creating TypeScript configs..."

  # Backend tsconfig
  cat > backend/tsconfig.json << 'EOF'
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

  # Frontend tsconfig
  cat > frontend/tsconfig.json << 'EOF'
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
    "exactOptionalPropertyTypes": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

  cat > frontend/tsconfig.node.json << 'EOF'
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

  log_info "TypeScript configs created"
}

# Create backend files
create_backend_files() {
  log_step "Creating backend files..."

  # app.ts
  cat > backend/src/app.ts << 'EOF'
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
app.use(
  cors({
    origin: env.CORS_ORIGIN,
    credentials: true,
  })
);

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
  cat > backend/src/shared/config/env.ts << EOF
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
  cat > backend/src/shared/utils/logger.ts << 'EOF'
import pino from 'pino';
import { env } from '../config/env.js';

export const logger = pino({
  level: env.NODE_ENV === 'production' ? 'info' : 'debug',
  transport:
    env.NODE_ENV === 'development'
      ? {
          target: 'pino-pretty',
          options: {
            colorize: true,
            translateTime: 'SYS:standard',
          },
        }
      : undefined,
});
EOF

  # error-handler.ts
  cat > backend/src/shared/middleware/error-handler.ts << 'EOF'
import type { ErrorRequestHandler } from 'express';
import { logger } from '../utils/logger.js';

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  logger.error(err);

  const status = err.status ?? 500;
  const message = err.message ?? 'Internal Server Error';

  res.status(status).json({
    error: {
      message,
      status,
    },
  });
};
EOF

  # validate.ts
  cat > backend/src/shared/middleware/validate.ts << 'EOF'
import type { Request, Response, NextFunction } from 'express';
import { type ZodSchema, ZodError } from 'zod';

export const validate =
  (schema: ZodSchema) =>
  (req: Request, res: Response, next: NextFunction): void => {
    try {
      schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({
          error: {
            message: 'Validation error',
            details: error.errors,
          },
        });
        return;
      }
      next(error);
    }
  };
EOF

  # health feature
  cat > backend/src/features/health/health.service.ts << 'EOF'
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

  cat > backend/src/features/health/health.controller.ts << 'EOF'
import { Router } from 'express';
import { getHealthStatus } from './health.service.js';

const router = Router();

router.get('/', (_req, res) => {
  res.json(getHealthStatus());
});

export { router as healthRouter };
EOF

  cat > backend/src/features/health/index.ts << 'EOF'
export { healthRouter } from './health.controller.js';
export { getHealthStatus } from './health.service.js';
EOF

  # OpenAPI spec
  cat > backend/src/openapi.yaml << EOF
openapi: 3.1.0
info:
  title: ${PROJECT_NAME} API
  version: 1.0.0
  description: API for ${PROJECT_NAME}

servers:
  - url: http://localhost:${BACKEND_PORT}
    description: Development server

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
      required:
        - status
        - timestamp
        - uptime
        - environment
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
  cat > backend/prisma/schema.prisma << EOF
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// Add your models here
EOF

  log_info "Backend files created"
}

# Create frontend files
create_frontend_files() {
  log_step "Creating frontend files..."

  # vite.config.ts
  cat > frontend/vite.config.ts << 'EOF'
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
    port: 5173,
  },
});
EOF

  # vite-env.d.ts (CRITICAL!)
  cat > frontend/src/vite-env.d.ts << 'EOF'
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
EOF

  # index.html
  cat > frontend/index.html << EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
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
  cat > frontend/src/app/index.tsx << 'EOF'
import React from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClientProvider } from './providers/query-provider';
import { HomePage } from '../pages/home';
import './styles/index.css';

const container = document.getElementById('root');
if (!container) throw new Error('Root element not found');

const root = createRoot(container);

root.render(
  <React.StrictMode>
    <QueryClientProvider>
      <HomePage />
    </QueryClientProvider>
  </React.StrictMode>
);
EOF

  # Query provider
  cat > frontend/src/app/providers/query-provider.tsx << 'EOF'
import { QueryClient, QueryClientProvider as TanStackQueryProvider } from '@tanstack/react-query';
import type { ReactNode } from 'react';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60,
      retry: 1,
    },
  },
});

interface Props {
  children: ReactNode;
}

export function QueryClientProvider({ children }: Props): JSX.Element {
  return <TanStackQueryProvider client={queryClient}>{children}</TanStackQueryProvider>;
}
EOF

  cat > frontend/src/app/providers/index.tsx << 'EOF'
export { QueryClientProvider } from './query-provider';
EOF

  # Styles
  mkdir -p frontend/src/app/styles
  cat > frontend/src/app/styles/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  @apply bg-gray-50 text-gray-900;
}
EOF

  # HomePage
  cat > frontend/src/pages/home/ui/HomePage.tsx << 'EOF'
import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/shared/api';

export function HomePage(): JSX.Element {
  const { data, isLoading, error } = useQuery({
    queryKey: ['health'],
    queryFn: () => apiClient.get('/api/health'),
  });

  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-4xl font-bold mb-4">Welcome!</h1>
        {isLoading && <p className="text-gray-500">Loading...</p>}
        {error && <p className="text-red-500">Error connecting to backend</p>}
        {data && (
          <div className="bg-green-100 p-4 rounded-lg">
            <p className="text-green-800">Backend is healthy</p>
            <p className="text-sm text-green-600">Uptime: {Math.floor(data.uptime)}s</p>
          </div>
        )}
      </div>
    </div>
  );
}
EOF

  cat > frontend/src/pages/home/index.ts << 'EOF'
export { HomePage } from './ui/HomePage';
EOF

  # API client (CRITICAL: body: null, not undefined!)
  cat > frontend/src/shared/api/client.ts << EOF
const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:${BACKEND_PORT}';

interface RequestOptions {
  method?: string;
  headers?: Record<string, string>;
  body?: unknown;
}

async function request<T>(endpoint: string, options: RequestOptions = {}): Promise<T> {
  const { method = 'GET', headers = {}, body } = options;

  const response = await fetch(\`\${API_URL}\${endpoint}\`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
    // CRITICAL: use null, not undefined for body
    body: body !== undefined ? JSON.stringify(body) : null,
  });

  if (!response.ok) {
    throw new Error(\`HTTP error! status: \${response.status}\`);
  }

  return response.json() as Promise<T>;
}

export const apiClient = {
  get: <T>(endpoint: string) => request<T>(endpoint),
  post: <T>(endpoint: string, body: unknown) => request<T>(endpoint, { method: 'POST', body }),
  put: <T>(endpoint: string, body: unknown) => request<T>(endpoint, { method: 'PUT', body }),
  delete: <T>(endpoint: string) => request<T>(endpoint, { method: 'DELETE' }),
};
EOF

  cat > frontend/src/shared/api/index.ts << 'EOF'
export { apiClient } from './client';
EOF

  # Shared barrel exports
  for dir in ui lib hooks types; do
    cat > "frontend/src/shared/$dir/index.ts" << 'EOF'
// Export shared components/utilities here
EOF
  done

  # Tailwind config
  cat > frontend/tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {},
  },
  plugins: [],
};
EOF

  # PostCSS config
  cat > frontend/postcss.config.js << 'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
EOF

  log_info "Frontend files created"
}

# Create env files
create_env_files() {
  log_step "Creating environment files..."

  # Backend .env.example
  cat > backend/.env.example << EOF
NODE_ENV=development
PORT=${BACKEND_PORT}
DATABASE_URL=postgresql://postgres:postgres@localhost:${POSTGRES_PORT}/${PROJECT_NAME}
CORS_ORIGIN=http://localhost:${FRONTEND_PORT}
EOF

  # Copy to .env
  cp backend/.env.example backend/.env

  # Frontend .env.example
  cat > frontend/.env.example << EOF
VITE_API_URL=http://localhost:${BACKEND_PORT}
EOF

  cp frontend/.env.example frontend/.env

  log_info "Environment files created"
}

# Create .gitignore
create_gitignore() {
  log_step "Creating .gitignore..."

  cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.pnpm-store/

# Build
dist/
build/
.next/

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

# Logs
*.log
npm-debug.log*
pnpm-debug.log*

# Testing
coverage/
.nyc_output/

# Misc
*.tsbuildinfo
EOF

  log_info ".gitignore created"
}

# Start Docker services
start_docker() {
  log_step "Starting Docker services..."

  # Check if containers already exist
  if docker compose ps --quiet 2>/dev/null | grep -q .; then
    log_warn "Existing containers found, recreating..."
    docker compose down -v 2>/dev/null || true
  fi

  docker compose up -d

  log_info "Docker services starting..."
}

# Wait for services to be healthy
wait_for_services() {
  log_step "Waiting for services to be healthy..."

  local max_attempts=30
  local attempt=0

  # Wait for PostgreSQL
  echo -n "  PostgreSQL: "
  while [ $attempt -lt $max_attempts ]; do
    if docker compose exec -T postgres pg_isready -U postgres &>/dev/null; then
      echo -e "${GREEN}ready${NC}"
      break
    fi
    echo -n "."
    sleep 1
    ((attempt++))
  done

  if [ $attempt -eq $max_attempts ]; then
    echo -e "${RED}timeout${NC}"
    log_error "PostgreSQL failed to start"
    docker compose logs postgres
    exit 1
  fi

  # Wait for Redis
  attempt=0
  echo -n "  Redis: "
  while [ $attempt -lt $max_attempts ]; do
    if docker compose exec -T redis redis-cli ping &>/dev/null; then
      echo -e "${GREEN}ready${NC}"
      break
    fi
    echo -n "."
    sleep 1
    ((attempt++))
  done

  if [ $attempt -eq $max_attempts ]; then
    echo -e "${RED}timeout${NC}"
    log_error "Redis failed to start"
    docker compose logs redis
    exit 1
  fi

  log_info "All services healthy"
}

# Install dependencies
install_dependencies() {
  log_step "Installing dependencies..."

  pnpm install

  log_info "Dependencies installed"
}

# Generate Prisma client
setup_database() {
  log_step "Setting up database..."

  cd backend
  pnpm db:generate
  pnpm db:push
  cd ..

  log_info "Database setup complete"
}

# Start development servers in background and verify
verify_servers() {
  log_step "Verifying servers..."

  # Start backend in background
  log_info "Starting backend..."
  cd backend
  pnpm dev &
  BACKEND_PID=$!
  cd ..

  # Wait for backend to be ready
  local max_attempts=30
  local attempt=0

  echo -n "  Backend: "
  while [ $attempt -lt $max_attempts ]; do
    if curl -s "http://localhost:${BACKEND_PORT}/api/health" &>/dev/null; then
      echo -e "${GREEN}ready${NC}"
      break
    fi
    echo -n "."
    sleep 1
    ((attempt++))
  done

  if [ $attempt -eq $max_attempts ]; then
    echo -e "${RED}timeout${NC}"
    log_error "Backend failed to start"
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
  fi

  # Test health endpoint
  local health_response
  health_response=$(curl -s "http://localhost:${BACKEND_PORT}/api/health")

  if echo "$health_response" | grep -q '"status":"ok"'; then
    log_info "Health endpoint: OK"
  else
    log_error "Health endpoint failed"
    echo "$health_response"
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
  fi

  # Stop backend (user will start it manually)
  kill $BACKEND_PID 2>/dev/null || true

  log_info "All servers verified"
}

# Initialize git
init_git() {
  log_step "Initializing git repository..."

  if [ ! -d .git ]; then
    git init
    git add .
    git commit -m "chore: initial project setup with FSD/VSA architecture"
    log_info "Git repository initialized"
  else
    log_info "Git repository already exists"
  fi
}

# Print summary
print_summary() {
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}  Project ${PROJECT_NAME} created successfully!${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "  Services:"
  echo "    - PostgreSQL: localhost:${POSTGRES_PORT}"
  echo "    - Redis:      localhost:${REDIS_PORT}"
  echo "    - Backend:    http://localhost:${BACKEND_PORT}"
  echo "    - Frontend:   http://localhost:${FRONTEND_PORT}"
  echo ""
  echo "  Quick Start:"
  echo "    pnpm dev           # Start both servers"
  echo "    pnpm dev:backend   # Backend only"
  echo "    pnpm dev:frontend  # Frontend only"
  echo ""
  echo "  MCP Servers:"
  echo "    Run /mcp in Claude Code to verify context7 and playwright"
  echo ""
  echo "  Next Steps:"
  echo "    1. Open the project in Claude Code"
  echo "    2. Start building your features!"
  echo ""
}

# Main
main() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  Claude Starter Kit - Project Initializer${NC}"
  echo -e "${BLUE}  Creating: ${PROJECT_NAME}${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  check_prerequisites
  create_structure
  create_mcp_config
  create_docker_compose
  create_package_json
  create_tsconfig
  create_backend_files
  create_frontend_files
  create_env_files
  create_gitignore
  start_docker
  wait_for_services
  install_dependencies
  setup_database
  verify_servers
  init_git
  print_summary
}

main "$@"
