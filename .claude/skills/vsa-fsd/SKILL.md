---
name: vsa-fsd
description: Validate VSA and FSD architecture
allowed-tools: [Bash, Read, Grep, Glob]
---

# VSA/FSD Architecture Validator

Валидация архитектурных паттернов: Vertical Slice Architecture (backend) и Feature-Sliced Design (frontend).

## When to Use

- После создания нового feature/slice
- Перед коммитом изменений в архитектуре
- При code review для проверки структуры
- Когда CI падает на `validate:vsa` или `validate:fsd`

## VSA Validation (Backend)

### Required Structure

```
src/
├── features/
│   └── [feature-name]/
│       ├── [feature].controller.ts   # HTTP handlers
│       ├── [feature].service.ts      # Business logic
│       ├── [feature].repository.ts   # Data access
│       ├── [feature].schema.ts       # Zod validation
│       ├── [feature].types.ts        # TypeScript types
│       └── index.ts                  # Public exports
├── shared/
│   ├── middleware/
│   ├── utils/
│   ├── types/
│   └── config/
├── openapi.yaml                      # API contract
└── prisma/schema.prisma
```

### VSA Rules

1. **Self-contained slices**: Каждый feature содержит все свои слои
2. **No cross-feature imports**: features/auth НЕ импортирует из features/users напрямую
3. **Shared only for common code**: middleware, utils, types — только общий код
4. **Repository pattern**: Вся работа с БД через repository
5. **Zod validation**: Все входные данные валидируются schema.ts

### VSA Import Rules

```typescript
// ALLOWED
import { authMiddleware } from '@/shared/middleware';
import { User } from '@prisma/client';

// FORBIDDEN - cross-feature import
import { UserService } from '@/features/users/users.service';
```

### Validation Command

```bash
npm run validate:vsa
```

## FSD Validation (Frontend)

### Required Structure

```
src/
├── app/          # Providers, global styles, routing setup
├── pages/        # Route components (1 page = 1 route)
├── widgets/      # Composite UI blocks with own state
├── features/     # User interactions, business features
├── entities/     # Business entities (User, Product, Order)
└── shared/       # Reusable: ui/, lib/, hooks/, api/, types/
```

### FSD Layer Import Rules

| Layer    | Can Import From                    |
|----------|-----------------------------------|
| app      | pages, widgets, features, entities, shared |
| pages    | widgets, features, entities, shared |
| widgets  | features, entities, shared        |
| features | entities, shared                  |
| entities | shared                            |
| shared   | NOTHING (only external libs)      |

### FSD Violations Examples

```typescript
// VIOLATION: feature imports from another feature
// File: src/features/auth/login-form.tsx
import { CartButton } from '@/features/cart';  // WRONG!

// FIX: Move shared logic to entities or shared
import { useCart } from '@/entities/cart';     // OK

// VIOLATION: entity imports from feature
// File: src/entities/user/model.ts
import { loginUser } from '@/features/auth';   // WRONG!

// FIX: Keep entities pure, features use entities
```

### Validation Command

```bash
npm run validate:fsd
```

## Quick Validation

```bash
# Validate both architectures
npm run validate:arch

# Check specific feature
npm run validate:vsa -- --feature=auth
npm run validate:fsd -- --slice=features/auth
```

## Common Violations & Fixes

### 1. Missing index.ts barrel export

```bash
# Error: Feature 'payments' missing index.ts
# Fix:
echo "export * from './payments.controller';" > src/features/payments/index.ts
```

### 2. Cross-slice dependency

```bash
# Error: features/orders imports from features/users
# Fix: Extract shared logic to entities/user or shared/
```

### 3. Business logic in controller

```bash
# Error: Controller contains business logic
# Fix: Move to service, controller only handles HTTP
```

### 4. Direct Prisma in service

```bash
# Error: Service uses Prisma directly
# Fix: Use repository pattern, inject repository
```

## Integration with CI

```yaml
# .github/workflows/validate.yml
validate:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - run: pnpm install
    - run: pnpm validate:vsa
    - run: pnpm validate:fsd
```

## See Also

- `~/.claude/CLAUDE.md` — Global FSD/VSA standards
- `/docs/architecture.md` — Project architecture decisions
