# Claude Starter Hooks System

> Enforcement-driven automation для Claude Code

## Версионирование

**Текущая версия**: 2.1.0

См. [CHANGELOG.md](./CHANGELOG.md) для истории изменений и миграционных инструкций.

### Semantic Versioning

- **Major** (X.0.0): Breaking changes в hook interfaces или поведении
- **Minor** (x.Y.0): Новые hooks, features, backwards-compatible изменения
- **Patch** (x.y.Z): Bug fixes, performance improvements, documentation

---

## Архитектура

### Три паттерна реализации

| Паттерн | Когда использовать | Производительность | Примеры |
|---------|-------------------|-------------------|---------|
| **Pure Bash** | Простая логика (< 50 строк), быстрые gates | ~10-50ms | backpressure-gate.sh, sprint-plan-validator.sh |
| **Shell → Compiled JS** | Сложная логика с TypeScript типами | ~50-100ms | task-verification.sh, auto-format.sh |
| **Shell → npx tsx** | ❌ Deprecated (слишком медленно) | ~500-1000ms | НЕ ИСПОЛЬЗОВАТЬ |

### Shell Wrapper Template

```bash
#!/bin/bash
set -e
cd "$CLAUDE_PROJECT_DIR/.claude/hooks"
cat | node dist/<hook>.js  # Для compiled JS
```

### TypeScript Handler Template

```typescript
import { PreToolUseInput, HookOutput, readStdin, output } from './types';

async function main() {
  const input: PreToolUseInput = JSON.parse(await readStdin());

  // Validation
  if (!input.tool_input?.file_path) {
    output({ result: 'continue', message: 'No file path' });
    return;
  }

  // Logic here
  const shouldBlock = /* ... */;

  if (shouldBlock) {
    output({
      result: 'block',
      message: 'Clear error message with context and fix instructions'
    });
  } else {
    output({ result: 'continue' });
  }
}

main().catch((error) => {
  output({ result: 'continue', message: `Hook error: ${error.message}` });
});
```

---

## Best Practices

### 1. Security

- **ВСЕГДА** валидируй inputs перед использованием
- **ВСЕГДА** quote shell переменные: `"$VAR"` не `$VAR`
- **НИКОГДА** не выполняй shell команды с user input без санитизации
- Проверяй path traversal: блокируй пути с `..`

### 2. Performance

- Используй **pre-compiled JavaScript** (`node dist/`) для TypeScript hooks
- Установи **timeout** в settings.json (5s для PreToolUse, 60s для PostToolUse)
- Избегай долгих операций в PreToolUse (они блокируют каждый Edit/Write)
- Кешируй результаты если возможно

### 3. Error Handling

- **ВСЕГДА** обрабатывай ошибки gracefully
- **НИКОГДА** не падай с exception (используй `try/catch` и `output({ result: 'continue' })`)
- Включай **контекст** в error messages (file paths, actual values, expected values)
- Предоставляй **actionable instructions** для исправления

### 4. Error Messages

❌ **Плохо**:
```json
{"result":"block","message":"Pattern not found"}
```

✅ **Хорошо**:
```json
{
  "result":"block",
  "message":"Missing infrastructure tasks in sprint plan.\n\nDetected patterns: Docker, database\n\nRequired tasks:\n- Add task: 'Setup Docker infrastructure'\n- Add task: 'Configure database schema'\n\nSee: docs/infrastructure.md"
}
```

### 5. Input Validation

```typescript
// ВСЕГДА валидируй expected fields
const input = JSON.parse(await readStdin());

if (!input.tool_input?.file_path) {
  output({ result: 'continue', message: 'No file path provided' });
  return;
}

const filePath = input.tool_input.file_path as string;

// Check path traversal
if (filePath.includes('..')) {
  output({ result: 'block', message: 'Path traversal detected' });
  return;
}
```

---

## Build & Development

### Компиляция TypeScript Hooks

```bash
cd .claude/hooks
bash build.sh
```

Это компилирует все TypeScript hooks из `src/*.ts` в `dist/*.js` используя esbuild.

### Добавление нового TypeScript Hook

