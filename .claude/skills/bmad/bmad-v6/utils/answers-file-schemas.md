# Answers File Schemas

This document defines the YAML structure for answers files used by step-* skills to pass variables to BMAD commands.

## Overview

When a step-* skill collects answers through its interactive interview, it stores them in a temporary YAML file (`/tmp/stepN-answers.yaml`). This file is then passed to the corresponding BMAD command via `variable-bridge.sh`.

## General Structure

All answers files follow this pattern:

```yaml
# Metadata (automatically added)
collected_at: "2026-01-19T05:30:00Z"  # ISO 8601 timestamp
collected_by: "step2-brief"            # Skill name

# Answer variables (specific to each workflow)
variable_name: "value"
another_variable: "value"

# Lists (for multi-value answers)
list_variable:
  - "item 1"
  - "item 2"
```

## Schema: step2-answers.yaml (Product Brief)

**Used by:** `step2-brief` → `product-brief`
**Variables:** 29 total

```yaml
# Metadata
collected_at: "2026-01-19T05:30:00Z"
collected_by: "step2-brief"

# Section 1: Краткое описание
executive_summary: "AI-powered chatbot for customer support automation"
vision: "Become the leading AI support solution for SMBs"

# Section 2: Проблема
problem_statement: "Manual support tickets take 24+ hours to resolve"
why_now: "Customer expectations for instant support are increasing"
current_solution: "Manual email support with 3-person team"

# Section 3: Целевая аудитория
primary_users: "Customer support teams in SMBs (10-100 employees)"
user_personas: "Support Manager (decision maker), Support Agent (daily user)"
user_pain_points: "High ticket volume, repetitive questions, slow response times"

# Section 4: Решение
proposed_solution: "AI chatbot that handles 80% of common queries automatically"
key_features:
  - "Natural language query understanding"
  - "FAQ knowledge base integration"
  - "Escalation to human agents"
unique_value_proposition: "80% faster response time with 50% cost reduction"

# Section 5: Бизнес-цели
business_goals:
  - "Reduce average response time from 24h to <1h"
  - "Handle 10,000 queries/month with same team size"
  - "Achieve 90% customer satisfaction score"

# Section 6: Метрики успеха
success_metrics:
  - "Response time: 95th percentile < 1 hour"
  - "Resolution rate: 80% without human escalation"
  - "Customer satisfaction: >90%"

# Section 7: Scope
in_scope:
  - "Text-based chatbot (web and mobile)"
  - "FAQ knowledge base (up to 500 articles)"
  - "Ticket routing to human agents"
out_of_scope:
  - "Voice support"
  - "Multi-language support (English only in v1)"
  - "Advanced analytics dashboard"

# Section 8: Стейкхолдеры
stakeholders:
  - "CEO: Budget approval, strategic alignment"
  - "Head of Support: Requirements, adoption"
  - "Engineering Lead: Technical feasibility"

# Section 9: Ограничения
constraints:
  - "Budget: $50,000 for development"
  - "Timeline: 3 months to MVP"
  - "Team: 2 developers, 1 designer"
technical_constraints: "Must integrate with existing Zendesk system"
compliance_requirements: "GDPR compliant data handling"

# Section 10: Assumptions
assumptions:
  - "80% of queries are repetitive and can be automated"
  - "Users will adopt chatbot over email gradually"
  - "Existing FAQ content is sufficient for training"

# Section 11: Риски
risks:
  - "Risk: Low user adoption | Mitigation: Phased rollout with training"
  - "Risk: AI accuracy <80% | Mitigation: Human-in-loop review for 1st month"
  - "Risk: Integration delays | Mitigation: Zendesk API sandbox testing early"
```

**Variable Count:** 29 variables (including lists)

---

## Schema: step3-answers.yaml (PRD)

**Used by:** `step3-prd` → `prd`
**Variables:** 23 total

