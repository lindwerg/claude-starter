---
name: advanced:create-workflow
description: "Создание нового workflow. Используй: 'create workflow', 'новый workflow'"
allowed-tools: [Read, Write, Edit, Glob]
---

# Создание Workflow

Создание нового workflow/skill.

## Что это?

Scaffold для нового skill в `.claude/skills/`.

## Когда использовать?

- Нужен повторяемый процесс
- Автоматизация рутины

## Как запустить?

```bash
/advanced:create-workflow "имя-workflow"
```

## Структура

```
skill-name/
├── SKILL.md        # Инструкции (обязательно)
├── REFERENCE.md    # Детальная документация
├── scripts/        # Bash/Python скрипты
└── templates/      # Шаблоны документов
```

## SKILL.md Format

```yaml
---
name: skill-name
description: "Описание с trigger words"
allowed-tools: [Read, Write]
---

# Skill Name

Instructions...
```

## Результат

Готовый skill в `.claude/skills/{name}/`.