1. Создай `src/my-hook.ts`:
   ```typescript
   import { PreToolUseInput, HookOutput, readStdin, output } from './types';

   async function main() {
     const input: PreToolUseInput = JSON.parse(await readStdin());
     // Your logic
     output({ result: 'continue' });
   }

   main().catch((error) => {
     output({ result: 'continue', message: `Hook error: ${error.message}` });
   });
   ```

2. Добавь в `build.sh` в массив `HOOKS`:
   ```bash
   HOOKS=(
     "types"
     # ... existing hooks ...
     "my-hook"  # Add here
   )
   ```

3. Создай shell wrapper `my-hook.sh`:
   ```bash
   #!/bin/bash
   set -e
   cd "$CLAUDE_PROJECT_DIR/.claude/hooks"
   cat | node dist/my-hook.js
   ```

4. Компилируй:
   ```bash
   bash build.sh
   chmod +x my-hook.sh
   ```

5. Зарегистрируй в `.claude/settings.json`:
   ```json
   {
     "hooks": {
       "PreToolUse": [{
         "matcher": ["Edit", "Write"],
         "hooks": [{
           "type": "command",
           "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/my-hook.sh",
           "timeout": 5000
         }]
       }]
     }
   }
   ```

---

## Тестирование

### Структура тестов

```
.claude/hooks/tests/
└── hooks/
    ├── subagent-enforcement.test.sh
    ├── backpressure-gate.test.sh
    └── task-verification.test.sh
```

### Template для теста

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$HOOK_DIR/my-hook.sh"

TESTS_PASSED=0
TESTS_FAILED=0

