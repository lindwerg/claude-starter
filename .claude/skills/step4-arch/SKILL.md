---
name: step4-arch
description: "Шаг 4: Архитектура системы. Используй: 'архитектура', 'architecture', 'дизайн системы', 'step4'"
allowed-tools: [Read, Write, Edit, Glob, TodoWrite, AskUserQuestion, Task]
---

# Шаг 4: Архитектура системы

Техническое проектирование на основе требований.

## Что это?

System Design — преобразование PRD в технические решения:
- Выбор технологий
- Структура компонентов
- API контракты
- Модели данных
- Инфраструктура

## Когда использовать?

После `/step3-prd`, перед `/step5-sprint`.

## Как запустить?

```bash
/step4-arch
```

## Что получим?

Документ `docs/architecture-{project}-{date}.md` с:

---

## MANDATORY INTERVIEW PROCESS

**CRITICAL — ЗАДАЙ ВСЕ ВОПРОСЫ ПОСЛЕДОВАТЕЛЬНО**

Используй AskUserQuestion tool для КАЖДОГО вопроса. НЕ ПРОПУСКАЙ вопросы. НЕ генерируй документ пока не получишь ответы на ВСЕ вопросы.

### Секция 1: Architectural Drivers (3 вопроса)

**ОБЯЗАТЕЛЬНО задай ЭТИ вопросы:**

1. **Критичные NFR**
   ```
   Какие нефункциональные требования определяют архитектуру?
   Выбери 3-5 самых важных: Performance, Security, Scalability, Availability, Maintainability
   ```

2. **Архитектурные ограничения**
   ```
   Есть ли жесткие ограничения?
   Примеры: budget, existing infrastructure, team skills, compliance (GDPR, HIPAA)
   ```

3. **Trade-offs**
   ```
   Что важнее для этого проекта?
   - Скорость разработки vs масштабируемость?
   - Простота vs гибкость?
   - Монолит vs микросервисы?
   ```

**После получения ответов проверь качество:**
- Если > 5 NFR → спроси: "Какие 3 самые критичные?"
- Если нет trade-offs → спроси: "Что предпочтем если придется выбирать?"

---

### Секция 2: Architectural Pattern (4 вопроса)

**ОБЯЗАТЕЛЬНО задай ЭТИ вопросы:**

1. **High-level паттерн**
   ```
   Какой архитектурный паттерн подходит?
   Варианты:
   - Monolithic (все в одном процессе, простой deploy)
   - Modular Monolith (модули, но один процесс)
   - Microservices (независимые сервисы, сложнее)
   - Serverless (FaaS, managed infrastructure)
   ```

2. **Обоснование выбора**
   ```
   Почему именно этот паттерн?
   Учти: размер команды, сложность проекта, NFR, бюджет
   ```

3. **Коммуникация между компонентами**
   ```
   Если несколько компонентов/сервисов:
   - REST API?
   - GraphQL?
   - gRPC?
   - Message queue (RabbitMQ, Kafka)?
   ```

4. **Деплой модель**
   ```
   Как будем деплоить?
   - Docker containers?
   - Kubernetes?
   - Serverless (Lambda, Cloud Functions)?
   - Traditional VM/bare metal?
   ```

**После получения ответов проверь качество:**
- Если микросервисы для маленького проекта → спроси: "Точно нужна такая сложность?"
- Если монолит для большой нагрузки → спроси: "Как масштабироваться будем?"

---

### Секция 3: Frontend Architecture (FSD) (5 вопросов)

**ОБЯЗАТЕЛЬНО задай ЭТИ вопросы:**

1. **Основные страницы (pages)**
   ```
   Перечисли 3-7 основных routes.
   Примеры: Home, Dashboard, Profile, Settings, ProductList, ProductDetail
   ```

2. **Сложные UI блоки (widgets)**
   ```
   Перечисли 3-5 независимых UI блоков.
   Примеры: Header, Sidebar, ChartsWidget, NotificationPanel
   ```

3. **Бизнес-фичи (features)**
   ```
   Перечисли 5-10 переиспользуемых features.
   Примеры: auth, createPost, editProfile, filterProducts, addToCart
   ```

4. **Entities**
   ```
   Перечисли 3-7 основных бизнес-сущностей.
   Примеры: User, Product, Order, Comment, Character, Conversation
   ```

