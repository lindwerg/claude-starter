#!/bin/bash
set -e

# Claude Starter Kit Installer
# Installs skills, rules, hooks, commands, and agents to ~/.claude/

REPO_URL="https://github.com/lindwerg/claude-starter"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$HOME/.claude-backup-$(date +%Y%m%d%H%M%S)"
TEMP_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# 1. Check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."

  if ! command -v node &> /dev/null; then
    log_error "Node.js is required but not installed."
    echo "Install from: https://nodejs.org/"
    exit 1
  fi

  if ! command -v git &> /dev/null; then
    log_error "Git is required but not installed."
    echo "Install from: https://git-scm.com/"
    exit 1
  fi

  log_info "Node.js $(node --version) found"
  log_info "Git $(git --version | cut -d' ' -f3) found"

  if ! command -v jq &> /dev/null; then
    log_warn "jq not found - settings will be replaced instead of merged"
    log_warn "Install jq for smart merging: brew install jq (macOS) or apt install jq (Linux)"
  fi
}

# 2. Backup existing config
backup_existing() {
  if [ -d "$CLAUDE_DIR" ]; then
    log_info "Backing up existing ~/.claude to $BACKUP_DIR"
    cp -r "$CLAUDE_DIR" "$BACKUP_DIR"
    echo "$BACKUP_DIR" > "$HOME/.claude-starter-last-backup"
    log_info "Backup created: $BACKUP_DIR"
  else
    log_info "No existing ~/.claude directory found"
  fi
}

# 3. Clone repo with submodules
clone_repo() {
  log_info "Cloning claude-starter repository..."
  TEMP_DIR=$(mktemp -d)

  if git clone --depth 1 --recurse-submodules "$REPO_URL" "$TEMP_DIR/claude-starter" 2>/dev/null; then
    log_info "Repository cloned successfully"
  else
    log_error "Failed to clone repository from $REPO_URL"
    exit 1
  fi
}

# 4. Install skills, rules, hooks, commands, agents
install_components() {
  log_info "Installing components..."

  # Create directories
  mkdir -p "$CLAUDE_DIR"/{skills,rules,hooks,commands,agents,templates,scripts}

  # Copy components (don't overwrite existing files)
  local components=("skills" "rules" "hooks" "commands" "agents")

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
      log_info "Installed $count new $component"
    fi
  done

  # Make hook scripts executable
  chmod +x "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true
}

# 5. Merge settings.json
merge_settings() {
  local src_settings="$TEMP_DIR/claude-starter/.claude/settings.json"
  local dst_settings="$CLAUDE_DIR/settings.json"

  if [ ! -f "$src_settings" ]; then
    log_warn "No settings.json in starter kit"
    return
  fi

  if command -v jq &> /dev/null && [ -f "$dst_settings" ]; then
    log_info "Merging settings.json (preserving your existing settings)..."

    # Deep merge: existing settings take precedence, new ones are added
    jq -s 'reduce .[] as $item ({}; . * $item)' \
      "$src_settings" \
      "$dst_settings" \
      > "$CLAUDE_DIR/settings.merged.json"

    mv "$CLAUDE_DIR/settings.merged.json" "$dst_settings"
    log_info "Settings merged successfully"
  else
    if [ -f "$dst_settings" ]; then
      log_warn "Existing settings.json preserved (install jq for smart merging)"
    else
      cp "$src_settings" "$dst_settings"
      log_info "Settings installed"
    fi
  fi
}

# 6. Merge mcp_config.json
merge_mcp() {
  local src_mcp="$TEMP_DIR/claude-starter/.claude/mcp_config.json"
  local dst_mcp="$CLAUDE_DIR/mcp_config.json"

  if [ ! -f "$src_mcp" ]; then
    log_warn "No mcp_config.json in starter kit"
    return
  fi

  if command -v jq &> /dev/null && [ -f "$dst_mcp" ]; then
    log_info "Merging mcp_config.json (preserving your existing servers)..."

    # Merge mcpServers objects (existing takes precedence)
    jq -s '.[0].mcpServers as $src | .[1].mcpServers as $dst | {mcpServers: ($src + $dst)}' \
      "$src_mcp" "$dst_mcp" > "$CLAUDE_DIR/mcp_config.merged.json"

    mv "$CLAUDE_DIR/mcp_config.merged.json" "$dst_mcp"
    log_info "MCP config merged successfully"
  else
    if [ -f "$dst_mcp" ]; then
      log_warn "Existing mcp_config.json preserved (install jq for smart merging)"
    else
      cp "$src_mcp" "$dst_mcp"
      log_info "MCP config installed"
    fi
  fi
}