```yaml
# Metadata
collected_at: "2026-01-19T06:00:00Z"
collected_by: "step3-prd"

# Section 1: Обзор продукта
product_overview: "AI chatbot SaaS for customer support automation"
target_users: "SMB support teams (10-100 employees)"
key_differentiators: "Plug-and-play Zendesk integration, 80% automation rate"

# Section 2: User Stories (formatted text)
user_stories: |
  US-001: As a Support Agent, I want to see chatbot suggestions, so I can respond faster
  US-002: As a Customer, I want instant answers to common questions, so I don't wait 24h
  US-003: As a Support Manager, I want escalation metrics, so I know what needs improvement

# Section 3: Functional Requirements
functional_requirements: |
  FR-001: Natural Language Understanding
  Priority: Must Have
  Description: System shall parse customer queries and match to FAQ articles
  Acceptance Criteria:
  - [ ] 90% accuracy on 100-query test set
  - [ ] Response time < 2 seconds

  FR-002: FAQ Knowledge Base
  Priority: Must Have
  Description: System shall allow CRUD operations on FAQ articles
  Acceptance Criteria:
  - [ ] Support up to 500 articles
  - [ ] Full-text search with ranking
  - [ ] Markdown formatting support

  [... more FRs ...]

# Section 4: Non-Functional Requirements
nfr_performance: "API response time p95 < 200ms, support 100 concurrent users"
nfr_security: "JWT authentication, HTTPS only, GDPR-compliant data encryption"
nfr_scalability: "Horizontal scaling to 10,000 queries/day"
nfr_availability: "99.5% uptime SLA (4h downtime/month acceptable)"
nfr_usability: "< 10 minute onboarding for new support agents"
nfr_maintainability: "TypeScript strict mode, 80% test coverage, CI/CD pipeline"

# Section 5: Epics
epics: |
  EPIC-001: Authentication & Authorization
  Stories: User registration, Login, Role-based access
  Priority: Must Have
  Estimate: 8 story points

  EPIC-002: Chatbot Engine
  Stories: NLU integration, FAQ matching, Response generation
  Priority: Must Have
  Estimate: 13 story points

  [... more epics ...]

# Section 6: Acceptance Criteria (global)
acceptance_criteria: |
  AC-001: All Must Have FRs implemented and tested
  AC-002: NFR-001 (Performance) validated with load testing
  AC-003: Security audit passed (no critical/high vulnerabilities)
  AC-004: User acceptance testing completed with >80% satisfaction

# Section 7: Риски
risks_technical: "NLU accuracy may require extensive training data"
risks_business: "User adoption dependent on change management strategy"
risks_timeline: "Zendesk API limitations may cause integration delays"

# Section 8: Допущения
assumptions: |
  - Zendesk API will remain stable during development
  - FAQ content is ready and well-structured
  - Users have modern browsers (Chrome/Firefox last 2 versions)

# Section 9: Out of Scope
out_of_scope: |
  - Voice/phone support
  - Multi-language (English only v1)
  - Advanced sentiment analysis
  - Custom reporting dashboards
```

**Variable Count:** 23 variables

---

## Schema: step4-answers.yaml (Architecture)

**Used by:** `step4-arch` → `architecture`
**Variables:** 37 total

