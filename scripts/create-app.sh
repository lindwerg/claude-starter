#!/bin/bash
set -e

# Provide Starter Kit - Quick App Creator
# Создаёт полностью готовый проект одной командой
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/lindwerg/claude-starter/main/scripts/create-app.sh) my-app
#   или локально: ./scripts/create-app.sh my-app

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_step() { echo -e "${BLUE}[→]${NC} $1"; }

# Check project name
PROJECT_NAME="${1:-}"
if [ -z "$PROJECT_NAME" ]; then
  echo ""
  echo -e "${CYAN}╔═══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║       ${GREEN}Provide Starter Kit${CYAN}                 ║${NC}"
  echo -e "${CYAN}║   ${NC}Быстрое создание Full-Stack проекта${CYAN}   ║${NC}"
  echo -e "${CYAN}╚═══════════════════════════════════════════╝${NC}"
  echo ""
  echo "Usage: $0 <project-name>"
  echo ""
  echo "Пример:"
  echo "  $0 my-awesome-app"
  echo ""
  exit 1
fi

CLAUDE_DIR="$HOME/.claude"
REPO_URL="https://raw.githubusercontent.com/lindwerg/claude-starter/main"

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       ${GREEN}Provide Starter Kit${CYAN}                 ║${NC}"
echo -e "${CYAN}║   ${NC}Создаю проект: ${GREEN}$PROJECT_NAME${CYAN}${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Check and install global environment if needed
if [ ! -d "$CLAUDE_DIR/skills" ]; then
  log_step "Устанавливаю глобальное окружение..."

  # Download and run install.sh
  if command -v curl &>/dev/null; then
    bash <(curl -fsSL "$REPO_URL/install.sh")
  elif command -v wget &>/dev/null; then
    bash <(wget -qO- "$REPO_URL/install.sh")
  else
    log_error "Нужен curl или wget для загрузки"
    exit 1
  fi
else
  log_info "Глобальное окружение уже установлено"
fi

# Step 2: Check init-fullstack-project.sh exists
if [ ! -f "$CLAUDE_DIR/scripts/init-fullstack-project.sh" ]; then
  log_error "init-fullstack-project.sh не найден в $CLAUDE_DIR/scripts/"
  log_warn "Переустановите: bash <(curl -fsSL $REPO_URL/install.sh)"
  exit 1
fi

# Step 3: Create project directory
if [ -d "$PROJECT_NAME" ]; then
  log_error "Папка $PROJECT_NAME уже существует"
  exit 1
fi

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

log_step "Создаю проект в $(pwd)..."

# Step 4: Run init-fullstack-project.sh
bash "$CLAUDE_DIR/scripts/init-fullstack-project.sh" "$PROJECT_NAME"

# Step 5: Success message
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ Проект $PROJECT_NAME готов!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}Следующие шаги:${NC}"
echo ""
echo "     1. Перейди в проект:"
echo "        cd $PROJECT_NAME"
echo ""
echo "     2. Запусти Claude Code:"
echo "        claude"
echo ""
echo "     3. Начни workflow:"
echo -e "        ${GREEN}/workflow-init${NC}    → Инициализация BMAD"
echo -e "        ${GREEN}/product-brief${NC}    → Бизнес-требования"
echo -e "        ${GREEN}/prd${NC}              → Документ требований"
echo -e "        ${GREEN}/architecture${NC}     → Архитектура"
echo -e "        ${GREEN}/sprint-planning${NC}  → Планирование спринта"
echo -e "        ${GREEN}/ralph-loop${NC}       → Автономная разработка"
echo ""
echo -e "  ${CYAN}Разработка:${NC}"
echo ""
echo "     pnpm dev           # Запустить backend + frontend"
echo "     pnpm test          # Запустить тесты"
echo "     docker ps          # Проверить PostgreSQL + Redis"
echo ""
