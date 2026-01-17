# Agents Reference

Detailed documentation for all 6 specialized subagents in the Ralph Loop.

---

## Overview

| Agent | Role | Key Output |
|-------|------|------------|
| API Agent | API contract design | `openapi.yaml` |
| Backend Agent | VSA implementation | VSA slice files |
| Frontend Agent | FSD implementation | FSD feature files |
| Test Agent | TDD-first testing | Test files |
| DevOps Agent | Environment setup | Docker, migrations |
| Validation Agent | Quality checks | Validation report |

---

## 1. API Agent

> OpenAPI specification and type generation

### Role

The API Agent is the API architect responsible for maintaining `openapi.yaml` as the single source of truth. It defines the contract between frontend and backend before any implementation begins.

### Knowledge Areas

- **OpenAPI 3.1** - Paths, operations, schemas, components
- **Zod Generation** - Generating validation schemas from OpenAPI
- **TypeScript Types** - Type generation from specification
- **REST Best Practices** - Resource naming, HTTP verbs, status codes

### Workflow

1. **Read story** - Extract required endpoints
2. **Analyze existing spec** - Check `openapi.yaml`
3. **Design endpoints** - Define paths, schemas, responses
4. **Update openapi.yaml** - Add new endpoints
5. **Generate types** - Run `pnpm generate-api-types`
6. **Validate** - Lint OpenAPI spec

### Input

```yaml
- User story description
- Existing openapi.yaml
- Database schema (for reference)
```

### Output

```yaml
- Updated openapi.yaml with new endpoints
- Generated TypeScript types (src/shared/api/types.generated.ts)
- Generated Zod schemas (src/shared/api/schemas.generated.ts)
```

### Example Output

```yaml
# openapi.yaml addition
paths:
  /api/v1/users:
    post:
      operationId: createUser
      tags: [users]
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
```

---

## 2. Backend Agent

> VSA slices (Vertical Slice Architecture)

### Role

The Backend Agent implements features using Vertical Slice Architecture. Each feature is a self-contained vertical slice with its own controller, service, repository, and DTOs.

### Knowledge Areas

- **VSA Structure** - Vertical slice organization
- **REPR Pattern** - Request-Endpoint-Response
- **CQRS Light** - Command/Query separation
- **Prisma ORM** - Database access layer

### Workflow

1. **Read API types** - From generated types
2. **Create slice structure** - Directory for new use case
3. **Implement layers** - dto.ts, repository.ts, service.ts, controller.ts
4. **Register routes** - Add to feature router
5. **Test** - Run unit and integration tests

### Input

```yaml
- openapi.yaml endpoints
- Generated TypeScript types
- Prisma schema
```

### Output

```yaml
- src/features/[feature]/[slice]/controller.ts
- src/features/[feature]/[slice]/service.ts
- src/features/[feature]/[slice]/repository.ts
- src/features/[feature]/[slice]/dto.ts
- src/features/[feature]/[slice]/index.ts
- Tests for each layer
```

### VSA Structure

```
src/features/users/create-user/
├── controller.ts    # HTTP handler
├── service.ts       # Business logic
├── repository.ts    # Data access
├── dto.ts           # Zod schemas + types
├── types.ts         # Domain types
├── index.ts         # Public exports
└── *.test.ts        # Tests
```

---

## 3. Frontend Agent

> FSD components (Feature-Sliced Design)

### Role

The Frontend Agent creates UI components following Feature-Sliced Design methodology. Each layer has clear responsibilities and strict import rules.

### Knowledge Areas

- **FSD Layers** - app, pages, widgets, features, entities, shared
- **React 18+** - Hooks, Suspense, transitions
- **TanStack Query** - Server state management
- **Zustand/Jotai** - Client state management
- **Tailwind CSS** - Utility-first styling

### Workflow

1. **Read API types** - From generated types
2. **Determine layer** - Which FSD layer?
3. **Create segment structure** - ui/, model/, api/
4. **Implement components** - React components with types
5. **Add state management** - TanStack Query or Zustand
6. **Export via index.ts** - Public API only

### Input

```yaml
- Generated API types
- UI requirements from story
- Existing shared components
```

### Output

```yaml
- src/[layer]/[slice]/ui/*.tsx
- src/[layer]/[slice]/model/*.ts
- src/[layer]/[slice]/api/*.ts
- src/[layer]/[slice]/index.ts
- Tests for components
```

### FSD Layer Decision

| What to create | Layer |
|----------------|-------|
| Full page | pages |
| Standalone UI block | widgets |
| User action | features |
| Data display | entities |
| Reusable UI | shared/ui |

### FSD Import Rules

```
pages    -> widgets, features, entities, shared
widgets  -> features, entities, shared
features -> entities, shared
entities -> shared
shared   -> external only
```

---

## 4. Test Agent

> TDD-first approach

### Role

The Test Agent writes tests BEFORE implementation (TDD). It ensures code quality through comprehensive test coverage following the inverted test pyramid.

### Knowledge Areas

- **Test Pyramid** - 20% unit, 70% integration, 10% E2E
- **Vitest** - Unit and integration testing
- **Playwright MCP** - E2E browser testing
- **AAA Pattern** - Arrange, Act, Assert
- **Mocking** - vi.mock, vi.spyOn