# 7. Install templates and scripts
install_templates() {
  local src_templates="$TEMP_DIR/claude-starter/templates"
  local src_scripts="$TEMP_DIR/claude-starter/scripts"

  if [ -d "$src_templates" ] && [ "$(ls -A "$src_templates" 2>/dev/null)" ]; then
    cp -rn "$src_templates/"* "$CLAUDE_DIR/templates/" 2>/dev/null || true
    log_info "Templates installed"
  fi

  if [ -d "$src_scripts" ] && [ "$(ls -A "$src_scripts" 2>/dev/null)" ]; then
    cp -rn "$src_scripts/"* "$CLAUDE_DIR/scripts/" 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/scripts/"*.sh 2>/dev/null || true
    log_info "Scripts installed"
  fi
}

# 8. Install CLAUDE.md template if not exists
install_claude_md() {
  local src_claude_md="$TEMP_DIR/claude-starter/CLAUDE.md"
  local dst_claude_md="$CLAUDE_DIR/CLAUDE.md"

  if [ -f "$src_claude_md" ] && [ ! -f "$dst_claude_md" ]; then
    cp "$src_claude_md" "$dst_claude_md"
    log_info "CLAUDE.md template installed"
  elif [ -f "$dst_claude_md" ]; then
    log_info "Existing CLAUDE.md preserved"
  fi
}

# 9. Install BMAD Method
install_bmad() {
  local bmad_dir="$CLAUDE_DIR/skills/bmad"
  local bmad_installer="$bmad_dir/install-v6.sh"

  if [ -f "$bmad_installer" ]; then
    log_info "Installing BMAD Method v6..."
    cd "$bmad_dir" && bash install-v6.sh
    cd - > /dev/null
    log_info "BMAD Method installed"
  else
    log_warn "BMAD installer not found, skipping"
  fi
}

# 10. Cleanup
cleanup() {
  if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
    log_info "Cleaned up temporary files"
  fi
}

# Handle script interruption
trap cleanup EXIT

# Print banner
print_banner() {
  echo ""
  echo "  ╔═══════════════════════════════════════╗"
  echo "  ║     Claude Starter Kit Installer      ║"
  echo "  ╚═══════════════════════════════════════╝"
  echo ""
}

# Print success message
print_success() {
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}  Installation complete!${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "  Restart Claude Code to apply changes."
  echo ""
  echo "  Quick Start (New Project):"
  echo "    mkdir my-app && cd my-app"
  echo "    /init-project              # FSD + VSA structure"
  echo "    /ralph-loop                # Autonomous dev loop"
  echo ""
  echo "  BMAD Workflow (Architecture):"
  echo "    /workflow-init             # Init BMAD in project"
  echo "    /product-brief             # Business requirements"
  echo "    /prd                       # Product spec"
  echo "    /architecture              # System design"
  echo "    /sprint-planning           # Break into stories"
  echo ""
  echo "  Installed to: $CLAUDE_DIR"
  if [ -f "$HOME/.claude-starter-last-backup" ]; then
    echo "  Backup at:    $(cat "$HOME/.claude-starter-last-backup")"
  fi
  echo ""
}

# 11. Override BMAD commands with our custom versions (FSD+VSA)
install_custom_commands() {
  log_info "Installing custom commands (FSD+VSA overrides)..."

  # Copy our architecture.md AFTER bmad to override it
  local src_arch="$TEMP_DIR/claude-starter/.claude/commands/architecture.md"
  if [ -f "$src_arch" ]; then
    cp -f "$src_arch" "$CLAUDE_DIR/commands/architecture.md"
    log_info "Custom /architecture with FSD+VSA installed"
  fi
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
  install_bmad
  install_custom_commands  # AFTER bmad to override
  print_success
}

main "$@"
