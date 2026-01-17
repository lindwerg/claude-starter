# API-First Development

OpenAPI spec — единственный источник правды для API.

## Принцип

```
openapi.yaml → Генерация типов → Backend/Frontend
     ↑
   Изменения API начинаются здесь
```

## Структура openapi.yaml

```yaml
openapi: 3.1.0
info:
  title: My API
  version: 1.0.0

paths:
  /users:
    get:
      operationId: getUsers
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'

components:
  schemas:
    User:
      type: object
      required: [id, email]
      properties:
        id:
          type: string
          format: uuid
        email:
          type: string
          format: email
```

## Генерация типов

```bash
# Генерация TypeScript типов из OpenAPI
pnpm generate-api-types

# Под капотом (openapi-typescript)
npx openapi-typescript ./openapi.yaml -o ./src/shared/api/types.ts
```

## Версионирование

```
/api/v1/users   # Текущая версия
/api/v2/users   # Новая версия (breaking changes)
```

Правила версионирования:
- **Patch**: исправления без изменения контракта
- **Minor**: новые endpoints, optional поля
- **Major**: breaking changes → новая версия пути

## Валидация

Backend валидирует входящие запросы против spec:

```typescript
import { OpenAPIValidator } from 'express-openapi-validator';

app.use(OpenAPIValidator.middleware({
  apiSpec: './openapi.yaml',
  validateRequests: true,
  validateResponses: true,
}));
```

## Workflow

1. **Spec First** — измени openapi.yaml
2. **Generate** — `pnpm generate-api-types`
3. **Implement** — backend endpoint
4. **Test** — integration tests против spec
5. **Frontend** — используй сгенерированные типы

## DO

```typescript
// Импорт сгенерированных типов
import type { User, CreateUserRequest } from '@/shared/api/types';

// TanStack Query с типами
const { data } = useQuery<User[]>({
  queryKey: ['users'],
  queryFn: () => api.get('/users'),
});
```

## DON'T

```typescript
// Ручные типы для API (рассинхрон со spec)
interface User {
  id: string;
  email: string;
}

// Изменение API без обновления spec
app.post('/users', (req, res) => { ... }); // ❌ spec не обновлён
```

## Checklist

- [ ] openapi.yaml актуален
- [ ] Типы сгенерированы из spec
- [ ] Backend валидирует против spec
- [ ] Frontend использует сгенерированные типы
- [ ] Breaking changes = новая версия API
