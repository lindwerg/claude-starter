# Project Instructions

> Inherits from `~/.claude/CLAUDE.md` (FSD + VSA standards)

## Communication

Always respond in **Russian**. Be direct, explain the "why", focus on architecture.

## Project Overview

- **Name**: [Project Name]
- **Description**: [Brief project description]
- **Type**: Full-stack application (monorepo)

## Technology Stack

### Backend (VSA)
- Node.js + TypeScript (strict)
- Express/Fastify
- Prisma ORM
- PostgreSQL
- Zod validation

### Frontend (FSD)
- React 18+
- TypeScript (strict)
- TanStack Query
- Zustand/Jotai
- Tailwind CSS

### Infrastructure
- pnpm workspaces (monorepo)
- Vite (frontend build)
- Docker (development & production)
- GitHub Actions (CI/CD)

## Architecture

### Backend: Vertical Slice Architecture (VSA)

```
apps/backend/src/
├── features/           # Vertical slices
│   └── [feature]/
│       ├── *.controller.ts
│       ├── *.service.ts
│       ├── *.repository.ts
│       ├── *.schema.ts (Zod)
│       ├── *.types.ts
│       └── index.ts
├── shared/             # Cross-cutting concerns
│   ├── middleware/
│   ├── utils/
│   ├── types/
│   └── config/
├── openapi.yaml        # API contract (source of truth)
└── prisma/schema.prisma
```

### Frontend: Feature-Sliced Design (FSD)

```
apps/frontend/src/
├── app/          # App initialization, providers, global styles
├── pages/        # Full pages (1 page = 1 route)
├── widgets/      # Standalone UI blocks with state
├── features/     # Business features (reusable)
├── entities/     # Business entities (User, Product, etc.)
└── shared/       # Reusable code (ui/, lib/, hooks/, api/, types/)
```

## OpenAPI as Source of Truth

- All API endpoints MUST be defined in `openapi.yaml` first
- Generate types: `pnpm generate:types`
- Backend implements the spec, frontend consumes generated types
- Never code without updating the specification

## TypeScript Rules

- `strict: true` — no exceptions
- No `any` — use `unknown` if type is truly unknown
- No `as unknown as T` — fix the types properly
- All functions must have explicit return types
- All parameters must be typed

## Commands

```bash
# Development
pnpm dev              # Start all services
pnpm dev:backend      # Backend only
pnpm dev:frontend     # Frontend only

# Testing
pnpm test             # Run all tests
pnpm test:unit        # Unit tests only
pnpm test:e2e         # E2E tests (Playwright)
pnpm test:coverage    # With coverage report

# Validation
pnpm validate:all     # Run all validations
pnpm validate:vsa     # Check VSA structure
pnpm validate:fsd     # Check FSD structure
pnpm validate:api     # Validate OpenAPI spec

# Build & Deploy
pnpm build            # Build all
pnpm lint             # Lint all
pnpm type-check       # TypeScript check
pnpm generate:types   # Generate API types from OpenAPI
```

## Project-Specific Overrides

<!-- Add project-specific rules here that override global standards -->