5. **State management**
   ```
   Нужен ли глобальный state?
   Если да — что там? (auth, user profile, theme, cart)
   Выбор: Zustand, Jotai, или local state?
   ```

**После получения ответов проверь качество:**
- Если > 10 pages → спроси: "Может объединить? Слишком много для MVP"
- Если widgets повторяют features → спроси: "Разделим widget (UI) и feature (логика)"
- Если нет entities → спроси: "Какие главные сущности предметной области?"

---

### Секция 4: Backend Architecture (VSA) (4 вопроса)

**ОБЯЗАТЕЛЬНО задай ЭТИ вопросы:**

1. **Features (вертикальные слайсы)**
   ```
   Перечисли 5-10 основных features.
   Примеры: auth, users, products, orders, conversations
   ```

2. **Slices внутри features**
   ```
   Для каждой feature — какие use-cases?
   Пример для auth: login, logout, register, refreshToken, resetPassword
   ```

3. **Shared компоненты**
   ```
   Что будет в shared/?
   Примеры: middleware (auth, error handling), utils (logger, validators), types
   ```

4. **Слои внутри slice**
   ```
   Какие слои нужны в каждом slice?
   Обычно: controller.ts, service.ts, repository.ts, dto.ts
   Нужны ли все?
   ```

**После получения ответов проверь качество:**
- Если < 3 features → спроси: "Точно так мало? Может есть еще домены?"
- Если слишком много slices → спроси: "Может объединить похожие?"

---

### Секция 5: API Contract (OpenAPI) (4 вопроса)

**ОБЯЗАТЕЛЬНО задай ЭТИ вопросы:**

1. **API стиль**
   ```
   REST или GraphQL?
   Если REST — версионирование? (/api/v1/)
   ```

2. **Аутентификация API**
   ```
   JWT tokens?
   OAuth 2.0?
   API keys?
   Session cookies?

   Где хранить токены? (localStorage, httpOnly cookies)
   Время жизни? Refresh mechanism?
   ```

3. **Основные endpoints**
   ```
   Перечисли 10-15 ключевых endpoints.
   Формат: METHOD /path - description

   Пример:
   POST /api/v1/auth/login - User login
   GET /api/v1/products - List products
   POST /api/v1/products - Create product
   ```

4. **Error handling**
   ```
   Формат ошибок?
   Коды: HTTP status + custom error codes?

   Пример:
   {
     "error": {
       "code": "AUTH_INVALID_CREDENTIALS",
       "message": "Email or password incorrect",
       "statusCode": 401
     }
   }
   ```

**После получения ответов проверь качество:**
- Если GraphQL для простого CRUD → спроси: "Точно нужен GraphQL?"
- Если нет версионирования → спроси: "Как handling breaking changes?"
- Если < 5 endpoints → спроси: "Точно покрывает все P0 stories?"

---

### Секция 6: Data Model (Prisma) (3 вопроса)

**ОБЯЗАТЕЛЬНО задай ЭТИ вопросы:**

1. **Entities (модели)**
   ```
   Перечисли все Prisma models.
   Для каждой укажи ключевые поля.

   Пример:
   User (id, email, name, createdAt)
   Product (id, title, price, userId, createdAt)
   ```

2. **Relationships**
   ```
   Как models связаны?
   Примеры:
   - User hasMany Products
   - Product belongsTo User
   - Order hasMany OrderItems
   - OrderItem belongsTo Product
   ```

3. **Индексы и constraints**
   ```
   Какие поля нужно индексировать?
   Примеры: email (unique), userId (index), createdAt (index)

   Какие unique constraints?
   ```

**После получения ответов проверь качество:**
- Если > 15 models → спроси: "Может упростить для MVP?"
- Если нет relationships → спроси: "Точно все entities независимы?"
- Если нет индексов → спроси: "На каких полях будут частые запросы?"

---

### Секция 7: NFR Mapping (6 вопросов)

**ОБЯЗАТЕЛЬНО задай ЭТИ вопросы:**

1. **Performance решения**
   ```
   Как достигнем performance NFR?
   Примеры: caching (Redis), CDN, DB query optimization, pagination
   ```

2. **Security решения**
   ```
   Как обеспечим security?
   Примеры: JWT validation, rate limiting, input sanitization, HTTPS, SQL injection prevention
   ```

