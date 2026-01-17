# FSD Architecture Rules (Frontend)

Feature-Sliced Design — архитектура с чёткими границами между слоями.

## Слои (сверху вниз)

```
src/
├── app/        # Инициализация, провайдеры, роутинг
├── pages/      # Композиция виджетов, 1 page = 1 route
├── widgets/    # Независимые UI-блоки со state
├── features/   # Бизнес-фичи (переиспользуемые)
├── entities/   # Бизнес-сущности (User, Product)
└── shared/     # Общий код (ui, lib, api, hooks, types)
```

## Import Rules

| Слой | Может импортировать |
|------|---------------------|
| app | pages, widgets, features, entities, shared |
| pages | widgets, features, entities, shared |
| widgets | features, entities, shared |
| features | entities, shared |
| entities | shared |
| shared | ничего выше |

**Золотое правило**: слой может импортировать только слои НИЖЕ себя.

## Segment Structure

Каждый слайс содержит сегменты:
- `ui/` — React компоненты
- `model/` — Zustand/Jotai stores, хуки состояния
- `api/` — TanStack Query hooks
- `lib/` — Утилиты слайса
- `config/` — Константы, конфиги

## Public API

Экспорт ТОЛЬКО через index.ts:

```typescript
// entities/user/index.ts
export { UserCard } from './ui/UserCard';
export { useUser } from './model/useUser';
export type { User } from './types';
```

## DO

```typescript
// pages/profile/ui/ProfilePage.tsx
import { UserCard } from '@/entities/user';        // ✅
import { EditProfileForm } from '@/features/profile'; // ✅
```

## DON'T

```typescript
// Импорт выше своего слоя
import { ProfilePage } from '@/pages/profile';  // ❌ из features

// Прямой импорт без index.ts
import { UserCard } from '@/entities/user/ui/UserCard'; // ❌

// Cross-slice в одном слое
import { ProductCard } from '../product'; // ❌ из entities/user
```

## Checklist

- [ ] Импорты идут только вниз по слоям
- [ ] Public API через index.ts
- [ ] Нет cross-slice импортов внутри слоя
- [ ] Shared не импортирует из других слоёв