```yaml
# Metadata
collected_at: "2026-01-19T06:30:00Z"
collected_by: "step4-arch"

# Section 1: Architectural Drivers
critical_nfrs:
  - "Performance: p95 < 200ms API response"
  - "Security: GDPR compliance, JWT auth"
  - "Scalability: 10,000 queries/day"

architectural_constraints: "Budget: $50k, Team: 2 devs, Timeline: 3 months"

tradeoffs: "Simplicity > Scalability (Modular Monolith over Microservices)"

# Section 2: Architectural Pattern
architectural_pattern: "Modular Monolith"
pattern_rationale: "Fast development, easy deployment, sufficient for SMB scale"
component_communication: "Internal function calls within monolith, REST API for external"
deployment_strategy: "Single Docker container, horizontal scaling via k8s if needed"

# Section 3: Frontend Architecture (FSD)
fsd_layers: "app, pages, widgets, features, entities, shared"
fsd_key_features:
  - "features/chat: Chat widget with message history"
  - "features/faq-editor: CRUD for FAQ articles"
  - "features/escalation: Human agent handoff"
fsd_state_management: "Zustand for global state, TanStack Query for server state"
fsd_routing: "React Router v6 with lazy loading"
fsd_styling: "Tailwind CSS with design tokens"

# Section 4: Backend Architecture (VSA)
vsa_structure: "features/{domain}/{slice}/ with controller/service/repository"
vsa_key_slices:
  - "features/auth/login/, features/auth/register/"
  - "features/chat/sendMessage/, features/chat/getHistory/"
  - "features/faq/createArticle/, features/faq/searchArticles/"
vsa_shared_modules: "shared/middleware/auth.ts, shared/utils/logger.ts"
vsa_database_access: "Prisma ORM with PostgreSQL"

# Section 5: API Contract (OpenAPI)
api_architecture: "REST API with JWT authentication"
api_versioning: "/api/v1/ for all endpoints, v2 for breaking changes"
api_authentication: "JWT tokens (access: 15min, refresh: 7 days)"

api_endpoints: |
  POST /api/v1/auth/register - User registration
  POST /api/v1/auth/login - User login (returns JWT)
  GET /api/v1/faq/articles - List FAQ articles (paginated)
  POST /api/v1/faq/articles - Create FAQ article
  POST /api/v1/chat/query - Submit customer query to chatbot
  GET /api/v1/chat/history - Get chat history for user
  POST /api/v1/escalation/create - Escalate to human agent

# Section 6: Data Model (Prisma)
data_model: |
  User (id, email, name, role, createdAt)
    - Has many: ChatHistory
  FaqArticle (id, title, content, category, createdAt)
    - Searchable via full-text
  ChatHistory (id, userId, query, response, escalated, createdAt)
    - Belongs to: User
  Escalation (id, chatHistoryId, assignedTo, status, createdAt)
    - Belongs to: ChatHistory

database_design: "PostgreSQL with Prisma schema, indexes on userId, category, status"

# Section 7: NFR Mapping
nfr_performance_solution: "Redis caching for FAQ search, CDN for static assets, DB indexing"
nfr_security_solution: "bcrypt password hashing, JWT with refresh tokens, HTTPS only, input validation with Zod"
nfr_scalability_solution: "Stateless API design, horizontal pod scaling in k8s, read replicas for DB"
nfr_availability_solution: "Health checks, auto-restart on failure, database backups every 6h"
nfr_usability_solution: "Responsive design, <3s page load, inline help tooltips"

# Section 8: Technology Stack
frontend_stack: "React 18, TypeScript strict, TanStack Query, Zustand, Tailwind CSS"
frontend_rationale: "Modern React with strict typing, excellent DX, proven scalability"

backend_stack: "Node.js 20, Express, Prisma, PostgreSQL 16, Zod validation"
backend_rationale: "JavaScript throughout, fast development, mature ecosystem"

database_stack: "PostgreSQL 16 with pg_trgm extension for full-text search"
database_rationale: "Reliable, ACID compliant, excellent full-text search"

infrastructure_stack: "Docker, Kubernetes (GKE), Redis for caching, Cloudflare CDN"
infrastructure_rationale: "Standard container orchestration, managed services reduce ops burden"

third_party_services: "Auth0 for social login (optional), SendGrid for email notifications"

# Section 9: Deployment Architecture
deployment_environment: "GKE (Google Kubernetes Engine)"
deployment_pipeline: "GitHub Actions: Build → Test → Docker → Deploy to staging → Manual prod deploy"
monitoring_stack: "Datadog for metrics/APM, Sentry for error tracking, CloudWatch logs"
```

**Variable Count:** 37 variables

---

## Schema: step5-answers.yaml (Sprint Planning)

**Used by:** `step5-sprint` → `sprint-planning`
**Variables:** Minimal (most data extracted from PRD/Architecture)

```yaml
# Metadata
collected_at: "2026-01-19T07:00:00Z"
collected_by: "step5-sprint"

# Sprint planning mostly reads from PRD and Architecture
# Only a few clarifying questions:

team_velocity: "15 story points per 2-week sprint"
sprint_duration: "2 weeks"
sprint_goal: "MVP with core chatbot functionality and FAQ management"

priority_adjustments: "Move EPIC-003 (Advanced Analytics) to Sprint 2"

dependencies_external: "Zendesk API sandbox access (needed by Week 2)"

sprint_start_date: "2026-01-27"
```

