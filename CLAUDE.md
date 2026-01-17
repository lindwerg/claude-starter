# Claude Starter Kit - Global Instructions

> **Communication**: Always respond in Russian unless user specifies otherwise.

## Core Principles

1. **Architecture First** — FSD (frontend) + VSA (backend). No exceptions.
2. **Spec-Driven** — OpenAPI.yaml is the contract. Never code without specification.
3. **Production-Ready** — TypeScript strict, tests, error handling from day one.
4. **Test Pyramid Inverted** — 70% integration, 20% unit, 10% E2E.

## Technology Stack

- **Frontend**: React 18+, TypeScript (strict), TanStack Query, Zustand, Tailwind CSS
- **Backend**: Node.js, Express/Fastify, Prisma, PostgreSQL, Zod validation
- **Tools**: pnpm, Vite, Docker, Vitest, Playwright

## FSD Architecture (Frontend)

```
src/
├── app/          # Initialization, providers, global styles
├── pages/        # Full pages (1 page = 1 route)
├── widgets/      # Standalone UI blocks with state
├── features/     # Business features (reusable actions)
├── entities/     # Business entities (User, Product)
└── shared/       # Reusable code (ui/, lib/, hooks/, api/, types/)
```

### FSD Import Rules

```
ALLOWED:                    FORBIDDEN:
pages → all below           features → features
widgets → features+below    entities → features/widgets/pages
features → entities+shared  shared → anything above
entities → shared only
```

## VSA Architecture (Backend)

```
src/
├── features/           # Vertical slices
│   └── [feature]/
│       └── [slice]/    # createUser, getUsers, etc.
│           ├── controller.ts
│           ├── service.ts
│           ├── repository.ts
│           ├── dto.ts (Zod)
│           └── index.ts
├── shared/             # middleware/, utils/, types/, config/
├── openapi.yaml        # API contract (source of truth)
└── prisma/schema.prisma
```

## Code Quality Rules

### Always
- Full TypeScript typing (no `any`, no `as unknown`)
- Tests alongside code (integration first)
- Error handling everywhere
- Zod validation for all inputs
- Update openapi.yaml when API changes

### Never
- Violate FSD/VSA architecture
- Skip null/undefined checks
- Use `@ts-ignore` or `!` non-null assertion
- Hardcode values (magic numbers/strings)

## Quick Start

```bash
# After installing this starter kit:
mkdir my-app && cd my-app
/init-project              # Creates FSD+VSA structure + Docker
/workflow-init             # Initialize BMAD workflow
/ralph-loop                # Autonomous development
/commit                    # Commit changes
```

## BMAD Workflow

```
/product-brief    → Business requirements
/prd              → Product Requirements Document
/architecture     → System design (auto-selects FSD+VSA)
/sprint-planning  → Break into stories
/dev-story        → Implement story
```
