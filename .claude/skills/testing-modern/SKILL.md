---
name: testing-modern
description: Modern testing strategy with inverted pyramid
allowed-tools: [Bash, Read, Write, Edit, Grep]
---

# Modern Testing Strategy

Современный подход к тестированию: Inverted Testing Pyramid, TDD, accessibility-first.

## When to Use

- Перед написанием нового кода (TDD)
- При добавлении тестов к существующему коду
- Настройка тестовой инфраструктуры
- Проверка coverage и качества тестов

## Inverted Testing Pyramid

Традиционная пирамида устарела. Современный подход:

```
        ┌─────────────┐
        │   E2E 10%   │  ← Critical user journeys only
        ├─────────────┤
        │             │
        │ Integration │  ← Bulk of tests (70%)
        │    70%      │     API + DB + Services
        │             │
        ├─────────────┤
        │  Unit 20%   │  ← Pure functions, utils
        └─────────────┘
```

### Why Inverted?

1. **Integration tests catch real bugs** — Unit tests miss integration issues
2. **Faster feedback** — Vitest + containers = fast integration tests
3. **Less mocking hell** — Test real behavior, not mocks
4. **Confidence** — Integration tests = actual user scenarios

## TDD Workflow

### Red → Green → Refactor

```bash
# 1. RED: Write failing test
vitest run --filter "user registration"
# ✗ should create user with valid email

# 2. GREEN: Minimal code to pass
# Write just enough code

# 3. REFACTOR: Clean up
# Improve code, tests still pass
```

### TDD Commands

```bash
# Watch mode during development
pnpm test:watch

# Run specific test file
pnpm test src/features/auth/__tests__/auth.service.test.ts

# Run with coverage
pnpm test:coverage
```

## Vitest Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node', // or 'jsdom' for frontend
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: ['**/*.d.ts', '**/__mocks__/**'],
      thresholds: {
        statements: 80,
        branches: 80,
        functions: 80,
        lines: 80,
      },
    },
    setupFiles: ['./tests/setup.ts'],
    include: ['**/*.{test,spec}.{ts,tsx}'],
  },
});
```

## Test Structure

### Unit Test (20%)

```typescript
// src/shared/utils/__tests__/validate-email.test.ts
import { describe, it, expect } from 'vitest';
import { validateEmail } from '../validate-email';

describe('validateEmail', () => {
  it('returns true for valid email', () => {
    expect(validateEmail('user@example.com')).toBe(true);
  });

  it('returns false for invalid email', () => {
    expect(validateEmail('invalid')).toBe(false);
  });
});
```

### Integration Test (70%)

```typescript
// src/features/auth/__tests__/auth.integration.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { createTestApp } from '@/tests/helpers';
import { prisma } from '@/shared/db';

describe('Auth API', () => {
  let app: TestApp;

  beforeAll(async () => {
    app = await createTestApp();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('registers user and returns JWT', async () => {
    const res = await app.post('/api/auth/register', {
      email: 'test@example.com',
      password: 'SecurePass123!',
    });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('token');

    // Verify in database
    const user = await prisma.user.findUnique({
      where: { email: 'test@example.com' },
    });
    expect(user).toBeTruthy();
  });
});
```

### E2E Test (10%)

```typescript
// e2e/auth-flow.spec.ts
import { test, expect } from '@playwright/test';

test('complete registration flow', async ({ page }) => {
  await page.goto('/register');

  await page.fill('[data-testid="email"]', 'new@example.com');
  await page.fill('[data-testid="password"]', 'SecurePass123!');
  await page.click('[data-testid="submit"]');

  await expect(page).toHaveURL('/dashboard');
  await expect(page.locator('[data-testid="welcome"]')).toBeVisible();
});
```

## Playwright MCP Integration

```bash
# Run E2E with Playwright MCP
pnpm exec playwright test

# Visual regression
pnpm exec playwright test --update-snapshots

# Debug mode
pnpm exec playwright test --debug
```

## Coverage Requirements

| Metric     | Minimum | Target |
|------------|---------|--------|
| Statements | 80%     | 90%    |
| Branches   | 80%     | 85%    |
| Functions  | 80%     | 90%    |
| Lines      | 80%     | 90%    |

```bash
# Check coverage
pnpm test:coverage

# Fail if below threshold
pnpm test:coverage --coverage.thresholds.100
```

## Accessibility Testing

### jest-axe for Unit/Integration

```typescript
import { axe, toHaveNoViolations } from 'jest-axe';
import { render } from '@testing-library/react';

expect.extend(toHaveNoViolations);

it('has no accessibility violations', async () => {
  const { container } = render(<LoginForm />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

### Playwright for E2E A11y

```typescript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('page is accessible', async ({ page }) => {
  await page.goto('/login');

  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa'])
    .analyze();

  expect(results.violations).toEqual([]);
});
```

### WCAG Compliance Checklist

- [ ] Color contrast ratio ≥ 4.5:1
- [ ] All images have alt text
- [ ] Forms have labels
- [ ] Keyboard navigation works
- [ ] Focus indicators visible
- [ ] ARIA attributes correct

## Test File Naming

```
src/
├── features/
│   └── auth/
│       ├── auth.service.ts
│       └── __tests__/
│           ├── auth.service.test.ts      # Unit
│           └── auth.integration.test.ts  # Integration
└── e2e/
    └── auth-flow.spec.ts                 # E2E
```

## Quick Commands

```bash
# All tests
pnpm test

# Watch mode
pnpm test:watch

# Coverage report
pnpm test:coverage

# E2E only
pnpm test:e2e

# A11y audit
pnpm test:a11y
```

## See Also

- `vitest.config.ts` — Vitest configuration
- `playwright.config.ts` — Playwright setup
- `/ralph-loop` — Test Agent integration
