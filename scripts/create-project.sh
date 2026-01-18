#!/bin/bash
set -e

# Цвета
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}   🚀 Create Project from Claude Starter${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo

# Проверка gh CLI
if ! command -v gh &> /dev/null; then
  echo -e "${RED}❌ GitHub CLI (gh) not found. Install: brew install gh${NC}"
  exit 1
fi

# Проверка авторизации gh
if ! gh auth status &> /dev/null; then
  echo -e "${RED}❌ Not logged in to GitHub. Run: gh auth login${NC}"
  exit 1
fi

# 1. Имя проекта
read -p "📁 Project name: " PROJECT_NAME
if [ -z "$PROJECT_NAME" ]; then
  echo -e "${RED}❌ Project name required${NC}"
  exit 1
fi

# Валидация имени (только буквы, цифры, дефисы)
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo -e "${RED}❌ Invalid name. Use only letters, numbers, hyphens, underscores${NC}"
  exit 1
fi

# 2. Описание
read -p "📝 Description (optional): " DESCRIPTION

# 3. Visibility
echo "🔒 Repository visibility:"
echo "  1) private (default)"
echo "  2) public"
read -p "Choose [1/2]: " VISIBILITY_CHOICE
VISIBILITY="--private"
[ "$VISIBILITY_CHOICE" = "2" ] && VISIBILITY="--public"

# 4. Директория для проекта
read -p "📂 Parent directory [~/Desktop]: " PARENT_DIR
PARENT_DIR="${PARENT_DIR:-$HOME/Desktop}"

# Расширить ~ в путь
PARENT_DIR="${PARENT_DIR/#\~/$HOME}"

# Проверить что директория существует
if [ ! -d "$PARENT_DIR" ]; then
  echo -e "${RED}❌ Directory does not exist: $PARENT_DIR${NC}"
  exit 1
fi

# Проверить что проект не существует
if [ -d "$PARENT_DIR/$PROJECT_NAME" ]; then
  echo -e "${RED}❌ Directory already exists: $PARENT_DIR/$PROJECT_NAME${NC}"
  exit 1
fi

# Подтверждение
echo
echo -e "${YELLOW}Will create:${NC}"
echo "  Name: $PROJECT_NAME"
echo "  Path: $PARENT_DIR/$PROJECT_NAME"
echo "  Visibility: ${VISIBILITY#--}"
[ -n "$DESCRIPTION" ] && echo "  Description: $DESCRIPTION"
echo
read -p "Continue? [Y/n]: " CONFIRM
[ "$CONFIRM" = "n" ] && exit 0

# 5. Клонирование starter с GitHub
echo -e "\n${GREEN}[1/5]${NC} Cloning claude-starter from GitHub..."
git clone -q --depth 1 https://github.com/lindwerg/claude-starter.git "$PARENT_DIR/$PROJECT_NAME"
cd "$PARENT_DIR/$PROJECT_NAME"

# Удаляем .git от клона
rm -rf .git

# 6. Инициализация git
echo -e "${GREEN}[2/5]${NC} Initializing fresh git repo..."
git init -q
git add .
git commit -q -m "init: bootstrap from claude-starter"

# 7. Создание GitHub репо
echo -e "${GREEN}[3/5]${NC} Creating GitHub repository..."
if [ -n "$DESCRIPTION" ]; then
  gh repo create "$PROJECT_NAME" $VISIBILITY --source=. --push --description "$DESCRIPTION"
else
  gh repo create "$PROJECT_NAME" $VISIBILITY --source=. --push
fi

# 8. Готово
GH_USER=$(gh api user -q .login)
echo -e "\n${GREEN}[4/5]${NC} ✅ Project created successfully!"
echo -e "  📁 $PARENT_DIR/$PROJECT_NAME"
echo -e "  🔗 https://github.com/$GH_USER/$PROJECT_NAME"

# 9. Запуск Claude
echo -e "\n${GREEN}[5/5]${NC} Starting Claude Code (bypass permissions mode)..."
echo -e "${YELLOW}Tip: Run /bmad:product-brief to start BMAD workflow${NC}"
echo
exec claude --dangerously-skip-permissions
