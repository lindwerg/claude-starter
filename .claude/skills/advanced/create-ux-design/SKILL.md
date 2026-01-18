---
name: advanced:create-ux-design
description: "UX дизайн. Используй: 'ux design', 'дизайн интерфейса', 'wireframes'"
allowed-tools: [Read, Write, AskUserQuestion]
---

# UX Дизайн

Проектирование пользовательского интерфейса.

## Что это?

Создание UX артефактов:
- User flows
- Wireframes (text-based)
- Component specs
- Accessibility requirements

## Когда использовать?

- Проектируешь новый интерфейс
- Нужны wireframes для frontend

## Как запустить?

```bash
/advanced:create-ux-design "название экрана"
```

## Что создаётся?

### User Flow
```
[Страница A] → [Действие] → [Страница B]
```

### Wireframe (ASCII)
```
┌─────────────────────────┐
│ Header                  │
├─────────────────────────┤
│ [Input: Email]          │
│ [Input: Password]       │
│ [Button: Login]         │
└─────────────────────────┘
```

### Component Spec
- States (default, hover, focus, error)
- Variants (primary, secondary)
- Accessibility (aria-labels, keyboard nav)

## Результат

Документ `docs/ux-{screen}-{date}.md`.