# Helper: Run test
run_test() {
    local test_name="$1"
    local input_json="$2"
    local expected_result="$3"  # "continue" or "block"

    echo -n "  Testing: $test_name... "

    local output=$(echo "$input_json" | bash "$HOOK")
    local result=$(echo "$output" | jq -r '.result' 2>/dev/null)

    if [ "$result" = "$expected_result" ]; then
        echo "✓ PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL (expected: $expected_result, got: $result)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Setup
export CLAUDE_PROJECT_DIR="/tmp/hook-test-$$"
mkdir -p "$CLAUDE_PROJECT_DIR"
trap "rm -rf '$CLAUDE_PROJECT_DIR'" EXIT

echo ""
echo "=== Testing my-hook.sh ==="
echo ""

# Tests
run_test "Test case 1" \
    '{"tool_name":"Edit","tool_input":{"file_path":"test.ts"}}' \
    "continue"

# Results
echo ""
echo "========================================="
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "========================================="

if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi
```

### Запуск тестов

```bash
# Все тесты
bash .claude/hooks/tests/hooks/*.test.sh

# Конкретный тест
bash .claude/hooks/tests/hooks/subagent-enforcement.test.sh
```

### Критерии качества тестов

- **Минимум 80% coverage** критических hooks
- Тесты для **всех edge cases**
- **Изолированные** тесты (каждый независим)
- **Cleanup** после теста (используй `trap ... EXIT`)
- **Быстрые** (< 5s на hook)

---

## Ключевые Hooks

### PreToolUse: Enforcement

**subagent-enforcement.sh** — Блокирует Ralph Loop от прямого редактирования `src/` без subagent
- **Trigger**: Edit/Write на `src/`, `frontend/src/`, `backend/src/`
- **Logic**: Требует `.bmad/subagent-active` marker (UUID)
- **Performance**: ~10ms (pure bash)
- **Tests**: 15 test cases

**backpressure-gate.sh** — Блокирует при TypeScript/Lint errors
- **Trigger**: Edit/Write на `*.ts`, `*.tsx`
- **Logic**: Запускает `pnpm typecheck` и `pnpm lint`
- **Performance**: Variable (зависит от размера проекта)
- **Whitelist**: .claude/, .bmad/, docs/, *.md

**sprint-plan-validator.sh** — Блокирует infrastructure stories без preparatory tasks
- **Trigger**: Write на `*sprint-plan.yaml`
- **Logic**: Детектит Docker/database паттерны, требует infra tasks
- **Performance**: ~20ms (bash + grep)

### PostToolUse: Automation

**task-verification.sh** — Автоверификация task completion
- **Trigger**: Edit/Write
- **Logic**: Читает `.bmad/current-task.yaml`, проверяет completion criteria
- **Performance**: ~50-100ms (compiled JS)

**auto-format.sh** — Prettier форматирование
- **Trigger**: Write на `*.ts`, `*.tsx`, `*.js`
- **Logic**: `prettier --write <file>`
- **Performance**: ~100-300ms

**ralph-auto-commit.sh** — Git commit после каждой задачи
- **Trigger**: Edit/Write при наличии `.bmad/task-queue.yaml`
- **Logic**: Создаёт commit с task ID и summary

### SessionStart: Context Loading

**session-start-continuity.sh** — Загрузка continuity ledger
- **Trigger**: SessionStart (resume/compact/clear)
- **Logic**: Читает `thoughts/ledgers/CONTINUITY_CLAUDE-*.md`
- **Performance**: ~50ms

**session-start-ralph.sh** — Prompt для resume Ralph Loop
- **Trigger**: SessionStart clear
- **Logic**: Проверяет `.bmad/ralph-in-progress`, спрашивает продолжить

### Stop: Cleanup

**ralph-sprint-completion.sh** — Архивация спринта и validation marker
- **Trigger**: Stop (Claude завершает работу)
- **Logic**: Переносит sprint в archived/, создаёт `.bmad/validation-pending`
- **Performance**: ~50-100ms (compiled JS)

**ralph-continue.sh** — Авто-продолжение при pending tasks
- **Trigger**: Stop
- **Logic**: Проверяет `.bmad/task-queue.yaml`, запускает Ralph если есть pending

---

## Миграция и Обновление

### Upgrade Hooks

```bash
cd .claude/hooks
git pull  # Если в git репозитории
bash build.sh
```

### Breaking Changes

См. [CHANGELOG.md](./CHANGELOG.md) для breaking changes между versions.

#### From 2.0.0 to 2.1.0

**No breaking changes**. Performance improvements и bug fixes.

**Action required**: None. Hooks backwards compatible.

**Recommended**: `bash build.sh` для компиляции TypeScript hooks.

---

## Troubleshooting

### Hook не срабатывает

1. Проверь registration в `.claude/settings.json`
2. Проверь permissions: `chmod +x .claude/hooks/*.sh`
3. Проверь timeout (возможно слишком короткий)
4. Запусти hook вручную для дебага:
   ```bash
   echo '{"tool_name":"Edit","tool_input":{"file_path":"test.ts"}}' | .claude/hooks/my-hook.sh
   ```

### Hook слишком медленный

1. Проверь использует ли `node dist/` а не `npx tsx`
2. Добавь caching если возможно
3. Оптимизируй heavy operations (external commands, file reads)
4. Рассмотри переход на pure bash если логика простая

### Hook падает с ошибкой

1. Проверь logs: Claude Code показывает hook errors в output
2. Убедись что error handling есть в TypeScript:
   ```typescript
   main().catch((error) => {
     output({ result: 'continue', message: `Hook error: ${error.message}` });
   });
   ```
3. Запусти hook вручную для детальной диагностики
4. Проверь что все dependencies установлены: `cd .claude/hooks && pnpm install`

### TypeScript compilation fails

```bash
cd .claude/hooks
pnpm install  # Install dependencies
bash build.sh
```

---

## Философия: Enforcement Over Instructions

**Почему hooks вместо instructions?**

❌ **Instructions в SKILL.md** — Claude может игнорировать:
```markdown
### Quality Gates
Before marking task done, run `pnpm test`...
```

✅ **PreToolUse Hook** — Claude не может обойти:
```bash
if ! pnpm test; then
  echo '{"result":"block","message":"Fix errors first"}'
fi
```

**Правило**: Если требование критично для quality/consistency, используй hook.

---

## Метрики и Мониторинг

*(Planned for v2.2.0)*

Добавление `logMetric()` helper в `types.ts` для tracking:
- Hook execution time
- Blocked vs continued operations
- Error rates

---

## Референсы

- [Claude Code Hooks Documentation](https://code.claude.com/docs/hooks)
- [CHANGELOG.md](./CHANGELOG.md) — Version history
- [build.sh](./build.sh) — Build script
- [settings.json](../.claude/settings.json) — Hook registration
