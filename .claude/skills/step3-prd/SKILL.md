---
name: step3-prd
description: "Шаг 3: PRD документ. Используй: 'prd', 'требования', 'product requirements', 'step3'"
allowed-tools: [Read, Write, Edit, Glob, TodoWrite, AskUserQuestion]
---

# Шаг 3: Product Requirements Document

Детальный документ требований к продукту.

## Что это?

PRD (Product Requirements Document) — полная спецификация продукта:
- Детальные user stories
- Функциональные требования
- Нефункциональные требования
- Acceptance criteria для каждой фичи

## Когда использовать?

После `/step2-brief`, перед `/step4-arch`.

## Как запустить?

```bash
/step3-prd
```

## Что получим?

Документ `docs/prd-{project}-{date}.md` с:

### 1. Обзор продукта
- Vision statement
- Цели продукта
- Ключевые метрики

### 2. User Stories
```
Как [роль], я хочу [действие], чтобы [результат]
```

### 3. Функциональные требования
- Группировка по фичам
- Приоритеты (P0 / P1 / P2)
- Зависимости

### 4. Нефункциональные требования
- Performance (время ответа, RPS)
- Security (аутентификация, авторизация)
- Scalability (сколько пользователей)
- Accessibility (WCAG уровень)

### 5. Acceptance Criteria
Для каждой story:
```
Given [предусловие]
When [действие]
Then [результат]
```

### 6. Риски и допущения

## Советы

- Каждая story должна быть независимой
- P0 = блокер релиза, P1 = важно, P2 = nice to have
- Acceptance criteria — это будущие тесты
- Не перегружай P0, реально оцени scope

## Следующий шаг

После PRD переходи к архитектуре:

```
/step4-arch
```
