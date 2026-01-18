---
name: ccexp
description: TUI explorer для Claude Code конфигураций (.claude/)
allowed-tools: [Bash]
---

# ccexp Skill

Используй `ccexp` для интерактивного исследования Claude Code конфигураций.

## Примеры

```bash
# Исследовать текущий проект
ccexp

# Исследовать другой проект
ccexp --path ~/projects/my-app

# Показать справку
ccexp --help

# Показать версию
ccexp --version
```

## Что показывает ccexp

TUI интерфейс отображает:
- `.claude/settings.json` - конфигурация хуков и разрешений
- `.claude/mcp_config.json` - MCP серверы
- `.claude/hooks/` - установленные хуки
- `.claude/skills/` - доступные skills
- `.claude/agents/` - определения агентов

## Когда использовать

- Нужно быстро понять структуру .claude/ директории
- Хочешь посмотреть какие хуки установлены
- Ищешь конкретную конфигурацию в проекте
- Дебаг проблем с настройками

## Требования

- Node.js (для npm) или Bun
- Установлен globally: `npm install -g ccexp`

## Примеры использования в Claude Code

```
User: "Покажи структуру .claude/ директории"
Claude: *Запускает ccexp в текущем проекте*

User: "Какие хуки установлены в моем проекте?"
Claude: *Использует ccexp для отображения конфигурации*
```

## Альтернативы

Если ccexp не установлен, можно использовать:
```bash
# Показать структуру
tree .claude/

# Список хуков
ls -la .claude/hooks/

# Показать settings
cat .claude/settings.json | jq .
```
