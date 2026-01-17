# /validate-all

Полная валидация проекта: типы, линтинг, тесты, архитектура, сборка.

## Описание

Запускает все проверки качества кода в правильном порядке. Используй перед коммитом,
после merge, или для диагностики проблем. Выводит сводный отчёт pass/fail.

**Философия:** Быстрые проверки сначала, медленные — в конце. Fail fast.

## Входные параметры

- `$SCOPE` — область проверки: `all` | `backend` | `frontend` (по умолчанию `all`)
- `$FIX` — автоматически исправлять где возможно (по умолчанию false)
- `$VERBOSE` — подробный вывод (по умолчанию false)

## Workflow

### 1. Type Check (быстро, ~5-10 сек)

```bash
# Backend
cd backend && npm run type-check
# Эквивалент: tsc --noEmit

# Frontend
cd frontend && npm run type-check
# Эквивалент: tsc --noEmit
```

**Что проверяет:**
- Все типы корректны
- Нет `any` где не должно быть
- Import/export согласованы

### 2. Lint (быстро, ~10-15 сек)

```bash
# Backend
cd backend && npm run lint
# С фиксом: npm run lint -- --fix

# Frontend
cd frontend && npm run lint
# С фиксом: npm run lint -- --fix
```

**Что проверяет:**
- ESLint rules
- Prettier formatting
- Import sorting

### 3. Unit Tests (средне, ~30-60 сек)

```bash
# Backend
cd backend && npm test
# Эквивалент: vitest run

# Frontend
cd frontend && npm test
# Эквивалент: vitest run
```

**Что проверяет:**
- Все unit тесты проходят
- Coverage не упал (если настроен threshold)

### 4. Validate VSA (backend архитектура)

```bash
cd backend && npm run validate:vsa
```

**Что проверяет:**
- Каждая feature содержит: controller, service, schema
- Нет cross-feature импортов (только через shared)
- Shared не импортирует из features
- Repository только в feature, не в shared

**Пример ошибки:**
```
ERROR: features/users/user.service.ts imports from features/auth/
       Cross-feature imports forbidden. Use shared/ or events.
```

### 5. Validate FSD (frontend архитектура)

```bash
cd frontend && npm run validate:fsd
```

**Что проверяет:**
- Слои импортируют только разрешённые слои
- Нет циклических зависимостей
- Каждый slice имеет public API (index.ts)

**Правила импорта:**
```
pages    → widgets, features, entities, shared
widgets  → features, entities, shared
features → entities, shared
entities → shared
shared   → ничего выше
```

**Пример ошибки:**
```
ERROR: features/cart/ui/CartButton.tsx imports from widgets/Header
       features cannot import from widgets
```

### 6. Validate API (OpenAPI соответствие)

```bash
npm run validate:api
```

**Что проверяет:**
- openapi.yaml валиден (OpenAPI 3.x)
- Backend endpoints соответствуют spec
- Zod schemas согласованы с OpenAPI types
- Нет undocumented endpoints

**Пример ошибки:**
```
ERROR: GET /api/users/{id} exists in code but missing in openapi.yaml
       Add endpoint to spec or remove from code.
```

### 7. Build (медленно, ~1-3 мин)

```bash
# Backend
cd backend && npm run build
# Эквивалент: tsc

# Frontend
cd frontend && npm run build
# Эквивалент: vite build
```

**Что проверяет:**
- Код компилируется без ошибок
- Все assets резолвятся
- Bundle size в пределах нормы

## Output

### Успех (все проверки прошли)

```
╔═══════════════════════════════════════════╗
║           VALIDATION REPORT               ║
╠═══════════════════════════════════════════╣
║ ✓ Type Check      PASS    (8.2s)          ║
║ ✓ Lint            PASS    (12.1s)         ║
║ ✓ Unit Tests      PASS    (45.3s)         ║
║ ✓ Validate VSA    PASS    (2.1s)          ║
║ ✓ Validate FSD    PASS    (3.4s)          ║
║ ✓ Validate API    PASS    (5.2s)          ║
║ ✓ Build           PASS    (67.8s)         ║
╠═══════════════════════════════════════════╣
║ RESULT: ALL CHECKS PASSED                 ║
║ Total time: 2m 24s                        ║
╚═══════════════════════════════════════════╝
```

### Провал (есть ошибки)

```
╔═══════════════════════════════════════════╗
║           VALIDATION REPORT               ║
╠═══════════════════════════════════════════╣
║ ✓ Type Check      PASS    (8.2s)          ║
║ ✗ Lint            FAIL    (12.1s)         ║
║   → 3 errors in frontend/src/features/    ║
║ - Unit Tests      SKIP    (skipped)       ║
║ - Validate VSA    SKIP    (skipped)       ║
║ - Validate FSD    SKIP    (skipped)       ║
║ - Validate API    SKIP    (skipped)       ║
║ - Build           SKIP    (skipped)       ║
╠═══════════════════════════════════════════╣
║ RESULT: FAILED AT STEP 2 (Lint)           ║
║ Fix errors and re-run /validate-all       ║
╚═══════════════════════════════════════════╝
```

## Примеры использования

### Полная валидация
```
/validate-all
```

### Только backend
```
/validate-all --scope backend
```

### С автофиксом линтинга
```
/validate-all --fix
```

### Подробный вывод для дебага
```
/validate-all --verbose
```

### Только архитектурные проверки
```
/validate-all --only vsa,fsd
```

## Интеграция с CI/CD

```yaml
# .github/workflows/validate.yml
validate:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - run: pnpm install
    - run: pnpm validate:all
```

## Когда использовать

- **Перед коммитом** — убедиться что ничего не сломано
- **После merge** — проверить что интеграция успешна
- **При странном поведении** — найти источник проблемы
- **В CI/CD** — автоматическая проверка на каждый PR
