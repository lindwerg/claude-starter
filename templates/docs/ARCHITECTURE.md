# Architecture Decision Record (ADR)

**Project**: [Project Name]
**Version**: 1.0
**Date**: [YYYY-MM-DD]
**Author**: [Author Name]
**Status**: Proposed | Accepted | Deprecated | Superseded

---

## System Overview

### Purpose
[What does this system do? 2-3 sentences]

### Context Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                       External Users                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (React/FSD)                     │
│                    http://localhost:3000                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backend API (Node/VSA)                   │
│                    http://localhost:3001                    │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │PostgreSQL│   │  Redis   │   │ External │
        │   :5432  │   │  :6379   │   │   APIs   │
        └──────────┘   └──────────┘   └──────────┘
```

### Key Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Frontend Architecture | FSD | Clear boundaries, scalable structure |
| Backend Architecture | VSA | Feature isolation, maintainability |
| API Contract | OpenAPI 3.1 | Type generation, documentation |
| Database | PostgreSQL | ACID compliance, JSON support |
| ORM | Prisma | Type safety, migrations |
| Validation | Zod | Runtime + compile-time safety |

---

## VSA Backend Structure

### Overview

Vertical Slice Architecture organizes code by feature, not by technical layer. Each feature is a self-contained slice with all its layers.

### Directory Structure

```
apps/backend/src/
├── features/
│   ├── auth/
│   │   ├── auth.controller.ts      # HTTP handlers
│   │   ├── auth.service.ts         # Business logic
│   │   ├── auth.repository.ts      # Data access
│   │   ├── auth.schema.ts          # Zod schemas
│   │   ├── auth.types.ts           # TypeScript types
│   │   ├── auth.test.ts            # Tests
│   │   └── index.ts                # Public API
│   │
│   ├── users/
│   │   ├── users.controller.ts
│   │   ├── users.service.ts
│   │   ├── users.repository.ts
│   │   ├── users.schema.ts
│   │   ├── users.types.ts
│   │   ├── users.test.ts
│   │   └── index.ts
│   │
│   └── [feature]/
│       └── ...
│
├── shared/
│   ├── middleware/
│   │   ├── auth.middleware.ts
│   │   ├── error.middleware.ts
│   │   ├── validation.middleware.ts
│   │   └── logging.middleware.ts
│   │
│   ├── utils/
│   │   ├── logger.ts
│   │   ├── errors.ts
│   │   └── helpers.ts
│   │
│   ├── types/
│   │   └── common.types.ts
│   │
│   └── config/
│       ├── env.ts
│       └── database.ts
│
├── openapi.yaml                    # API specification
├── app.ts                          # Express/Fastify app setup
└── server.ts                       # Server entry point
```

### Feature Rules

1. **Self-contained**: Each feature has its own controller, service, repository
2. **No cross-feature imports**: Features communicate via shared types or events
3. **Public API via index.ts**: Only export what other features need
4. **Tests co-located**: Each feature has its own tests

### Layer Responsibilities

| Layer | Responsibility |
|-------|----------------|
| Controller | HTTP handling, request/response transformation |
| Service | Business logic, orchestration |
| Repository | Data access, database queries |
| Schema | Input/output validation with Zod |
| Types | TypeScript interfaces and types |

---

## FSD Frontend Structure

### Overview

Feature-Sliced Design organizes code by business domain with strict import rules that ensure maintainability.

### Directory Structure

```
apps/frontend/src/
├── app/
│   ├── providers/
│   │   ├── QueryProvider.tsx
│   │   ├── RouterProvider.tsx
│   │   └── ThemeProvider.tsx
│   ├── styles/
│   │   └── globals.css
│   ├── App.tsx
│   └── main.tsx
│
├── pages/
│   ├── home/
│   │   ├── ui/
│   │   │   └── HomePage.tsx
│   │   └── index.ts
│   ├── auth/
│   │   ├── ui/
│   │   │   ├── LoginPage.tsx
│   │   │   └── RegisterPage.tsx
│   │   └── index.ts
│   └── [page]/
│       └── ...
│
├── widgets/
│   ├── header/
│   │   ├── ui/
│   │   │   └── Header.tsx
│   │   └── index.ts
│   ├── sidebar/
│   │   └── ...
│   └── [widget]/
│       └── ...
│
├── features/
│   ├── auth/
│   │   ├── api/
│   │   │   └── authApi.ts
│   │   ├── model/
│   │   │   ├── authStore.ts
│   │   │   └── authTypes.ts
│   │   ├── ui/
│   │   │   ├── LoginForm.tsx
│   │   │   └── LogoutButton.tsx
│   │   └── index.ts
│   └── [feature]/
│       └── ...
│
├── entities/
│   ├── user/
│   │   ├── api/
│   │   │   └── userApi.ts
│   │   ├── model/
│   │   │   └── userTypes.ts
│   │   ├── ui/
│   │   │   ├── UserCard.tsx
│   │   │   └── UserAvatar.tsx
│   │   └── index.ts
│   └── [entity]/
│       └── ...
│
└── shared/
    ├── api/
    │   ├── client.ts
    │   └── types.ts
    ├── ui/
    │   ├── Button/
    │   ├── Input/
    │   ├── Modal/
    │   └── ...
    ├── lib/
    │   ├── formatters.ts
    │   └── validators.ts
    ├── hooks/
    │   ├── useDebounce.ts
    │   └── useMediaQuery.ts
    └── types/
        └── common.ts
