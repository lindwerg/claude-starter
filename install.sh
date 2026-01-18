#!/bin/bash
set -e

# Provide Starter Kit Installer
# Автономная разработка full-stack приложений с Claude Code

REPO_URL="https://github.com/lindwerg/claude-starter"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$HOME/.claude-backup-$(date +%Y%m%d%H%M%S)"
TEMP_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# 1. Check prerequisites
check_prerequisites() {
  log_step "Проверяю зависимости..."

  if ! command -v node &> /dev/null; then
    log_error "Node.js не найден."
    echo "    Установи: https://nodejs.org/"
    exit 1
  fi

  if ! command -v git &> /dev/null; then
    log_error "Git не найден."
    echo "    Установи: https://git-scm.com/"
    exit 1
  fi

  log_info "Node.js $(node --version)"
  log_info "Git $(git --version | cut -d' ' -f3)"

  if ! command -v jq &> /dev/null; then
    log_warn "jq не найден — settings будут заменены, не объединены"
    echo "    Установи: brew install jq (macOS) или apt install jq (Linux)"
  fi

  # Check for Claude Code
  if ! command -v claude &> /dev/null; then
    log_warn "Claude Code не найден"
    echo "    Установи: npm install -g @anthropic-ai/claude-code"
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
    log_info "Существующий ~/.claude не найден — чистая установка"
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

# 4. Install skills, rules, hooks, commands, agents
install_components() {
  log_step "Устанавливаю компоненты..."

  # Create directories
  mkdir -p "$CLAUDE_DIR"/{skills,rules,hooks,commands,agents,templates,scripts,orchestrator}

  # Copy components (don't overwrite existing files)
  local components=("skills" "rules" "hooks" "commands" "agents" "orchestrator")

  for component in "${components[@]}"; do
    local src_dir="$TEMP_DIR/claude-starter/.claude/$component"
    local dst_dir="$CLAUDE_DIR/$component"

    if [ -d "$src_dir" ] && [ "$(ls -A "$src_dir" 2>/dev/null)" ]; then
      local count=0
      for file in "$src_dir"/*; do
        local filename=$(basename "$file")
        if [ ! -e "$dst_dir/$filename" ]; then
          cp -r "$file" "$dst_dir/"
          ((count++))
        fi
      done
      if [ $count -gt 0 ]; then
        log_info "Установлено $count новых $component"
      fi
    fi
  done

  # Make hook scripts executable
  chmod +x "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true

  # Make orchestrator scripts executable (Ralph)
  chmod +x "$CLAUDE_DIR/orchestrator/ralph" 2>/dev/null || true
  chmod +x "$CLAUDE_DIR/orchestrator/lib/"*.sh 2>/dev/null || true
}

# 5. Merge settings.json
merge_settings() {
  local src_settings="$TEMP_DIR/claude-starter/.claude/settings.json"
  local dst_settings="$CLAUDE_DIR/settings.json"

  if [ ! -f "$src_settings" ]; then
    log_warn "settings.json не найден в starter kit"
    return
  fi

  if command -v jq &> /dev/null && [ -f "$dst_settings" ]; then
    log_step "Объединяю settings.json..."

    jq -s 'reduce .[] as $item ({}; . * $item)' \
      "$src_settings" \
      "$dst_settings" \
      > "$CLAUDE_DIR/settings.merged.json"

    mv "$CLAUDE_DIR/settings.merged.json" "$dst_settings"
    log_info "Settings объединены"
  else
    if [ -f "$dst_settings" ]; then
      log_warn "Существующий settings.json сохранён"
    else
      cp "$src_settings" "$dst_settings"
      log_info "Settings установлен"
    fi
  fi
}

# 6. Merge mcp_config.json
merge_mcp() {
  local src_mcp="$TEMP_DIR/claude-starter/.claude/mcp_config.json"
  local dst_mcp="$CLAUDE_DIR/mcp_config.json"

  if [ ! -f "$src_mcp" ]; then
    log_warn "mcp_config.json не найден"
    return
  fi

  if command -v jq &> /dev/null && [ -f "$dst_mcp" ]; then
    log_step "Объединяю mcp_config.json..."

    jq -s '.[0].mcpServers as $src | .[1].mcpServers as $dst | {mcpServers: ($src + $dst)}' \
      "$src_mcp" "$dst_mcp" > "$CLAUDE_DIR/mcp_config.merged.json"

    mv "$CLAUDE_DIR/mcp_config.merged.json" "$dst_mcp"
    log_info "MCP config объединён"
  else
    if [ -f "$dst_mcp" ]; then
      log_warn "Существующий mcp_config.json сохранён"
    else
      cp "$src_mcp" "$dst_mcp"
      log_info "MCP config установлен"
    fi
  fi
}

# 7. Install templates and scripts
install_templates() {
  local src_templates="$TEMP_DIR/claude-starter/templates"
  local src_scripts="$TEMP_DIR/claude-starter/scripts"

  if [ -d "$src_templates" ] && [ "$(ls -A "$src_templates" 2>/dev/null)" ]; then
    cp -rn "$src_templates/"* "$CLAUDE_DIR/templates/" 2>/dev/null || true
    log_info "Шаблоны установлены"
  fi

  if [ -d "$src_scripts" ] && [ "$(ls -A "$src_scripts" 2>/dev/null)" ]; then
    cp -rn "$src_scripts/"* "$CLAUDE_DIR/scripts/" 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/scripts/"*.sh 2>/dev/null || true
    log_info "Скрипты установлены"
  fi
}

# 8. Install CLAUDE.md template if not exists
install_claude_md() {
  local src_claude_md="$TEMP_DIR/claude-starter/CLAUDE.md"
  local dst_claude_md="$CLAUDE_DIR/CLAUDE.md"

  if [ -f "$src_claude_md" ] && [ ! -f "$dst_claude_md" ]; then
    cp "$src_claude_md" "$dst_claude_md"
    log_info "CLAUDE.md установлен"
  elif [ -f "$dst_claude_md" ]; then
    log_info "Существующий CLAUDE.md сохранён"
  fi
}

# 9. Install TDD Guard globally
install_tdd_guard() {
  if ! command -v tdd-guard &> /dev/null; then
    log_step "Устанавливаю TDD Guard глобально..."
    npm install -g tdd-guard 2>/dev/null || log_warn "Не удалось установить tdd-guard"
    if command -v tdd-guard &> /dev/null; then
      log_info "TDD Guard установлен"
    fi
  else
    log_info "TDD Guard уже установлен"
  fi
}

# 10. Install Provide workflows (replaces BMAD)
install_provide() {
  log_step "Устанавливаю Provide workflows..."

  # Copy provide skills (main workflow)
  local provide_src="$TEMP_DIR/claude-starter/.claude/skills/provide"
  local provide_dst="$CLAUDE_DIR/skills/provide"

  if [ -d "$provide_src" ]; then
    mkdir -p "$provide_dst"
    cp -r "$provide_src/"* "$provide_dst/" 2>/dev/null || true
    log_info "Основные шаги (step1-step7) установлены"
  fi

  # Copy advanced skills
  local advanced_src="$TEMP_DIR/claude-starter/.claude/skills/advanced"
  local advanced_dst="$CLAUDE_DIR/skills/advanced"

  if [ -d "$advanced_src" ]; then
    mkdir -p "$advanced_dst"
    cp -r "$advanced_src/"* "$advanced_dst/" 2>/dev/null || true
    log_info "Advanced команды установлены"
  fi

  # Copy help skill
  local help_src="$TEMP_DIR/claude-starter/.claude/skills/help"
  local help_dst="$CLAUDE_DIR/skills/help"

  if [ -d "$help_src" ]; then
    mkdir -p "$help_dst"
    cp -r "$help_src/"* "$help_dst/" 2>/dev/null || true
    log_info "/help установлен"
  fi
}

# 10. Cleanup
cleanup() {
  if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}

# Handle script interruption
trap cleanup EXIT

# Print banner
print_banner() {
  echo ""
  echo -e "${CYAN}  ╔═══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}  ║       ${GREEN}Provide Starter Kit${CYAN}                 ║${NC}"
  echo -e "${CYAN}  ║   ${NC}Автономная разработка с Claude Code${CYAN}   ║${NC}"
  echo -e "${CYAN}  ╚═══════════════════════════════════════════╝${NC}"
  echo ""
}

# Print success message
print_success() {
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}  ✅ Provide Starter Kit установлен!${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${CYAN}📚 Быстрый старт:${NC}"
  echo ""
  echo "     1. Создай папку проекта:"
  echo "        mkdir my-app && cd my-app"
  echo ""
  echo "     2. Запусти Claude Code:"
  echo "        claude"
  echo ""
  echo "     3. Выполни команды по порядку:"
  echo ""
  echo -e "  ${CYAN}📖 Полный цикл разработки:${NC}"
  echo ""
  echo -e "     ${GREEN}/init-project${NC}     → Создание структуры проекта"
  echo -e "     ${GREEN}/workflow-init${NC}    → Инициализация BMAD"
  echo -e "     ${GREEN}/product-brief${NC}    → Бизнес-анализ требований"
  echo -e "     ${GREEN}/prd${NC}              → Документ требований (PRD)"
  echo -e "     ${GREEN}/architecture${NC}     → Техническая архитектура"
  echo -e "     ${GREEN}/sprint-planning${NC}  → Планирование спринта"
  echo -e "     ${GREEN}/validate-sprint${NC}  → Валидация + очередь задач"
  echo -e "     ${GREEN}/ralph-loop${NC}       → Автономная разработка"
  echo ""
  echo -e "  ${CYAN}💡 Подсказка:${NC} используй /help для справки"
  echo ""
  echo -e "  ${CYAN}📁 Установлено в:${NC} $CLAUDE_DIR"
  if [ -f "$HOME/.claude-starter-last-backup" ]; then
    echo -e "  ${CYAN}📦 Backup:${NC}        $(cat "$HOME/.claude-starter-last-backup")"
  fi
  echo ""
}

# Main
main() {
  print_banner
  check_prerequisites
  backup_existing
  clone_repo
  install_components
  merge_settings
  merge_mcp
  install_templates
  install_claude_md
  install_tdd_guard    # Install TDD Guard globally
  install_provide      # Install Provide workflows
  print_success
}

main "$@"
