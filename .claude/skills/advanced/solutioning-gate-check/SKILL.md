---
name: advanced:solutioning-gate-check
description: "Проверка архитектурного решения. Используй: 'gate check', 'проверка решения'"
allowed-tools: [Read, Glob, Grep]
---

# Solutioning Gate Check

Валидация архитектурного решения.

## Что это?

Проверка качества архитектуры перед имплементацией:
- Соответствие требованиям PRD
- Покрытие всех use cases
- Технические риски
- Соблюдение FSD/VSA

## Когда использовать?

- После `/step4-arch`
- Перед началом sprint planning
- При review архитектуры

## Как запустить?

```bash
/advanced:solutioning-gate-check
```

## Checklist

### Требования
- [ ] Все P0 requirements покрыты
- [ ] Acceptance criteria реализуемы
- [ ] Non-functional requirements учтены

### Архитектура
- [ ] FSD структура корректна (frontend)
- [ ] VSA структура корректна (backend)
- [ ] API контракт полный

### Риски
- [ ] Технические риски идентифицированы
- [ ] Mitigation strategies описаны
- [ ] Dependencies понятны

## Результат

Отчёт о готовности к имплементации.
