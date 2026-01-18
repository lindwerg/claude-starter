---
name: advanced:workflow-init
description: "Инициализация workflow. Используй: 'workflow init', 'init workflow'"
allowed-tools: [Read, Write, Edit, Bash, Glob]
---

# Инициализация Workflow

Настройка Provide workflow в существующем проекте.

## Что это?

Создание конфигурации для Provide в проекте:
- `.bmad/` директория
- Конфигурационные файлы
- Status tracking

## Когда использовать?

- Добавляешь Provide в существующий проект
- Сбросить workflow status

## Как запустить?

```bash
/advanced:workflow-init
```

## Что создаётся?

```
.bmad/
├── config.yaml           # Настройки проекта
├── workflow-status.yaml  # Статус workflow
└── task-queue.yaml       # Очередь задач (пустая)
```

### config.yaml
```yaml
project_name: my-app
project_type: fullstack
project_level: 2  # 0=tiny, 1=small, 2=medium, 3=large
output_folder: docs
```

### workflow-status.yaml
```yaml
workflows:
  step1-init: null
  step2-brief: null
  step3-prd: null
  step4-arch: null
  step5-sprint: null
  step6-validate: null
  step7-build: null
```

## Результат

Проект готов к Provide workflow.
