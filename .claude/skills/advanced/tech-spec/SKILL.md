---
name: advanced:tech-spec
description: "Техническая спецификация. Используй: 'tech spec', 'техническая спека'"
allowed-tools: [Read, Write, Edit, AskUserQuestion]
---

# Техническая спецификация

Lightweight техническая документация.

## Что это?

Краткая техническая спецификация для небольших проектов:
- Технологии
- Структура проекта
- API endpoints
- Модели данных

## Когда использовать?

- Маленький проект (Level 0-1)
- Не нужен полный PRD
- Quick prototype

## Как запустить?

```bash
/advanced:tech-spec
```

## Что включает?

### 1. Технологии
- Frontend stack
- Backend stack
- Database
- Infrastructure

### 2. Структура
```
project/
├── frontend/  (FSD)
└── backend/   (VSA)
```

### 3. API Endpoints
```
POST /api/auth/login
GET  /api/users
POST /api/users
```

### 4. Модели данных
```prisma
model User {
  id    String @id @default(uuid())
  email String @unique
}
```

## Результат

Документ `docs/tech-spec-{project}-{date}.md`.