3. **Scalability решения**
   ```
   Как масштабироваться?
   Примеры: horizontal scaling (Kubernetes), load balancer, DB read replicas, connection pooling
   ```

4. **Availability решения**
   ```
   Как обеспечим uptime?
   Примеры: health checks, auto-restart, multi-instance deployment, failover
   ```

5. **Monitoring & Logging**
   ```
   Что мониторим?
   Metrics: latency, error rate, throughput, CPU/memory

   Что логируем?
   Structured logs (JSON), log levels (error, warn, info)

   Инструменты: Prometheus, Grafana, Sentry, Datadog?
   ```

6. **Testing strategy**
   ```
   Какие типы тестов?
   - Unit tests (20%)
   - Integration tests (70%)
   - E2E tests (10%)

   Coverage target? (80%+)
   TDD подход?
   ```

**После получения ответов проверь качество:**
- Если нет caching но нужен performance → спроси: "Как без кэша достигнем < 200ms?"
- Если нет monitoring → спроси: "Как узнаем о проблемах?"

---

### Секция 8: Technology Stack (5 вопросов)

**ОБЯЗАТЕЛЬНО задай ЭТИ вопросы:**

1. **Frontend stack**
   ```
   React / Vue / Angular / Svelte?
   Почему этот выбор?

   Дополнительно:
   - State: Zustand / Jotai / Redux?
   - Routing: React Router / TanStack Router?
   - Forms: React Hook Form / Formik?
   - Styling: Tailwind / CSS-in-JS / CSS Modules?
   ```

2. **Backend stack**
   ```
   Node.js / Python / Go / Java?
   Framework: Express / Fastify / NestJS?
   Почему этот выбор?
   ```

3. **Database**
   ```
   PostgreSQL / MySQL / MongoDB / SQLite?
   Почему?

   ORM: Prisma / TypeORM / Drizzle?
   ```

4. **Infrastructure**
   ```
   Где хостим?
   - Cloud: AWS / GCP / Azure / Vercel / Railway?
   - Docker + Kubernetes?
   - Serverless?

   CI/CD: GitHub Actions / GitLab CI / CircleCI?
   ```

5. **External services**
   ```
   Какие сторонние сервисы нужны?
   Примеры:
   - Auth: Auth0, Clerk, Supabase Auth?
   - Payments: Stripe, PayPal?
   - Email: SendGrid, Resend?
   - Storage: S3, Cloudinary?
   - Analytics: Mixpanel, Amplitude?
   ```

**После получения ответов проверь качество:**
- Если выбор не обоснован → спроси: "Почему именно эта технология?"
- Если слишком много внешних сервисов → спроси: "Что критично для MVP?"

---

### Секция 9: Deployment Architecture (3 вопроса)

**ОБЯЗАТЕЛЬНО задай ЭТИ вопросы:**

1. **Environments**
   ```
   Какие окружения нужны?
   - dev (local)
   - staging / preview
   - production

   Как настраивать? (.env файлы, secrets manager)
   ```

2. **Deployment flow**
   ```
   Как происходит деплой?
   1. Git push to branch?
   2. CI runs tests?
   3. Build Docker image?
   4. Deploy to cluster?
   5. Run migrations?
   6. Health check?

   Rollback strategy?
   ```

3. **Infrastructure as Code**
   ```
   Нужен ли IaC?
   Terraform / Pulumi / CloudFormation?

   Или manual setup?
   ```

**После получения ответов проверь качество:**
- Если нет staging → спроси: "Как тестировать перед production?"
- Если нет rollback → спроси: "Что если деплой сломался?"

---

## Answer Quality Gates

После КАЖДОГО ответа пользователя проверь качество:

| Проблема ответа | Уточняющий вопрос |
|-----------------|-------------------|
| Выбор технологии без обоснования | "Почему именно эта технология?" |
| > 10 pages/features | "Может упростить для MVP?" |
| Нет индексов для БД | "На каких полях частые запросы?" |
| Нет monitoring | "Как узнаем о проблемах в production?" |
| Нет caching но нужен performance | "Как достигнем < 200ms без кэша?" |
| Микросервисы для маленького проекта | "Точно нужна такая сложность?" |

**ПРАВИЛО**: Если ответ попадает в таблицу — НЕМЕДЛЕННО задай уточняющий вопрос. НЕ ПЕРЕХОДИ к следующему вопросу.

---

## Context Management

