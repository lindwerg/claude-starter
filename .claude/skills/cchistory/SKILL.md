---
name: cchistory
description: Извлечение shell команд из прошлых Claude Code сессий
allowed-tools: [Bash]
---

# cchistory Skill

Используй `cchistory` для поиска команд, которые выполнялись в прошлых сессиях.

## Примеры

```bash
# Все команды текущего проекта
cchistory

# История всех проектов
cchistory --global

# Список проектов
cchistory --list-projects

# История конкретного проекта
cchistory my-app

# Поиск docker команд
cchistory | grep docker

# Поиск npm команд
cchistory | grep "npm install"

# Последние 20 команд
cchistory | tail -20

# Все git команды
cchistory | grep git
```

## Когда использовать

- Нужно вспомнить команду, которая использовалась ранее
- Хочешь посмотреть какие docker команды запускались
- Ищешь последовательность команд для setup
- Анализируешь историю npm install для понимания зависимостей

## Требования

- Node.js 20+
- Установлен globally: `npm install -g cchistory`
- История сессий в `~/.claude/projects/` (сохраняется ~30 дней)

## Примеры использования в Claude Code

```
User: "Какие docker команды я использовал для запуска БД?"
Claude: *Использует cchistory | grep docker*

User: "Покажи все команды для настройки проекта"
Claude: *Использует cchistory | head -50*
```