```

### Import Rules

```
Layer          Can Import From
─────────────────────────────────────────
app         →  pages, widgets, features, entities, shared
pages       →  widgets, features, entities, shared
widgets     →  features, entities, shared
features    →  entities, shared
entities    →  shared
shared      →  (nothing above)
```

### Segment Structure

Each slice follows the same internal structure:

| Segment | Purpose |
|---------|---------|
| `api/` | API calls, data fetching |
| `model/` | State, types, business logic |
| `ui/` | React components |
| `lib/` | Utilities specific to this slice |
| `index.ts` | Public API (re-exports) |

---

## API Design (OpenAPI)

### Contract-First Development

1. **Design API in openapi.yaml first**
2. **Generate TypeScript types**: `pnpm generate:types`
3. **Implement backend endpoints**
4. **Frontend consumes generated types**

### OpenAPI Location

```
apps/backend/src/openapi.yaml
```

### Type Generation

```bash
# Generate types from OpenAPI spec
pnpm generate:types

# Output location
packages/api-types/src/generated.ts
```

### API Conventions

| Aspect | Convention |
|--------|------------|
| Base path | `/api/v1` |
| Resource naming | Plural nouns (`/users`, `/posts`) |
| HTTP methods | GET (read), POST (create), PUT (replace), PATCH (update), DELETE |
| Status codes | 200, 201, 204, 400, 401, 403, 404, 500 |
| Error format | `{ error: { code: string, message: string, details?: object } }` |
| Pagination | `?page=1&limit=20` with `X-Total-Count` header |

---

## Data Model (Prisma)

### Schema Location

```
apps/backend/prisma/schema.prisma
```

### Conventions

```prisma
model User {
  // Primary key - always UUID
  id        String   @id @default(uuid())

  // Timestamps - always include
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  // Soft delete (optional)
  deletedAt DateTime? @map("deleted_at")

  // Fields
  email     String   @unique
  name      String

  // Relations
  posts     Post[]

  // Table mapping (snake_case)
  @@map("users")
}
```

### Migration Workflow

```bash
# Create migration
pnpm db:migrate -- --name add_users_table

# Apply migrations
pnpm db:push

# Generate Prisma Client
pnpm db:generate

# Seed database
pnpm db:seed
```

---

## Security Considerations

### Authentication

- **Method**: JWT (JSON Web Tokens)
- **Storage**: httpOnly cookies (not localStorage)
- **Refresh**: Refresh token rotation
- **Expiry**: Access token 15min, Refresh token 7 days

### Authorization

- **Model**: Role-Based Access Control (RBAC)
- **Implementation**: Middleware + decorators
- **Roles**: `admin`, `user`, `guest`

### Input Validation

- **Backend**: Zod schemas for all inputs
- **Frontend**: Zod + React Hook Form
- **Never trust client data**

### Data Protection

- [ ] Passwords hashed with bcrypt (cost factor 12)
- [ ] Sensitive data encrypted at rest
- [ ] HTTPS enforced in production
- [ ] CORS configured properly
- [ ] Rate limiting on auth endpoints
- [ ] SQL injection prevented (Prisma parameterized queries)
- [ ] XSS prevented (React escaping + CSP headers)

---

## Deployment Architecture

### Environments

| Environment | Purpose | URL |
|-------------|---------|-----|
| Development | Local development | localhost:3000 |
| Staging | Pre-production testing | staging.example.com |
| Production | Live environment | example.com |

### Infrastructure

```
┌─────────────────────────────────────────────────────────────┐
│                        Cloudflare                           │
│                     (CDN, DDoS, WAF)                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer / Ingress                  │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │ Frontend │   │ Backend  │   │ Backend  │
        │  (CDN)   │   │   Pod 1  │   │   Pod 2  │
        └──────────┘   └──────────┘   └──────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │PostgreSQL│   │  Redis   │   │ Storage  │
        │ (Primary)│   │ Cluster  │   │   (S3)   │
        └──────────┘   └──────────┘   └──────────┘
```

---

## Decision Log

### ADR-001: [Decision Title]

**Date**: [YYYY-MM-DD]
**Status**: Accepted

**Context**: [What is the issue?]

**Decision**: [What was decided?]

**Consequences**:
- **Positive**: [Benefits]
- **Negative**: [Drawbacks]
- **Neutral**: [Other impacts]

---

## Appendix

### Technology Versions

| Technology | Version | Purpose |
|------------|---------|---------|
| Node.js | 20.x LTS | Runtime |
| TypeScript | 5.3+ | Type safety |
| React | 18.x | UI framework |
| PostgreSQL | 16.x | Database |
| Prisma | 5.x | ORM |
| Zod | 3.x | Validation |

### References

- [Feature-Sliced Design](https://feature-sliced.design/)
- [Vertical Slice Architecture](https://jimmybogard.com/vertical-slice-architecture/)
- [OpenAPI Specification](https://spec.openapis.org/oas/v3.1.0)
- [Prisma Documentation](https://www.prisma.io/docs)