**Variable Count:** 6 variables

---

## Variable Naming Conventions

### YAML Format (in answers file)
- Use `snake_case` for keys
- Example: `executive_summary`, `problem_statement`, `primary_users`

### Template Format (in templates)
- Use `{{snake_case}}` placeholders
- Example: `{{executive_summary}}`, `{{problem_statement}}`

### Environment Variable Format (exported by variable-bridge)
- Use `BMAD_UPPER_SNAKE_CASE`
- Example: `BMAD_EXECUTIVE_SUMMARY`, `BMAD_PROBLEM_STATEMENT`

## Validation Rules

### Required Fields
- `collected_at` - ISO 8601 timestamp
- `collected_by` - Skill name (step2-brief, step3-prd, step4-arch, step5-sprint)

### Optional Fields
- All answer variables are technically optional, but commands should validate required ones

### Data Types
- **String**: Most variables (single-line or multi-line)
- **List**: Use YAML list syntax for multi-value answers
  ```yaml
  business_goals:
    - "Goal 1"
    - "Goal 2"
  ```
- **Multi-line String**: Use `|` for long text blocks
  ```yaml
  functional_requirements: |
    FR-001: First requirement
    FR-002: Second requirement
  ```

## File Locations

### Temporary Files (during execution)
```
/tmp/step2-answers.yaml   # Product Brief answers
/tmp/step3-answers.yaml   # PRD answers
/tmp/step4-answers.yaml   # Architecture answers
/tmp/step5-answers.yaml   # Sprint Planning answers
```

These files are **temporary** and should be cleaned up after BMAD command completes.

### Permanent Storage (optional)
For debugging or reuse, answers can be saved to:
```
{project-root}/.bmad/answers/
├── product-brief-2026-01-19.yaml
├── prd-2026-01-19.yaml
├── architecture-2026-01-19.yaml
└── sprint-planning-2026-01-19.yaml
```

## Usage Example

### In step-* skill:
```bash
# Collect 29 answers through interactive interview
# Then create YAML file:

cat > /tmp/step2-answers.yaml <<EOF
collected_at: "$(date -Iseconds)"
collected_by: "step2-brief"
executive_summary: "$ANSWER_1"
vision: "$ANSWER_2"
problem_statement: "$ANSWER_3"
[... all 29 answers ...]
EOF

# Call variable-bridge.sh
bash ~/.claude/skills/bmad/bmad-v6/utils/variable-bridge.sh \
  product-brief \
  /tmp/step2-answers.yaml
```

### In BMAD command:
```markdown
## Pre-Flight

4. **Check for answers file:**
   ```bash
   if [ "$BMAD_BATCH_MODE" == "true" ]; then
     # Batch mode: load from environment variables
     EXEC_SUMMARY="$BMAD_EXECUTIVE_SUMMARY"
     VISION="$BMAD_VISION"
     PROBLEM="$BMAD_PROBLEM_STATEMENT"
     SKIP_INTERVIEW=true
   else
     # Interactive mode: ask user
     SKIP_INTERVIEW=false
   fi
   ```
```

---

## Troubleshooting

### Error: "Answers file not found"
- Check that skill created `/tmp/stepN-answers.yaml`
- Verify file permissions (readable by current user)

### Error: "Variable not found in template"
- Check YAML key matches template placeholder exactly
- Example: YAML `executive_summary` → Template `{{executive_summary}}`

### Error: "BMAD_* env var empty"
- Verify variable-bridge.sh exported correctly
- Check for syntax errors in YAML file (invalid YAML syntax)

### Multi-line Values Not Working
- Use YAML `|` or `|-` for multi-line strings:
  ```yaml
  long_text: |
    Line 1
    Line 2
    Line 3
  ```

---

## Version History

- **v1.0.0** (2026-01-19): Initial schemas for unified BMAD system