Веди контекст ВСЕХ ответов в памяти:

**После КАЖДОГО ответа пользователя:**

1. **Подтверди получение:**
   ```
   ✅ Записал: [краткое извлечение]
   Переходим к следующему вопросу...
   ```

2. **Перед финальной генерацией покажи ПОЛНЫЙ summary:**
   ```
   ## Собранная информация

   ### 1. Architectural Pattern
   - Pattern: [выбор]
   - Rationale: [обоснование]

   ### 2. Frontend (FSD)
   - Pages: [список]
   - Features: [список]
   - Entities: [список]

   ### 3. Backend (VSA)
   - Features: [список]
   - Slices: [список]

   ### 4. Tech Stack
   - Frontend: [стек]
   - Backend: [стек]
   - Database: [выбор]

   Всё верно? Могу генерировать architecture.md.
   ```

**КРИТИЧНО**: НЕ используй Write/Edit ДО финальной генерации. Храни всё в памяти/контексте.

---

## Pre-Generation Checklist

**БЛОКИРУЮЩЕЕ ПРАВИЛО**: НЕ генерируй документ, пока НЕ выполнены все проверки:

- [ ] Все 9 секций опрошены (37 вопросов минимум)
- [ ] Выбран архитектурный паттерн с обоснованием
- [ ] Определены все FSD слои (pages, widgets, features, entities)
- [ ] Определены все VSA features и slices
- [ ] Есть минимум 10 API endpoints
- [ ] Определены Prisma models с relationships
- [ ] Есть NFR решения (performance, security, monitoring)
- [ ] Выбран tech stack с обоснованием
- [ ] Пользователь подтвердил финальный summary

**Если хоть один пункт НЕ выполнен:**
→ Покажи пользователю что не хватает
→ Спроси недостающие вопросы
→ НЕ генерируй документ

**Только когда ВСЕ пункты ✅:**
→ Переходи к секции "Call BMAD Backend" ниже

---

## Call BMAD Backend

После сбора всех 37 ответов, передай их в BMAD систему для генерации архитектурного документа **и автоматического обновления CLAUDE.md (Part 13)**.

### Шаг 1: Создай YAML файл с ответами

Создай файл `/tmp/step4-answers.yaml` со всеми собранными ответами:

```yaml
# Metadata
collected_at: "{current_timestamp_ISO8601}"
collected_by: "step4-arch"

# Section 1: Architectural Drivers
critical_nfrs:
  - "{NFR с обоснованием 1}"
  - "{NFR с обоснованием 2}"
  - "{NFR с обоснованием 3}"
architectural_constraints: "{бюджет, команда, сроки}"
tradeoffs: "{Simplicity > Scalability или другие trade-offs}"

# Section 2: Architectural Pattern
architectural_pattern: "{Modular Monolith | Microservices | Event-Driven}"
pattern_rationale: "{почему выбрали этот паттерн}"
component_communication: "{как компоненты взаимодействуют}"
deployment_strategy: "{Docker, k8s, strategy}"

# Section 3: Frontend Architecture (FSD)
fsd_layers: "app, pages, widgets, features, entities, shared"
fsd_key_features:
  - "{features/feature-1: описание}"
  - "{features/feature-2: описание}"
  - "{features/feature-3: описание}"
fsd_state_management: "{Zustand | Redux | Context}"
fsd_routing: "{React Router v6 | Next.js routing}"
fsd_styling: "{Tailwind CSS | Styled Components}"

# Section 4: Backend Architecture (VSA)
vsa_structure: "features/{domain}/{slice}/ with controller/service/repository"
vsa_key_slices:
  - "{features/auth/login/, features/auth/register/}"
  - "{features/users/createUser/, features/users/getUsers/}"
  - "{другие slices}"
vsa_shared_modules: "{shared/middleware/, shared/utils/, shared/types/}"
vsa_database_access: "{Prisma ORM | TypeORM}"

# Section 5: API Contract (OpenAPI)
api_architecture: "REST API with JWT authentication"
api_versioning: "/api/v1/ for all endpoints"
api_authentication: "JWT tokens (access: 15min, refresh: 7 days)"
api_endpoints: |
  POST /api/v1/auth/register - User registration
  POST /api/v1/auth/login - User login (returns JWT)
  GET /api/v1/users - List users (paginated)
  POST /api/v1/users - Create user
  ...

# Section 6: Data Model (Prisma)
data_model: |
  User (id, email, name, role, createdAt)
    - Has many: ChatHistory
  Entity2 (fields...)
    - Relationships
  ...
database_design: "PostgreSQL with Prisma schema, indexes on userId, category, status"

# Section 7: NFR Mapping
nfr_performance_solution: "{Redis caching, CDN, DB indexing}"
nfr_security_solution: "{bcrypt, JWT, HTTPS, input validation with Zod}"
nfr_scalability_solution: "{Stateless API, horizontal scaling, read replicas}"
nfr_availability_solution: "{Health checks, auto-restart, backups every 6h}"
nfr_usability_solution: "{Responsive design, <3s page load, tooltips}"

# Section 8: Technology Stack
frontend_stack: "React 18, TypeScript strict, TanStack Query, Zustand, Tailwind CSS"
frontend_rationale: "{Modern React with strict typing, excellent DX}"
backend_stack: "Node.js 20, Express, Prisma, PostgreSQL 16, Zod validation"
backend_rationale: "{JavaScript throughout, fast development}"
database_stack: "PostgreSQL 16 with pg_trgm extension"
database_rationale: "{Reliable, ACID compliant, full-text search}"
infrastructure_stack: "Docker, Kubernetes (GKE), Redis, Cloudflare CDN"
infrastructure_rationale: "{Standard container orchestration}"
third_party_services: "{Auth0, SendGrid, etc.}"

# Section 9: Deployment Architecture
deployment_environment: "{GKE | AWS ECS | Azure AKS}"
deployment_pipeline: "GitHub Actions: Build → Test → Docker → Deploy to staging → Manual prod"
monitoring_stack: "Datadog for metrics/APM, Sentry for errors, CloudWatch logs"
```

