# TypeScript Strict Mode

Строгая типизация — защита от runtime ошибок.

## tsconfig.json

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  }
}
```

## Запрещено

### 1. any

```typescript
// ❌ BAD
function process(data: any) { ... }
const result: any = fetch(...);

// ✅ GOOD
function process(data: UserData) { ... }
const result: ApiResponse = await fetch(...);
```

### 2. Type assertions (as unknown as)

```typescript
// ❌ BAD
const user = data as unknown as User;
const id = value as string;

// ✅ GOOD
const user = userSchema.parse(data);  // Zod validation
if (typeof value === 'string') { ... }
```

### 3. Non-null assertion (!)

```typescript
// ❌ BAD
const name = user!.name;
document.getElementById('app')!.innerHTML = '';

// ✅ GOOD
const name = user?.name ?? 'Anonymous';
const app = document.getElementById('app');
if (app) app.innerHTML = '';
```

## Zod для Runtime Validation

Типы TypeScript стираются в runtime. Zod валидирует данные:

```typescript
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  age: z.number().min(0).optional(),
});

type User = z.infer<typeof UserSchema>;

// Безопасный parse
const user = UserSchema.parse(untrustedData);

// Или с обработкой ошибок
const result = UserSchema.safeParse(data);
if (!result.success) {
  console.error(result.error.issues);
}
```

## Utility Types

```typescript
// Предпочитай built-in types
Partial<User>           // все поля optional
Required<User>          // все поля required
Pick<User, 'id'|'name'> // только указанные
Omit<User, 'password'>  // без указанных
Record<string, number>  // объект с типизированными ключами
```

## Checklist

- [ ] strict: true в tsconfig
- [ ] Нет any в коде
- [ ] Нет as unknown as
- [ ] Zod для внешних данных (API, forms)
- [ ] Обработка null/undefined
