# Provide Starter Kit

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-2.0.0-green.svg)
![Claude Code](https://img.shields.io/badge/Claude%20Code-compatible-purple.svg)

> Автономная разработка full-stack приложений с Claude Code

Превращает Claude Code в полностью автономную систему разработки со специализированными агентами, архитектурными паттернами и production-ready workflows.

---

## Быстрый старт

```bash
curl -fsSL https://raw.githubusercontent.com/lindwerg/claude-starter/main/install.sh | bash
```

После установки:

```bash
mkdir my-app && cd my-app
claude
/step1-init
```

---

## Что получаешь?

### 6 специализированных агентов

| Агент | Ответственность |
|-------|-----------------|
| **API Agent** | OpenAPI спецификация, типы, API контракты |
| **Backend Agent** | VSA slices (Vertical Slice Architecture) |
| **Frontend Agent** | FSD компоненты (Feature-Sliced Design) |
| **Test Agent** | TDD-first тестирование (Vitest, Playwright) |
| **DevOps Agent** | Docker, миграции, окружение |
| **Validation Agent** | Проверка архитектуры, линтинг, coverage |

### 7 шагов разработки

| Шаг | Команда | Описание |
|-----|---------|----------|
| 1 | `/step1-init` | Создание структуры проекта |
| 2 | `/step2-brief` | Бизнес-анализ требований |
| 3 | `/step3-prd` | Документ требований (PRD) |
| 4 | `/step4-arch` | Техническая архитектура |
| 5 | `/step5-sprint` | Планирование спринта |
| 6 | `/step6-validate` | Валидация и очередь задач |
| 7 | `/step7-build` | Автономная разработка |

### Production-Ready архитектура

- **VSA (Vertical Slice Architecture)** для backend
- **FSD (Feature-Sliced Design)** для frontend
- **OpenAPI 3.1** как единственный источник правды
- **TypeScript strict mode** везде
- **Zod валидация** для всех inputs

### Автоматические проверки

- Pre-commit hooks для форматирования и типов
- Test coverage thresholds (80% minimum)
- Валидация архитектуры (VSA/FSD правила)
- OpenAPI sync verification

---

## Архитектура

### Ralph Loop

Автономный оркестратор реализации:

```
+----------------------------------------------------------+
|                      RALPH LOOP                           |
+----------------------------------------------------------+
|  Story --> API Agent --> Backend Agent --> Frontend Agent |
|                |              |                |          |
|           openapi.yaml    VSA slice       FSD feature     |
|                |              |                |          |
|         Test Agent --> DevOps Agent --> Validation Agent  |
|                |              |                |          |
|            tests         CI/deploy        arch check      |
|                              |                            |
|                       COMPLETE / BLOCKED                  |
+----------------------------------------------------------+
```

**RALPH** = **R**elentless **A**utonomous **L**oop for **P**roduct **H**acking

Цикл продолжается до завершения или явного блокера, требующего решения человека.

---

## Структура после установки

```
~/.claude/
├── CLAUDE.md              # Глобальные инструкции
├── settings.json          # Настройки Claude Code
├── mcp_config.json        # MCP серверы
│
├── agents/                # Агенты
│   ├── api-agent.md
│   ├── backend-agent.md
│   ├── frontend-agent.md
│   ├── test-agent.md
│   ├── devops-agent.md
│   └── validation-agent.md
│
├── skills/                # Скиллы
│   ├── provide/           # Основные шаги (step1-step7)
│   ├── advanced/          # Дополнительные команды
│   ├── help/              # Справка
│   ├── vsa-fsd/           # Валидация архитектуры
│   └── testing-modern/    # Стратегия тестирования
│
├── rules/                 # Правила разработки
│   ├── api-first.md
│   ├── fsd-architecture.md
│   ├── vsa-architecture.md
│   ├── typescript-strict.md
│   └── testing-strategy.md
│
├── hooks/                 # Автоматизация
│   ├── auto-format.sh
│   ├── typescript-preflight.sh
│   ├── backpressure-gate.sh
│   └── ...
│
├── commands/              # Кастомные команды
├── templates/             # Шаблоны проектов
└── scripts/               # Утилиты
```

---

## Workflow

### Шаг 1: Инициализация проекта

```bash
/step1-init
```

Создаёт структуру с:
- TypeScript (strict mode)
- ESLint и Prettier
- Docker Compose для локальной разработки
- OpenAPI template
- VSA backend структура
- FSD frontend структура

### Шаг 2: Бизнес-бриф

```bash
/step2-brief
```

Определяет видение продукта, целевую аудиторию, метрики успеха.

### Шаг 3: PRD

```bash
/step3-prd
```

Создаёт детальный Product Requirements Document с user stories.

### Шаг 4: Архитектура

```bash
/step4-arch
```

Техническая архитектура:
- System design
- Database schema
- API structure
- Security

### Шаг 5: Планирование спринта

```bash
/step5-sprint
```

Разбивает PRD на эпики и user stories.

### Шаг 6: Валидация

```bash
/step6-validate
```

Проверяет sprint plan и генерирует очередь задач.

### Шаг 7: Автономная разработка

```bash
/step7-build
```

Автономная реализация:
- Обрабатывает задачи последовательно
- Каждая задача проходит через нужного агента
- Продолжает до завершения или блокера
- Автоматически коммитит

---

## Справочник команд

### Основные команды (по порядку)

| Команда | Описание |
|---------|----------|
| `/step1-init` | Создание структуры проекта |
| `/step2-brief` | Бизнес-анализ требований |
| `/step3-prd` | Документ требований |
| `/step4-arch` | Техническая архитектура |
| `/step5-sprint` | Планирование спринта |
| `/step6-validate` | Валидация и очередь задач |
| `/step7-build` | Автономная разработка |

### Дополнительные команды

| Команда | Описание |
|---------|----------|
| `/help` | Справка |
| `/commit` | Git commit (без Claude attribution) |
| `/validate-all` | Полная валидация |

### Advanced команды

| Команда | Описание |
|---------|----------|
| `/advanced:brainstorm` | Мозговой штурм идей |
| `/advanced:research` | Исследование темы |
| `/advanced:create-agent` | Создание нового агента |
| `/advanced:create-workflow` | Создание нового workflow |
| `/advanced:create-story` | Создание user story |
| `/advanced:create-ux-design` | UX дизайн интерфейса |
| `/advanced:dev-story` | Ручная реализация story |
| `/advanced:tech-spec` | Техническая спецификация |
| `/advanced:workflow-init` | Инициализация workflow |
| `/advanced:workflow-status` | Статус прогресса |
| `/advanced:solutioning-gate-check` | Проверка архитектуры |

---

## VSA Архитектура (Backend)

Vertical Slice Architecture организует код по фичам:

```
src/
├── features/
│   └── users/
│       └── create-user/
│           ├── controller.ts    # HTTP handler
│           ├── service.ts       # Бизнес-логика
│           ├── repository.ts    # Доступ к данным
│           ├── dto.ts           # Zod schemas
│           └── index.ts         # Public API
├── shared/
│   ├── middleware/
│   ├── utils/
│   └── types/
└── prisma/
    └── schema.prisma
```

**Правила:**
- Каждая фича самодостаточна
- Нет cross-feature импортов
- Controller -> Service -> Repository иерархия
- Все inputs валидируются Zod

---

## FSD Архитектура (Frontend)

Feature-Sliced Design организует код по слоям:

```
src/
├── app/           # Инициализация, providers
├── pages/         # Полные страницы (1 на route)
├── widgets/       # Составные UI блоки
├── features/      # Бизнес-фичи
├── entities/      # Бизнес-сущности
└── shared/        # UI kit, hooks, utils, api
```

**Правила импортов (только вниз):**
- `pages` -> widgets, features, entities, shared
- `widgets` -> features, entities, shared
- `features` -> entities, shared
- `entities` -> shared
- `shared` -> только внешние пакеты

---

## Стратегия тестирования

Перевёрнутая пирамида (70% интеграционных):

```
        /\
       /E2E\        5-10%
      /------\
     /Integr- \     70%
    /  ation   \
   /------------\
  /    Unit      \  20%
 /________________\
```

- **Unit тесты**: Чистые функции, утилиты (Vitest)
- **Integration тесты**: API endpoints, DB queries (Vitest + Supertest)
- **E2E тесты**: Критические user flows (Playwright)

**Минимум coverage: 80%**

---

## Требования

### Обязательно

- **Claude Code** - CLI установлен и авторизован
- **Node.js** >= 18.x
- **Git** >= 2.x
- **pnpm** >= 8.x

### Опционально

- **Docker** >= 24.x (для локальной разработки)
- **jq** (для умного merge settings при установке)

### Проверка

```bash
node --version  # >= 18.x
git --version   # >= 2.x
pnpm --version  # >= 8.x
docker --version  # >= 24.x (опционально)
```

---

## Установка

### Одной командой

```bash
curl -fsSL https://raw.githubusercontent.com/lindwerg/claude-starter/main/install.sh | bash
```

### Вручную

```bash
git clone https://github.com/lindwerg/claude-starter.git
cd claude-starter
./install.sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/lindwerg/claude-starter/main/install.ps1 | iex
```

### Что устанавливается

1. Skills, rules, hooks, commands, agents -> `~/.claude/`
2. Settings мержатся (сохраняют существующие)
3. MCP config мержится (сохраняет существующие серверы)
4. Templates и scripts
5. Backup существующего конфига

---

## Удаление

```bash
./uninstall.sh
```

Восстановление из backup:

```bash
cp -r ~/.claude-backup-<timestamp>/* ~/.claude/
```

---

## Обновление

```bash
cd claude-starter
git pull origin main
./install.sh
```

---

## Troubleshooting

### Skills не загружаются

1. Перезапусти Claude Code
2. Проверь `~/.claude/settings.json` на синтаксические ошибки
3. Убедись что файлы скиллов существуют в `~/.claude/skills/`

### Hooks не работают

1. Проверь права: `chmod +x ~/.claude/hooks/*.sh`
2. Проверь регистрацию в `~/.claude/settings.json`
3. Тест вручную: `echo '{"test": true}' | ~/.claude/hooks/auto-format.sh`

### MCP серверы не подключаются

1. Проверь синтаксис `~/.claude/mcp_config.json`
2. Убедись что зависимости серверов установлены
3. Проверь логи в выводе Claude Code

---

## Лицензия

MIT License

---

## Благодарности

- [Claude Code](https://claude.ai/claude-code) by Anthropic
- [Feature-Sliced Design](https://feature-sliced.design/)
- [Vertical Slice Architecture](https://www.jimmybogard.com/vertical-slice-architecture/)
