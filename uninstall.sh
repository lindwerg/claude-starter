#!/bin/bash
set -e

# Claude Starter Kit Uninstaller
# Removes installed components and optionally restores backup

CLAUDE_DIR="$HOME/.claude"
BACKUP_FILE="$HOME/.claude-starter-last-backup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
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

# Known starter kit files (to avoid removing user's own files)
# These are patterns that identify starter kit components
STARTER_KIT_MARKERS=(
  "# Claude Starter Kit"
  "# Installed by claude-starter"
)

# Print banner
print_banner() {
  echo ""
  echo -e "${CYAN}  ╔═══════════════════════════════════════╗${NC}"
  echo -e "${CYAN}  ║    Claude Starter Kit Uninstaller     ║${NC}"
  echo -e "${CYAN}  ╚═══════════════════════════════════════╝${NC}"
  echo ""
}

# Check if backup exists
check_backup() {
  if [ -f "$BACKUP_FILE" ]; then
    BACKUP_DIR=$(cat "$BACKUP_FILE")
    if [ -d "$BACKUP_DIR" ]; then
      log_info "Found backup: $BACKUP_DIR"
      return 0
    fi
  fi
  return 1
}

# List what will be removed
list_components() {
  echo ""
  echo "The following directories will be affected:"
  echo ""

  local components=("skills" "rules" "hooks" "commands" "agents" "templates" "scripts")

  for component in "${components[@]}"; do
    local dir="$CLAUDE_DIR/$component"
    if [ -d "$dir" ]; then
      local count=$(ls -1 "$dir" 2>/dev/null | wc -l | tr -d ' ')
      echo "  $dir/ ($count items)"
    fi
  done

  echo ""
}

# Prompt for confirmation
confirm_action() {
  local prompt="$1"
  local default="${2:-n}"

  if [ "$default" = "y" ]; then
    read -p "$prompt [Y/n]: " response
    response=${response:-y}
  else
    read -p "$prompt [y/N]: " response
    response=${response:-n}
  fi

  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

# Remove starter kit components
remove_components() {
  log_info "Removing starter kit components..."

  local components=("skills" "rules" "hooks" "commands" "agents" "templates" "scripts")
  local removed_count=0

  for component in "${components[@]}"; do
    local dir="$CLAUDE_DIR/$component"
    if [ -d "$dir" ]; then
      local count=$(ls -1 "$dir" 2>/dev/null | wc -l | tr -d ' ')
      if [ "$count" -gt 0 ]; then
        rm -rf "$dir"/*
        log_info "Cleared $component/ ($count items removed)"
        ((removed_count += count))
      fi
    fi
  done

  log_info "Total items removed: $removed_count"
}

# Remove entire .claude directory
remove_all() {
  log_warn "This will remove the entire ~/.claude directory!"
  echo ""

  if confirm_action "Are you sure you want to remove everything?"; then
    rm -rf "$CLAUDE_DIR"
    log_info "Removed $CLAUDE_DIR"

    # Clean up backup reference
    rm -f "$BACKUP_FILE"

    return 0
  fi

  return 1
}

# Restore from backup
restore_backup() {
  if ! check_backup; then
    log_error "No backup found to restore"
    return 1
  fi

  local backup_dir=$(cat "$BACKUP_FILE")

  echo ""
  log_info "Backup found: $backup_dir"
  echo ""

  if confirm_action "Restore from this backup?"; then
    # Remove current .claude
    rm -rf "$CLAUDE_DIR"

    # Restore backup
    cp -r "$backup_dir" "$CLAUDE_DIR"

    log_info "Restored from backup"

    # Ask about removing backup
    echo ""
    if confirm_action "Remove backup directory?"; then
      rm -rf "$backup_dir"
      rm -f "$BACKUP_FILE"
      log_info "Backup removed"
    else
      log_info "Backup preserved at: $backup_dir"
    fi

    return 0
  fi

  return 1
}

# Show menu
show_menu() {
  echo "What would you like to do?"
  echo ""
  echo "  1) Remove starter kit components (keep your custom files)"
  echo "  2) Remove everything (~/.claude directory)"
  echo "  3) Restore from backup"
  echo "  4) Cancel"
  echo ""
  read -p "Select option [1-4]: " choice

  case "$choice" in
    1)
      list_components
      if confirm_action "Proceed with removal?"; then
        remove_components
        echo ""
        log_info "Starter kit components removed"
        log_info "Restart Claude Code to apply changes"
      else
        log_info "Cancelled"
      fi
      ;;
    2)
      if remove_all; then
        echo ""
        log_info "Claude configuration removed"
        log_info "Restart Claude Code to start fresh"
      else
        log_info "Cancelled"
      fi
      ;;
    3)
      if restore_backup; then
        echo ""
        log_info "Configuration restored"
        log_info "Restart Claude Code to apply changes"
      fi
      ;;
    4|*)
      log_info "Cancelled"
      exit 0
      ;;
  esac
}

# Parse command line arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --components|-c)
        # Remove only components
        list_components
        if confirm_action "Proceed with removal?"; then
          remove_components
        fi
        exit 0
        ;;
      --all|-a)
        # Remove everything
        remove_all
        exit 0
        ;;
      --restore|-r)
        # Restore from backup
        restore_backup
        exit 0
        ;;
      --force|-f)
        # Skip confirmations (for scripting)
        FORCE=true
        ;;
      --help|-h)
        echo "Claude Starter Kit Uninstaller"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  -c, --components  Remove starter kit components only"
        echo "  -a, --all         Remove entire ~/.claude directory"
        echo "  -r, --restore     Restore from backup"
        echo "  -f, --force       Skip confirmation prompts"
        echo "  -h, --help        Show this help message"
        echo ""
        echo "Without options, shows interactive menu."
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
    shift
  done
}

# Override confirm for force mode
FORCE=false
confirm_action() {
  if [ "$FORCE" = true ]; then
    return 0
  fi

  local prompt="$1"
  local default="${2:-n}"

  if [ "$default" = "y" ]; then
    read -p "$prompt [Y/n]: " response
    response=${response:-y}
  else
    read -p "$prompt [y/N]: " response
    response=${response:-n}
  fi

  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

# Main
main() {
  print_banner

  # Check if .claude exists
  if [ ! -d "$CLAUDE_DIR" ]; then
    log_warn "No ~/.claude directory found"

    if check_backup; then
      if confirm_action "Would you like to restore from backup?"; then
        restore_backup
      fi
    fi

    exit 0
  fi

  # Parse arguments or show menu
  if [ $# -gt 0 ]; then
    parse_args "$@"
  else
    show_menu
  fi
}

main "$@"
