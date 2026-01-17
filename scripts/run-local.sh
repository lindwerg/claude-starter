#!/bin/bash
# Local Development Runner
# Starts all services for local development
#
# Usage: ./scripts/run-local.sh [--skip-docker] [--backend-only] [--frontend-only]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Flags
SKIP_DOCKER=false
BACKEND_ONLY=false
FRONTEND_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-docker) SKIP_DOCKER=true; shift ;;
    --backend-only) BACKEND_ONLY=true; shift ;;
    --frontend-only) FRONTEND_ONLY=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prereqs() {
  log_info "Checking prerequisites..."

  # Node.js
  if ! command -v node &> /dev/null; then
    log_error "Node.js not found. Install from https://nodejs.org"
    exit 1
  fi
  log_info "Node.js: $(node --version)"

  # pnpm
  if ! command -v pnpm &> /dev/null; then
    log_warn "pnpm not found. Installing..."
    npm install -g pnpm
  fi
  log_info "pnpm: $(pnpm --version)"

  # Docker (optional)
  if ! $SKIP_DOCKER; then
    if ! command -v docker &> /dev/null; then
      log_error "Docker not found. Install or use --skip-docker"
      exit 1
    fi
    log_info "Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"

    if ! docker info &> /dev/null; then
      log_error "Docker daemon not running. Start Docker Desktop."
      exit 1
    fi
  fi
}

# Start Docker services
start_docker() {
  if $SKIP_DOCKER; then
    log_warn "Skipping Docker (--skip-docker)"
    return
  fi

  log_info "Starting Docker services..."

  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    docker-compose up -d
    log_info "Waiting for services to be ready..."
    sleep 5
  else
    log_warn "No docker-compose.yml found. Skipping."
  fi
}

# Install dependencies
install_deps() {
  log_info "Checking dependencies..."

  if [ ! -d "node_modules" ] || [ "package.json" -nt "node_modules" ]; then
    log_info "Installing dependencies..."
    pnpm install
  else
    log_info "Dependencies up to date."
  fi
}

# Run database migrations
run_migrations() {
  if $FRONTEND_ONLY; then
    return
  fi

  log_info "Running database migrations..."

  if [ -f "prisma/schema.prisma" ]; then
    pnpm db:migrate 2>/dev/null || pnpm prisma migrate dev 2>/dev/null || {
      log_warn "Migration command not found. Skipping."
    }
  else
    log_warn "No Prisma schema found. Skipping migrations."
  fi
}

# Health check
check_health() {
  local url=$1
  local name=$2
  local max_attempts=30
  local attempt=1

  log_info "Waiting for $name to be healthy..."

  while [ $attempt -le $max_attempts ]; do
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|204\|301\|302"; then
      log_info "$name is healthy!"
      return 0
    fi
    sleep 1
    ((attempt++))
  done

  log_warn "$name health check failed after ${max_attempts}s"
  return 1
}

# Start development servers
start_dev() {
  log_info "Starting development servers..."

  # Determine what to start
  if $BACKEND_ONLY; then
    log_info "Starting backend only..."
    pnpm dev:backend 2>/dev/null || pnpm --filter backend dev 2>/dev/null || {
      cd backend && pnpm dev
    }
  elif $FRONTEND_ONLY; then
    log_info "Starting frontend only..."
    pnpm dev:frontend 2>/dev/null || pnpm --filter frontend dev 2>/dev/null || {
      cd frontend && pnpm dev
    }
  else
    # Start both using common scripts
    if grep -q '"dev"' package.json 2>/dev/null; then
      pnpm dev
    else
      # Fallback: start backend and frontend separately
      log_info "Starting backend and frontend..."

      if [ -d "backend" ]; then
        (cd backend && pnpm dev) &
        BACKEND_PID=$!
      fi

      if [ -d "frontend" ]; then
        (cd frontend && pnpm dev) &
        FRONTEND_PID=$!
      fi

      # Wait for health
      sleep 3
      check_health "http://localhost:3000/health" "Backend" || true
      check_health "http://localhost:5173" "Frontend" || true

      log_info "Development servers started!"
      log_info "Backend: http://localhost:3000"
      log_info "Frontend: http://localhost:5173"

      # Wait for interrupt
      trap 'log_info "Shutting down..."; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null' EXIT
      wait
    fi
  fi
}

# Cleanup function
cleanup() {
  log_info "Cleaning up..."
  if ! $SKIP_DOCKER; then
    docker-compose down 2>/dev/null || true
  fi
}

# Main
main() {
  echo "========================================"
  echo "  Local Development Environment"
  echo "========================================"
  echo ""

  check_prereqs
  start_docker
  install_deps
  run_migrations
  start_dev
}

main
