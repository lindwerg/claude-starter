---
name: ralph-loop
description: Autonomous implementation loop with subagents
allowed-tools: [Bash, Read, Write, Edit, Grep, Glob, Task, TodoWrite]
---

# Ralph Loop — Autonomous Implementation Orchestrator

Главный skill для автономной разработки фич через оркестрацию специализированных субагентов.

## When to Use

- Реализация полной user story от API до UI
- Многофазные задачи с зависимостями между backend/frontend
- Когда нужна автономная работа с минимальным участием человека
- Batch-реализация нескольких связанных stories

## Core Philosophy

**Ralph = Relentless Autonomous Loop for Product Hacking**

Цикл работает до полного завершения или явного блокера, требующего человека.

## Workflow Overview

```
┌─────────────────────────────────────────────────────────┐
│                     RALPH LOOP                          │
├─────────────────────────────────────────────────────────┤
│  Story → API Agent → Backend Agent → Frontend Agent     │
│                ↓           ↓              ↓             │
│           openapi.yaml  VSA slice    FSD feature        │
│                ↓           ↓              ↓             │
│         Test Agent → DevOps Agent → Validation Agent    │
│                ↓           ↓              ↓             │
│            tests      CI/deploy     arch check          │
│                          ↓                              │
│                   <promise>COMPLETE</promise>           │
└─────────────────────────────────────────────────────────┘
```

## Subagent Pipeline

### 1. API Agent

**Purpose**: Определить контракт API перед реализацией

```yaml
Input: User story, existing openapi.yaml
Output: Updated openapi.yaml with new endpoints
Validates: OpenAPI spec validity, naming conventions
```

### 2. Backend Agent

**Purpose**: Реализовать VSA slice

```yaml
Input: openapi.yaml endpoints
Output:
  - src/features/[name]/*.ts (controller, service, repository, schema)
  - prisma/schema.prisma updates
  - Database migrations
Validates: VSA structure, Zod schemas match OpenAPI
```

### 3. Frontend Agent

**Purpose**: Реализовать FSD feature

```yaml
Input: Generated API types, UI requirements
Output:
  - src/features/[name]/ (UI components, model, api)
  - src/entities/[name]/ (if new entity)
  - src/pages/ updates
Validates: FSD import rules, TypeScript strict
```

### 4. Test Agent

**Purpose**: Написать тесты по inverted pyramid

```yaml
Input: Implemented feature code
Output:
  - Unit tests (20%) — isolated logic
  - Integration tests (70%) — API + DB
  - E2E tests (10%) — critical paths
Validates: Coverage >80%, all tests pass
```

### 5. DevOps Agent

**Purpose**: CI/CD и deployment

```yaml
Input: Complete feature with tests
Output:
  - CI pipeline updates
  - Docker/compose changes
  - Environment variables
Validates: Build succeeds, deploy preview works
```

### 6. Validation Agent

**Purpose**: Финальная проверка архитектуры

```yaml
Input: All changes
Output: Validation report
Validates: VSA/FSD rules, no circular deps, types match
```

## Retry Logic

```
MAX_RETRIES_PER_AGENT = 3

for agent in pipeline:
    retries = 0
    while retries < MAX_RETRIES:
        result = agent.execute()
        if result.success:
            break
        retries++
        if retries == MAX_RETRIES:
            return BLOCKED(agent, result.error)
```

## Story Transition

После завершения story:

1. Mark current story DONE в ledger
2. Update checkboxes: `[x]` completed, `[→]` next
3. Commit changes with `/commit`
4. Load next story context
5. Continue loop

## Output Format

```xml
<!-- Success -->
<promise>COMPLETE</promise>
<summary>
  - Created: 5 files
  - Modified: 3 files
  - Tests: 24 passed
  - Coverage: 87%
</summary>

<!-- Blocked -->
<promise>BLOCKED</promise>
<blocker>
  Agent: Backend
  Error: Prisma migration conflict
  Requires: Human decision on schema change
</blocker>
```

## Usage Examples

### Single Story

```
/ralph-loop

Story: Implement user authentication
- Login with email/password
- JWT token generation
- Protected route middleware
```

### Batch Stories

```
/ralph-loop --batch

Stories:
1. User registration
2. Email verification
3. Password reset
4. Profile management
```

### Resume After Block

```
/ralph-loop --resume

Continuing from: Backend Agent (retry 2/3)
Last error: Database connection timeout
```

## Integration with Ledger

Ralph automatically updates `thoughts/ledgers/CONTINUITY_CLAUDE-*.md`:

```markdown
## State
- Done:
  - [x] Story 1: User registration
  - [x] Story 2: Email verification
- Now: [→] Story 3: Password reset (Backend Agent)
- Next: Story 4: Profile management
```

## Monitoring

```bash
# Check loop status
cat thoughts/ledgers/CONTINUITY_CLAUDE-ralph.md

# View agent logs
tail -f .claude/cache/ralph-loop.log
```

## See Also

- `/implement_task` — Single task implementation
- `/create_plan` — Planning before Ralph
- `thoughts/ledgers/` — State persistence
