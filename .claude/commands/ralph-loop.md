# /ralph-loop

Автономный цикл реализации stories с использованием специализированных субагентов.

## Описание

RALPH (Recursive Autonomous Loop for Production Handoffs) — паттерн автономной реализации,
где каждая story проходит через цепочку специализированных агентов. Каждый агент отвечает
за свою часть: API дизайн, backend, frontend, тесты, DevOps, валидация.

**Ключевая идея:** Main context остаётся чистым, вся тяжёлая работа выполняется субагентами.

## Входные параметры

- `$STORY_PATH` — путь к story или директории со stories (по умолчанию `docs/stories/`)
- `$MAX_RETRIES` — максимум попыток при failure (по умолчанию 3)
- `$AUTO_COMMIT` — автоматический commit при успехе (по умолчанию true)

## Workflow

### 1. Чтение Backlog

```
Читаем stories из docs/stories/:
├── STORY-001-auth.md
├── STORY-002-users.md
└── STORY-003-products.md
```

Каждая story должна содержать:
- **Acceptance Criteria** — что считается done
- **Technical Notes** — ограничения, зависимости
- **Priority** — порядок выполнения

### 2. Для каждой Story → Субагенты

#### 2.1 API Agent
**Задача:** Обновить `openapi.yaml`
```
- Анализирует story requirements
- Добавляет/обновляет endpoints в openapi.yaml
- Валидирует OpenAPI spec
- Output: обновлённый openapi.yaml
```

#### 2.2 Backend Agent
**Задача:** Реализовать VSA slice
```
- Создаёт feature slice: controller, service, repository, schema
- Реализует бизнес-логику
- Добавляет Zod валидацию
- Обновляет Prisma schema при необходимости
- Output: готовый backend код
```

#### 2.3 Frontend Agent
**Задача:** Реализовать FSD компоненты
```
- Генерирует API types из openapi.yaml
- Создаёт entities, features, widgets
- Реализует UI компоненты
- Подключает TanStack Query
- Output: готовый frontend код
```

#### 2.4 Test Agent
**Задача:** Написать тесты
```
- Unit тесты для services
- Integration тесты для API
- Component тесты для React
- E2E smoke тесты
- Output: полное покрытие тестами
```

#### 2.5 DevOps Agent
**Задача:** Обновить инфраструктуру
```
- Обновить Docker конфиги если нужно
- Добавить миграции
- Обновить CI/CD если нужно
- Output: готовая инфраструктура
```

#### 2.6 Validation Agent
**Задача:** Финальная проверка
```
- Запустить все линтеры
- Запустить все тесты
- Проверить type-check
- Проверить build
- Валидировать архитектуру (FSD/VSA)
- Output: pass/fail с детальным отчётом
```

### 3. При успехе → Commit

```bash
git add .
git commit -m "feat($FEATURE): implement $STORY_ID"
```

Story перемещается в `docs/stories/done/`

### 4. При failure → Retry

```
Attempt 1: FAIL (test failures)
  → Анализ ошибок
  → Spawn Fix Agent
  → Re-run Validation Agent

Attempt 2: FAIL (type errors)
  → Анализ ошибок
  → Spawn Fix Agent
  → Re-run Validation Agent

Attempt 3: SUCCESS
  → Commit
```

При 3 неудачных попытках:
- Story помечается как BLOCKED
- Создаётся handoff документ с описанием проблемы
- Переход к следующей story

## Output

```xml
<promise>COMPLETE</promise>
```

Также создаётся отчёт `docs/ralph-report-{timestamp}.md`:
```markdown
# RALPH Run Report

## Summary
- Stories processed: 5
- Successful: 4
- Blocked: 1
- Total time: 45 min

## Details
| Story | Status | Attempts | Notes |
|-------|--------|----------|-------|
| STORY-001 | DONE | 1 | — |
| STORY-002 | DONE | 2 | Fixed type errors |
| STORY-003 | BLOCKED | 3 | Prisma migration conflict |
```

## Примеры использования

### Обработать все stories
```
/ralph-loop
```

### Обработать конкретную story
```
/ralph-loop docs/stories/STORY-001-auth.md
```

### Без автокоммита
```
/ralph-loop --no-commit
```

### С увеличенным retry
```
/ralph-loop --max-retries 5
```

## Критерии остановки

- Все stories обработаны
- Достигнут лимит времени (если задан)
- Критическая ошибка (сломан build/tests для main)
- Ручная остановка пользователем

## Восстановление после сбоя

При неожиданном прерывании:
1. Проверить `docs/ralph-state.json` — текущий прогресс
2. Запустить `/ralph-loop --resume` — продолжит с последней story