**Используй Write tool для создания этого файла.**

### Шаг 2: Вызови variable-bridge.sh

```bash
bash ~/.claude/skills/bmad/bmad-v6/utils/variable-bridge.sh \
  architecture \
  /tmp/step4-answers.yaml
```

**Что происходит:**
1. variable-bridge.sh загружает YAML
2. Экспортирует все 37 переменных как BMAD_*
3. Устанавливает BMAD_BATCH_MODE=true
4. Вызывает команду /architecture

**Результат:**
- Команда architecture использует BMAD_* переменные
- Загружает template из `~/.claude/config/bmad/templates/architecture.md`
- Подставляет переменные
- Генерирует документ `docs/architecture-{project}-{date}.md`
- **🚀 Выполняет Part 13: автоматически обновляет CLAUDE.md с проектной архитектурой!**
- Обновляет workflow status

### Шаг 3: Сообщи пользователю

```
✓ Архитектура создана!

Документ: docs/architecture-{project}-{date}.md

🎉 ВАЖНО: CLAUDE.md автоматически обновлён с:
- Architectural Pattern: {pattern}
- Technology Stack (Backend, Frontend, Database)
- Data Model (Core Entities)
- API Guidelines
- Critical NFRs

Все будущие Claude сессии теперь знают архитектуру проекта!

Следующий шаг: /step5-sprint
```

---

### 1. Обзор системы
- High-level диаграмма
- Ключевые компоненты
- Потоки данных

### 2. Frontend (FSD)
```
src/
├── app/          # Providers, routing
├── pages/        # Route pages
├── widgets/      # Complex UI blocks
├── features/     # Business features
├── entities/     # Business entities
└── shared/       # UI kit, hooks, api
```

### 3. Backend (VSA)
```
src/
├── features/
│   └── [feature]/
│       └── [slice]/
│           ├── controller.ts
│           ├── service.ts
│           ├── repository.ts
│           └── dto.ts
└── shared/
```

### 4. API Контракт
- OpenAPI 3.1 спецификация
- Endpoints с request/response schemas
- Error codes

### 5. Модель данных
- Prisma schema
- Связи между entities
- Индексы

### 6. Инфраструктура
- Docker services
- Environment variables
- CI/CD pipeline

## Принципы

- **FSD** для frontend (импорты только вниз)
- **VSA** для backend (vertical slices)
- **API-First** (OpenAPI как источник правды)
- **TypeScript strict** (no any, Zod validation)

## Следующий шаг

После архитектуры переходи к планированию спринта:

```
/step5-sprint
```
