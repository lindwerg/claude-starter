# VSA Architecture Rules (Backend)

Vertical Slice Architecture — каждая фича изолирована и содержит все слои.

## Структура

```
src/
├── features/
│   └── [feature]/
│       └── [slice]/           # use-case (createUser, getUsers)
│           ├── controller.ts  # HTTP layer
│           ├── service.ts     # Business logic
│           ├── repository.ts  # Data access
│           ├── dto.ts         # Zod schemas + types
│           └── index.ts       # Public API
├── shared/
│   ├── middleware/
│   ├── utils/
│   └── types/
└── openapi.yaml
```

## REPR Pattern (Request-Endpoint-Presenter-Response)

Каждый endpoint — отдельный слайс:
- **Request** → dto.ts (Zod validation)
- **Endpoint** → controller.ts (HTTP routing)
- **Presenter** → service.ts (business logic)
- **Response** → dto.ts (response schema)

## CQRS Light

Разделяй команды и запросы:
- `createUser/` — Command (изменяет состояние)
- `getUsers/` — Query (только чтение)

## Import Rules

| Откуда | Куда | Разрешено |
|--------|------|-----------|
| Controller | Service | Да, через index.ts |
| Service | Repository | Да, через index.ts |
| Feature A | Feature B | Нет, через shared/ |
| Любой слой | shared/ | Да |

## DO

```typescript
// features/users/createUser/index.ts
export { createUserController } from './controller';
export { CreateUserDto, CreateUserResponse } from './dto';
```

## DON'T

```typescript
// Прямой импорт файлов (минуя index.ts)
import { userService } from '../getUsers/service'; // ❌

// Cross-feature импорт
import { orderService } from '../../orders/createOrder/service'; // ❌
```

## Checklist

- [ ] Каждый use-case в отдельной папке
- [ ] Импорты только через index.ts
- [ ] Zod схемы в dto.ts
- [ ] Нет cross-feature зависимостей
