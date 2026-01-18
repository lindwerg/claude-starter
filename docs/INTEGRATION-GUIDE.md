# Integration Guide: Quality Enforcement Tools

Руководство по интеграции инструментов из awesome-claude-code в проекты на основе claude-starter.

## Установленные инструменты

### ✅ Глобальные утилиты
- **TDD Guard** (`npm install -g tdd-guard`) - TDD принципы enforcement
- **cchistory** (`npm install -g cchistory`) - история команд из сессий
- **ccexp** (`npm install -g ccexp`) - TUI explorer конфигураций

### ✅ Локальные инструменты
- **cchooks** (Python SDK) - генератор хуков
- **TypeScript Quality Hooks** - проверка strict mode

## 1. TDD Guard Integration

### Установка в проект

```bash
# В root проекта
npm install --save-dev tdd-guard-vitest
```

### Конфигурация vitest.config.ts

```typescript
import { defineConfig } from 'vitest/config';
import { VitestReporter } from 'tdd-guard-vitest';

export default defineConfig({
  test: {
    reporters: [
      'default',
      new VitestReporter(process.cwd()),
    ],
    // ... остальные настройки
  },
});
```

### Регистрация хуков в .claude/settings.json

Добавьте в секцию `hooks`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "tdd-guard",
            "timeout": 10000
          }
        ]
      },
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "tdd-guard",
            "timeout": 10000
          }
        ]
      },
      {
        "matcher": "MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "tdd-guard",
            "timeout": 10000
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "tdd-guard"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "tdd-guard"
          }
        ]
      },
      {
        "matcher": "resume",
        "hooks": [
          {
            "type": "command",
            "command": "tdd-guard"
          }
        ]
      },
      {
        "matcher": "clear",
        "hooks": [
          {
            "type": "command",
            "command": "tdd-guard"
          }
        ]
      }
    ]
  }
}
```

## 2. TypeScript Quality Hooks

### Уже установлено в claude-starter

Файлы скопированы в `.claude/hooks/`:
- `quality-check.js` - основной скрипт проверки
- `hook-config.json` - конфигурация правил

### Регистрация в .claude/settings.json

Добавьте в `PostToolUse`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/quality-check.js",
            "timeout": 15000
          }
        ]
      },
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/quality-check.js",
            "timeout": 15000
          }
        ]
      },
      {
        "matcher": "MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/quality-check.js",
            "timeout": 15000
          }
        ]
      }
    ]
  }
}
```

### Настройка правил

Отредактируйте `.claude/hooks/hook-config.json`:

```json
{
  "typescript": {
    "enabled": true
  },
  "eslint": {
    "enabled": true,
    "autofix": true
  },
  "prettier": {
    "enabled": true,
    "autofix": true
  },
  "rules": {
    "anyType": {
      "enabled": true,
      "severity": "error",
      "message": "Forbidden: 'any' type"
    },
    "asUnknown": {
      "enabled": true,
      "severity": "error",
      "message": "Forbidden: 'as unknown as T'"
    },
    "nonNullAssertion": {
      "enabled": true,
      "severity": "error",
      "message": "Forbidden: '!' non-null assertion"
    }
  }
}
```

## 3. cchooks SDK - Генератор хуков

### Использование

```bash
# Создать новый hook
.claude/hooks/sdk/create-hook.py \
  --name my-custom-hook \
  --event PreToolUse \
  --tool Write

# Создаст:
# - .claude/hooks/my-custom-hook.py
# - .claude/hooks/my-custom-hook.sh

# Зарегистрировать в settings.json согласно output генератора
```

### Пример кастомного хука

```python
#!/usr/bin/env python3
from cchooks import create_context

c = create_context()

# Блокировать запись в .env файлы
if c.tool_name == "Write" and ".env" in c.tool_input.get("file_path", ""):
    c.output.deny(reason="Запрещено редактировать .env файлы напрямую")
else:
    c.output.exit_success()
```

## 4. CLI Утилиты

### cchistory - История команд

```bash
# Просмотр истории текущего проекта
cchistory

# Глобальная история
cchistory --global

# Поиск команд
cchistory | grep docker
cchistory | grep "npm install"
```

### ccexp - Config Explorer

```bash
# TUI для текущего проекта
ccexp

# Конкретный проект
ccexp --path ~/my-project
```

## Проверка установки

```bash
# Проверить TDD Guard
which tdd-guard && echo "✓ TDD Guard installed"

# Проверить cchistory
which cchistory && echo "✓ cchistory installed"

# Проверить ccexp
which ccexp && echo "✓ ccexp installed"

# Проверить cchooks
uv pip list | grep cchooks && echo "✓ cchooks installed"

# Проверить TypeScript Quality Hooks
ls -la .claude/hooks/quality-check.js && echo "✓ TS Quality Hooks installed"
```

## Troubleshooting

### TDD Guard ошибка "Unexpected end of JSON input"

Это нормально при запуске без stdin. Hook будет работать корректно при фактическом использовании Claude Code.

### recall не установился

Требует обновления Xcode Command Line Tools:
```bash
sudo rm -rf /Library/Developer/CommandLineTools
sudo xcode-select --install
```

Или установить через cargo:
```bash
cargo install --git https://github.com/zippoxer/recall
```

## Следующие шаги

1. Настроить хуки в `.claude/settings.json` согласно этому гайду
2. Обновить templates/project с TDD Guard reporter
3. Создать skills для cchistory и ccexp в `.claude/skills/`
4. Запустить integration test

## Ресурсы

- [TDD Guard](https://github.com/nizos/tdd-guard)
- [TypeScript Quality Hooks](https://github.com/bartolli/claude-code-typescript-hooks)
- [cchooks SDK](https://github.com/GowayLee/cchooks)
- [cchistory](https://github.com/eckardt/cchistory)
- [ccexp](https://github.com/nyatinte/ccexp)
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