### Workflow

1. **Extract acceptance criteria** - From story
2. **Write tests FIRST** - Red phase (failing tests)
3. **Cover edge cases** - Error scenarios
4. **Add E2E for critical paths** - Playwright
5. **Verify coverage** - >= 80%

### Input

```yaml
- User story with acceptance criteria
- Implementation plan
- API contract
```

### Output

```yaml
- src/features/[feature]/*.test.ts (unit)
- src/features/[feature]/*.integration.test.ts
- e2e/[feature].spec.ts (E2E)
- Coverage report
```

### Test Distribution

```
        /\
       /E2E\        5-10% - Critical user flows
      /------\
     /Integr- \     70% - API endpoints, DB
    /  ation   \
   /------------\
  /    Unit      \  20% - Pure functions
 /________________\
```

### Coverage Requirements

- **Minimum:** 80% overall
- **Critical paths:** 100%
- **New code:** 90%+

---

## 5. DevOps Agent

> Local environment and deployment

### Role

The DevOps Agent sets up and manages the local development environment. It handles Docker, database migrations, environment variables, and health checks.

### Knowledge Areas

- **Docker Compose** - Container orchestration
- **PostgreSQL** - Database management
- **Prisma** - Migrations and seeding
- **Environment Variables** - Configuration management

### Workflow

1. **Check prerequisites** - Node, Docker, ports
2. **Setup environment** - Copy .env.example
3. **Start containers** - docker compose up
4. **Run migrations** - prisma migrate dev
5. **Seed database** - prisma db seed
6. **Start dev server** - pnpm dev
7. **Health check** - Verify all services

### Input

```yaml
- Project requirements
- Database schema
- Environment template
```

### Output

```yaml
- Running Docker containers (db, redis)
- Migrated database
- Seeded test data
- Running application
- Health check passing
```

### Service Ports

| Service | Port |
|---------|------|
| Application | 3000 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| Mailhog | 1025/8025 |

### Health Check

```bash
curl http://localhost:3000/api/health

# Expected response:
{
  "status": "healthy",
  "services": {
    "database": "connected",
    "redis": "connected"
  }
}
```

---

## 6. Validation Agent

> Final quality checks

### Role

The Validation Agent performs comprehensive quality checks before code is ready for merge. It verifies architecture compliance, type safety, test coverage, and code quality.

### Knowledge Areas

- **VSA Rules** - Backend architecture validation
- **FSD Rules** - Frontend architecture validation
- **TypeScript Strict** - No any, no @ts-ignore
- **ESLint** - Code quality rules
- **OpenAPI Sync** - Spec matches implementation

### Workflow

1. **Type check** - `pnpm tsc --noEmit`
2. **Lint check** - `pnpm lint`
3. **Run tests** - `pnpm test --coverage`
4. **VSA validation** - Check backend architecture
5. **FSD validation** - Check frontend architecture
6. **OpenAPI sync** - Verify types match spec
7. **Build check** - `pnpm build`

### Input

```yaml
- All changed files
- Test results
- Coverage report
```

### Output

```yaml
- Validation report (pass/fail for each check)
- List of violations (if any)
- Recommendations
```

### Validation Report

```markdown
# Validation Report

| Check | Status | Details |
|-------|--------|---------|
| Type Check | PASS | 0 errors |
| ESLint | PASS | 0 errors |
| Tests | PASS | 142 passed |
| Coverage | PASS | 85.2% |
| VSA | PASS | No violations |
| FSD | PASS | No violations |
| OpenAPI | PASS | In sync |
| Build | PASS | 245KB gzipped |
```

### Checks Performed

**TypeScript:**
- No `any` types
- No `as unknown as` casts
- No `@ts-ignore` comments
- No `!` non-null assertions without checks

**Architecture:**
- VSA: No cross-feature imports
- FSD: No upward layer imports
- Both: No circular dependencies

**Quality:**
- ESLint rules pass
- Test coverage >= 80%
- Build succeeds
- OpenAPI types in sync

---

## Agent Communication

### Pipeline Order

```
1. API Agent
   |
   v
2. Backend Agent
   |
   v
3. Frontend Agent
   |
   v
4. Test Agent
   |
   v
5. DevOps Agent
   |
   v
6. Validation Agent
```

### Data Flow

```
Story
  |
  v
API Agent --> openapi.yaml
  |
  v
Backend Agent --> VSA files (uses openapi types)
  |
  v
Frontend Agent --> FSD files (uses openapi types)
  |
  v
Test Agent --> Test files (tests all above)
  |
  v
DevOps Agent --> Environment (runs all above)
  |
  v
Validation Agent --> Report (validates all above)
```

### Handoff Points

Each agent produces artifacts that the next agent consumes:

| From | To | Artifact |
|------|-----|----------|
| API | Backend | openapi.yaml, types |
| Backend | Frontend | API implementation |
| Frontend | Test | UI components |
| Test | DevOps | Test suite |
| DevOps | Validation | Running environment |

---

## Related Documentation

- [WORKFLOW.md](./WORKFLOW.md) - Workflow guide
- [INSTALLATION.md](./INSTALLATION.md) - Installation guide
- [README.md](../README.md) - Project overview
