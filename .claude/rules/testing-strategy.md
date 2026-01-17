# Testing Strategy

Inverted Test Pyramid — интеграционные тесты в приоритете.

## Распределение тестов

```
        ┌─────────┐
        │  E2E    │  5-10%  (Playwright)
        │  5-10%  │
     ┌──┴─────────┴──┐
     │  Integration  │  70%  (Vitest + Testing Library)
     │     70%       │
  ┌──┴───────────────┴──┐
  │       Unit          │  20%  (Vitest)
  │        20%          │
  └─────────────────────┘
```

## Минимальные требования

- **Coverage**: 80% minimum
- **TDD**: обязателен для бизнес-логики
- **CI**: тесты блокируют merge

## Unit Tests (20%)

Чистые функции, утилиты, валидаторы:

```typescript
// shared/lib/formatPrice.test.ts
describe('formatPrice', () => {
  it('formats number with currency', () => {
    expect(formatPrice(1000)).toBe('1 000 ₽');
  });
});
```

## Integration Tests (70%)

API endpoints, React компоненты с моками:

```typescript
// features/auth/login.integration.test.ts
describe('POST /auth/login', () => {
  it('returns token for valid credentials', async () => {
    const res = await request(app)
      .post('/auth/login')
      .send({ email: 'test@test.com', password: 'pass' });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('token');
  });
});
```

## E2E Tests (5-10%)

Критические user flows через Playwright:

```typescript
// e2e/checkout.spec.ts
test('user can complete checkout', async ({ page }) => {
  await page.goto('/products');
  await page.click('[data-testid="add-to-cart"]');
  await page.click('[data-testid="checkout"]');
  await expect(page.locator('.success')).toBeVisible();
});
```

## Accessibility

jest-axe для a11y проверок:

```typescript
import { axe } from 'jest-axe';

it('has no accessibility violations', async () => {
  const { container } = render(<Button>Click</Button>);
  expect(await axe(container)).toHaveNoViolations();
});
```

## TDD Workflow

1. **Red** — пиши failing test
2. **Green** — минимальный код для прохождения
3. **Refactor** — улучшай без изменения поведения

## Checklist

- [ ] Coverage >= 80%
- [ ] Интеграционные тесты для API
- [ ] E2E для критических flows
- [ ] A11y тесты для UI компонентов
- [ ] TDD для бизнес-логики
