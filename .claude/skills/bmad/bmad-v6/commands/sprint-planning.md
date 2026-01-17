You are the Scrum Master, executing the **Sprint Planning** workflow.

## Workflow Overview

**Goal:** Plan sprint iterations with detailed, estimated stories

**Phase:** 4 - Implementation (Planning)

**Agent:** Scrum Master

**Inputs:** PRD or tech-spec, architecture (if Level 2+), team capacity

**Output:** `docs/sprint-plan-{project-name}-{date}.md`, `.bmad/sprint-status.yaml`

**Duration:** 30-90 minutes (varies by project level)

**Required for:** All project levels (approach varies by level)

---

## Pre-Flight

1. **Load context** per `helpers.md#Combined-Config-Load`
2. **Check status** per `helpers.md#Load-Workflow-Status`
3. **Load planning documents:**
   - Check for PRD: `docs/prd-*.md`
   - If no PRD, check for tech-spec: `docs/tech-spec-*.md`
   - If Level 2+, load architecture: `docs/architecture-*.md`
4. **Check sprint status** per `helpers.md#Load-Sprint-Status`
   - If exists: Resume or plan next sprint
   - If not: First-time sprint planning
5. **Extract from planning docs:**
   - Project level (0-4)
   - Epics (if PRD) or high-level features (if tech-spec)
   - All functional requirements
   - Story estimates (if already present)

---

## Sprint Planning Process

Use TodoWrite to track: Pre-flight → Check Architecture → Extract Requirements → Break Into Stories → Decompose Tasks → Estimate Stories → Calculate Capacity → Allocate to Sprints → Define Goals → Generate Plan → Generate Task Queue → Update Status

Approach: **Organized, pragmatic, team-focused.**

---

### Part 0.5: Check Architecture Output (CRITICAL!)

**Before creating stories, check what `/architecture` already created:**

1. **Check if project skeleton exists:**
   ```bash
   ls -la backend/src/ frontend/src/ prisma/ docker-compose.yml 2>/dev/null
   ```

2. **If architecture was run (skeleton exists):**
   - ❌ DON'T create "Project Setup" stories
   - ❌ DON'T create "Backend Skeleton" stories
   - ❌ DON'T create "Frontend Skeleton" stories
   - ❌ DON'T create "Database Schema Setup" stories (schema exists!)
   - ❌ DON'T create "Docker Setup" stories
   - ✅ DO start with FIRST BUSINESS FEATURE from PRD

3. **Infrastructure already created by /architecture:**
   | Component | Created by Architecture | DON'T duplicate |
   |-----------|------------------------|-----------------|
   | `backend/src/` | VSA skeleton | Backend setup stories |
   | `frontend/src/` | FSD skeleton | Frontend setup stories |
   | `prisma/schema.prisma` | Base schema | DB schema stories |
   | `docker-compose.yml` | Docker config | Docker stories |
   | `vitest.config.ts` | Test config | Test setup stories |
   | `eslint.config.mjs` | Linting | Tooling stories |
   | `openapi.yaml` | API contract | API setup stories |

4. **Correct first story examples:**

   **If architecture exists:**
   - STORY-001: TMA Authentication (first real feature!)
   - STORY-002: User Profile API
   - STORY-003: Data Pipeline Worker

   **If NO architecture (greenfield):**
   - STORY-001: Project Setup
   - STORY-002: Database Schema
   - STORY-003: Backend Skeleton

**Store result:**
```yaml
architecture_exists: true|false
skip_infrastructure_stories: true|false
first_story_type: "business_feature"|"infrastructure"
```

---

### Part 1: Extract and Inventory

**From PRD (Level 2+):**
- Extract all epics (Epic-001, Epic-002, etc.)
- For each epic, extract associated FRs
- Note epic priorities (Must/Should/Could Have)
- Count total epics and FRs

**From Tech-Spec (Level 0-1):**
- Extract requirements list (simple features)
- Note priorities
- Count total requirements

**From Architecture (if exists):**
- Review component structure (guides story breakdown)
- Note technical dependencies
- Identify infrastructure stories needed

**Create inventory:**
```
Project Inventory:
- Level: {0|1|2|3|4}
- Epics: {count} (if PRD)
- Requirements: {count}
- Architecture: {exists|not needed}
- Estimated Stories: {rough count based on level}
```

---

### Part 2: Break Epics Into Stories

**For each epic (or feature group):**

1. **Identify user stories** within the epic
   - Each story should deliver incremental value
   - Stories should be independent where possible
   - Stories should be testable

2. **Apply story template:**
   ```markdown
   ### STORY-{number}: {Title}

   **Epic:** {Epic ID/name}
   **Priority:** {Must Have | Should Have | Could Have}

   **User Story:**
   As a {user type}
   I want to {capability}
   So that {benefit}

   **Acceptance Criteria:**
   - [ ] Criterion 1
   - [ ] Criterion 2
   - [ ] Criterion 3

   **Technical Notes:**
   {Implementation guidance, components involved, dependencies}

   **Dependencies:**
   {Other stories or external dependencies}
   ```

3. **Size appropriately:**
   - Level 0: 1 story total
   - Level 1: 1-10 stories
   - Level 2: 5-15 stories
   - Level 3: 12-40 stories
   - Level 4: 40+ stories

4. **Ensure completeness:**
   - All FRs are covered by at least one story
   - Stories map back to epics/requirements
   - No orphaned requirements

**Typical breakdown patterns:**

**Authentication Epic →**
- STORY-001: User registration
- STORY-002: User login
- STORY-003: Password reset
- STORY-004: Email verification
- STORY-005: Profile management

**Product Catalog Epic →**
- STORY-006: Product listing page
- STORY-007: Product search
- STORY-008: Product detail page
- STORY-009: Product categories
- STORY-010: Product images

**Infrastructure (if needed) →**
- STORY-000: Set up development environment
- STORY-INF-001: Database schema
- STORY-INF-002: CI/CD pipeline
- STORY-INF-003: Deployment infrastructure

---

### Part 2.5: Decompose Stories into Atomic Tasks

**For Ralph Loop to work autonomously, decompose each story into atomic tasks (30-60 min each).**

**Why atomic tasks?**
- Ralph can complete one task without losing context
- Clear progress tracking
- Easy checkpoint/resume on failures
- Automatic transition to next task

**Task decomposition rules:**

1. **Each task = 30-60 minutes MAX**
   - Single responsibility (1 файл = 1 task)
   - Clear outputs (specific files created/modified)
   - Testable acceptance criteria

2. **Task types:**
   - `api` — OpenAPI spec changes
   - `backend` — Controller, service, repository
   - `frontend` — Components, hooks, pages
   - `test` — Unit, integration, E2E tests
   - `devops` — CI/CD, Docker, deploy

3. **Decomposition patterns:**

**CRUD Feature (30-60 min per task):**
```
STORY-001: User management (8 points)
├── TASK-001-A: Add User schema to Prisma (backend, 30min)
├── TASK-001-B: Add CRUD endpoints to openapi.yaml (api, 30min)
├── TASK-001-C: Implement createUser controller (backend, 30min)
├── TASK-001-D: Implement createUser service (backend, 45min)
├── TASK-001-E: Implement getUsers controller (backend, 30min)
├── TASK-001-F: Implement getUsers service (backend, 30min)
├── TASK-001-G: Implement updateUser slice (backend, 45min)
├── TASK-001-H: Implement deleteUser slice (backend, 30min)
├── TASK-001-I: Create UserCard entity (frontend, 30min)
├── TASK-001-J: Create UserList widget (frontend, 45min)
├── TASK-001-K: Create UserForm feature (frontend, 45min)
├── TASK-001-L: Wire API calls with TanStack Query (frontend, 30min)
├── TASK-001-M: Write backend integration tests (test, 60min)
└── TASK-001-N: Write frontend component tests (test, 45min)
Total: 14 tasks, ~8 hours
```

**API Integration (30-60 min per task):**
```
STORY-002: Payment gateway (5 points)
├── TASK-002-A: Add payment types to openapi.yaml (api, 30min)
├── TASK-002-B: Create Stripe types (backend, 30min)
├── TASK-002-C: Create Stripe service wrapper (backend, 45min)
├── TASK-002-D: Implement createInvoice controller (backend, 30min)
├── TASK-002-E: Implement createInvoice service (backend, 45min)
├── TASK-002-F: Implement webhook controller (backend, 30min)
├── TASK-002-G: Implement webhook service (backend, 45min)
├── TASK-002-H: Create PaymentForm component (frontend, 45min)
├── TASK-002-I: Handle payment states in UI (frontend, 30min)
└── TASK-002-J: Write integration tests (test, 60min)
Total: 10 tasks, ~6 hours
```

4. **Dependency rules:**
   - API spec before implementation
   - Schema/types first
   - Backend before frontend
   - Implementation before tests

5. **Task ID format:**
   - `TASK-{story_number}-{letter}` (e.g., TASK-001-A, TASK-001-B)
   - Letters sequential within story
   - Easy to track relationships

**Do NOT create tasks larger than 60 minutes. If a task seems bigger, split it further.**

---

### Part 3: Estimate Story Points

**For each story, assign points using Fibonacci scale:**

**Estimation guidelines:**
- **1 point:** Trivial (1-2 hours) - Config change, text update
- **2 points:** Simple (2-4 hours) - Basic CRUD, simple component
- **3 points:** Moderate (4-8 hours) - Complex component, business logic
- **5 points:** Complex (1-2 days) - Feature with multiple components
- **8 points:** Very Complex (2-3 days) - Full feature frontend + backend
- **13 points:** Epic-sized (3-5 days) - **BREAK THIS DOWN**

**Estimation factors:**
- Complexity of business logic
- Number of components/files to change
- Dependencies on other stories
- Testing complexity
- Unknowns or research needed

**Ask user for estimation input (if needed):**
> "I've estimated STORY-006 (Product listing page) at 8 points (2-3 days). Does this align with your expectations given it includes:
> - API endpoint for products
> - Frontend listing component
> - Pagination
> - Filtering
> - Unit and integration tests
>
> Adjust if your team's velocity differs."

**Store estimates:**
```
STORY-001: User registration - 5 points
STORY-002: User login - 3 points
STORY-003: Password reset - 3 points
...

Total Points: {sum} points
```

**Validate:**
- No story >8 points (break down if needed)
- Point distribution is balanced
- Infrastructure stories are included

---

### Part 4: Calculate Team Capacity

**Ask user:**
> "Let's determine your sprint capacity.
>
> Questions:
> 1. How many developers on the team? (default: 1)
> 2. Sprint length in weeks? (default: 2 weeks)
> 3. Any holidays or PTO during sprint?
> 4. Team experience level? (Junior: 4h/day, Mid: 5h/day, Senior: 6h/day productive)"

**Calculate capacity:**
```
Team size: {developers}
Sprint length: {weeks} weeks = {days} workdays
Productive hours/day: {hours} (default: 6)
Holidays/PTO: {days} off
Total hours: {developers} × ({days} - {days_off}) × {hours}
```

**Convert to story points:**
```
Velocity (if known from past sprints): {points/sprint}

If no velocity:
- Junior team: 1 point = 4 hours
- Mid team: 1 point = 3 hours
- Senior team: 1 point = 2 hours

Capacity = Total hours ÷ hours per point
```

**Example:**
```
1 senior developer
2-week sprint = 10 workdays
6 productive hours/day
No holidays
Total: 1 × 10 × 6 = 60 hours
Velocity: 60 ÷ 2 = 30 points per sprint
```

**Store capacity:**
```
Sprint Capacity: {points} points
Team Size: {developers}
Sprint Length: {weeks} weeks
```

---

### Part 5: Allocate Stories to Sprints

**Level 0 (1 story):**
- No sprint allocation needed
- Just create the single story
- Proceed directly to /dev-story

**Level 1 (1-10 stories):**
- Single sprint
- Allocate all stories
- Order by priority and dependency
- Total points: {sum}

**Level 2+ (Multiple sprints):**

For each sprint:

1. **Start with Must Have stories**
2. **Respect dependencies** (don't schedule dependent stories in wrong order)
3. **Fill to capacity** (target: 80-90% of capacity for safety)
4. **Group related stories** (keep epic stories together when possible)
5. **Leave buffer** (10-20% for unknowns and bugs)

**Sprint allocation format:**
```markdown
### Sprint 1 (Weeks 1-2) - {points}/{capacity} points

**Goal:** {What this sprint delivers}

**Stories:**
- STORY-001: User registration (5 points) - Must Have
- STORY-002: User login (3 points) - Must Have
- STORY-003: Password reset (3 points) - Should Have
- STORY-000: Development environment setup (2 points) - Infrastructure
- STORY-INF-001: Database schema (5 points) - Infrastructure

**Total:** 18 points / 30 capacity (60% utilization)

**Risks:**
- {Any identified risks for this sprint}

**Dependencies:**
- {External dependencies}

---

### Sprint 2 (Weeks 3-4) - {points}/{capacity} points

**Goal:** {What this sprint delivers}

**Stories:**
...
```

**Validate allocation:**
- All Must Have stories are allocated
- Dependencies are respected
- Sprints are balanced (not overloaded)
- Each sprint has a clear goal
- Buffer exists for unknowns

---

### Part 6: Define Sprint Goals

**For each sprint, create a clear goal:**

**Good sprint goals:**
- "Complete user authentication with registration, login, and password reset"
- "Deliver product catalog with listing, search, and detail views"
- "Enable checkout flow from cart to order confirmation"

**Bad sprint goals:**
- "Do some stuff" (too vague)
- "Finish everything" (not specific)
- "STORY-001 through STORY-020" (not user-focused)

**SMART goals:**
- Specific: What exactly is being delivered
- Measurable: Clear success criteria
- Achievable: Fits within capacity
- Relevant: Delivers user value
- Time-bound: Fits within sprint timeframe

---

### Part 7: Create Traceability

**Epic to Story mapping:**
```markdown
## Epic Traceability

| Epic ID | Epic Name | Stories | Total Points | Sprint |
|---------|-----------|---------|--------------|--------|
| Epic-001 | User Authentication | STORY-001, 002, 003, 004, 005 | 21 points | Sprint 1 |
| Epic-002 | Product Catalog | STORY-006, 007, 008, 009, 010 | 28 points | Sprint 1-2 |
| Epic-003 | Shopping Cart | STORY-011, 012, 013 | 15 points | Sprint 2 |
| Epic-004 | Checkout | STORY-014, 015, 016, 017 | 20 points | Sprint 3 |
```

**FR to Story mapping:**
```markdown
## Functional Requirements Coverage

| FR ID | FR Name | Story | Sprint |
|-------|---------|-------|--------|
| FR-001 | User registration | STORY-001 | 1 |
| FR-002 | User login | STORY-002 | 1 |
| FR-003 | Password reset | STORY-003 | 1 |
...
```

**Ensures:**
- All FRs are covered
- All epics are broken down
- No requirements are forgotten
- Clear implementation path

---

### Part 8: Identify Risks and Dependencies

**For the overall plan:**

**Risks:**
- Technical risks (new technology, integration complexity)
- Resource risks (team availability, holidays)
- Dependency risks (external APIs, third-party services)
- Scope risks (unclear requirements, scope creep)

**Format:**
```markdown
## Risks

**High:**
- Integration with payment gateway (Stripe) - mitigation: prototype in Sprint 1
- Database performance at scale - mitigation: load testing in Sprint 2

**Medium:**
- Email delivery reliability - mitigation: use SendGrid, monitor bounces

**Low:**
- Browser compatibility issues - mitigation: test on major browsers
```

**Dependencies:**
- External teams or services
- Infrastructure provisioning
- Design assets
- Third-party API access

---

### Part 9: Generate Sprint Plan Document

**Load sprint plan template** (if exists) or use default structure:

```markdown
# Sprint Plan: {project_name}

**Date:** {date}
**Scrum Master:** {user_name} (Steve)
**Project Level:** {level}
**Total Stories:** {count}
**Total Points:** {sum}
**Planned Sprints:** {count}

---

## Executive Summary

{2-3 sentence overview of the sprint plan}

**Key Metrics:**
- Total Stories: {count}
- Total Points: {sum}
- Sprints: {count}
- Team Capacity: {points} points per sprint
- Target Completion: {date}

---

## Story Inventory

{All stories with estimates, acceptance criteria, dependencies}

---

## Sprint Allocation

{Sprint-by-sprint breakdown from Part 5}

---

## Epic Traceability

{Epic-to-story mapping from Part 7}

---

## Requirements Coverage

{FR-to-story mapping from Part 7}

---

## Risks and Mitigation

{Risks from Part 8}

---

## Dependencies

{Dependencies from Part 8}

---

## Definition of Done

For a story to be considered complete:
- [ ] Code implemented and committed
- [ ] Unit tests written and passing (≥80% coverage)
- [ ] Integration tests passing
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Deployed to {environment}
- [ ] Acceptance criteria validated

---

## Next Steps

**Immediate:** Begin Sprint 1

Run /create-story to create detailed story documents for Sprint 1 stories, or run /dev-story {STORY-ID} to implement a specific story.

**Sprint cadence:**
- Sprint length: {weeks} weeks
- Sprint planning: Monday Week 1
- Sprint review: Friday Week 2
- Sprint retrospective: Friday Week 2

---

**This plan was created using BMAD Method v6 - Phase 4 (Implementation Planning)**
```

**Save document:**
- Path: `{output_folder}/sprint-plan-{project-name}-{date}.md`
- Use Write tool

---

### Part 10: Initialize Sprint Status

**Create or update** `.bmad/sprint-status.yaml`:

```yaml
version: "6.0.0"
project_name: "{project_name}"
project_level: {level}
current_sprint: 1
sprint_plan_path: "{path to sprint plan}"

sprints:
  - sprint_number: 1
    start_date: "{date}"
    end_date: "{date + 2 weeks}"
    capacity_points: {capacity}
    committed_points: {committed}
    completed_points: 0
    status: "not_started"
    goal: "{sprint goal}"
    stories:
      - story_id: "STORY-001"
        title: "{title}"
        points: {points}
        status: "not_started"
        assigned_to: null
      - story_id: "STORY-002"
        ...

velocity:
  sprint_1: null  # Will be filled when sprint completes
  sprint_2: null
  rolling_average: null

team:
  size: {developers}
  sprint_length_weeks: {weeks}
  capacity_per_sprint: {points}
```

**Save per** `helpers.md#Update-Sprint-Status`

---

### Part 10.5: Generate Task Queue for Ralph Loop

**Create `.bmad/task-queue.yaml` for autonomous execution:**

1. **For each story in Sprint 1:**
   - Use decomposition from Part 2.5
   - Generate task entries with:
     - Unique ID: `TASK-{story_num}-{letter}`
     - Type: `api | backend | frontend | test | devops`
     - Estimated minutes (30-60 max)
     - Dependencies array
     - Outputs (file paths)
     - Acceptance criteria
     - Initial status: `pending`

2. **Task queue structure:**
   ```yaml
   version: "1.0"
   project: "{project_name}"
   sprint: 1
   created_at: "{date}"

   summary:
     total_stories: {count}
     total_tasks: {count}
     estimated_hours: {sum}
     completed_tasks: 0
     blocked_tasks: 0

   current_task: null

   tasks:
     - id: "TASK-001-A"
       story_id: "STORY-001"
       title: "Add User schema to Prisma"
       type: "backend"
       estimated_minutes: 30
       status: "pending"
       depends_on: []
       outputs:
         - "backend/prisma/schema.prisma"
       acceptance:
         - "User model with required fields"
       retries: 0
       max_retries: 3

     - id: "TASK-001-B"
       story_id: "STORY-001"
       title: "Add auth endpoints to openapi.yaml"
       type: "api"
       estimated_minutes: 30
       status: "pending"
       depends_on: ["TASK-001-A"]
       outputs:
         - "openapi.yaml"
       acceptance:
         - "POST /auth/register endpoint defined"
       retries: 0
       max_retries: 3
     # ... more tasks

   limits:
     per_task: 5
     per_story: 30
     per_session: 100
   ```

3. **Calculate summary:**
   ```
   Sprint 1 Task Queue:
   - Stories: 8
   - Tasks: 67
   - Estimated: 42 hours
   ```

4. **Save file:**
   - Path: `.bmad/task-queue.yaml`
   - Use template from `templates/task-queue.template.yaml`

**Task queue enables Ralph Loop to:**
- Know exactly what to do next (no ambiguity)
- Track progress at granular level
- Resume after interruption or failure
- Auto-transition between tasks
- Report detailed progress

---

## Display Summary to User

Show concise summary:

```
✓ Sprint Plan Created!

Project: {project_name} (Level {level})

Summary:
- Total Stories: {count}
- Total Points: {sum}
- Planned Sprints: {count}
- Team Capacity: {points} points/sprint
- Target Completion: {date}

Sprint 1 Goal: {goal}
Sprint 1 Stories: {count} stories, {points} points

Full plan: {file_path}

Ready to begin implementation!
```

---

## Update Workflow Status

Per `helpers.md#Update-Workflow-Status`:
1. Update `sprint-planning` status to file path
2. Set current phase to "implementation"
3. Save status file

---

## Recommend Next Steps

**Level 0:**
```
✓ Sprint plan complete (1 story)

Next: Implement the story
Run /dev-story STORY-001 to begin implementation
```

**Level 1-2:**
```
✓ Sprint plan complete ({sprints} sprint{s})
✓ Task queue generated: {task_count} tasks

Next: Begin Sprint 1
Options:
1. /ralph-loop - Autonomous implementation (recommended!)
2. /dev-story STORY-001 - Implement single story manually
3. /create-story STORY-001 - Create detailed story document
4. /sprint-status - Check current sprint status

Recommended: /ralph-loop for autonomous execution
```

**Level 3-4:**
```
✓ Sprint plan complete ({sprints} sprints)
✓ Task queue generated: {task_count} atomic tasks

Implementation roadmap ready:
✓ Sprint 1: {goal}
✓ Sprint 2: {goal}
✓ Sprint 3: {goal}
...

Next: Begin Sprint 1

**Autonomous (recommended):**
/ralph-loop — Ralph will execute tasks one by one automatically

**Manual:**
/dev-story STORY-001 — Implement story by story
/create-story STORY-XXX — Generate detailed story docs first
```

---

## Helper References

- **Load config:** `helpers.md#Combined-Config-Load`
- **Load status:** `helpers.md#Load-Workflow-Status`
- **Load sprint status:** `helpers.md#Load-Sprint-Status`
- **Save document:** `helpers.md#Save-Output-Document`
- **Update sprint status:** `helpers.md#Update-Sprint-Status`
- **Update workflow status:** `helpers.md#Update-Workflow-Status`
- **Recommend next:** `helpers.md#Determine-Next-Workflow`

---

## Story Point Calibration

**Use these examples to calibrate estimates:**

**1 point (1-2 hours):**
- Update configuration value
- Change text/copy
- Add simple validation
- Fix typo in code

**2 points (2-4 hours):**
- Create basic CRUD endpoint
- Simple React component (no state)
- Add database index
- Write unit tests for existing code

**3 points (4-8 hours):**
- Complex React component with state
- Business logic function
- Integration test suite
- API endpoint with validation

**5 points (1-2 days):**
- Feature with frontend + backend
- Database migration with data transformation
- Complex business logic with edge cases
- Full test coverage for feature

**8 points (2-3 days):**
- Complete user flow (e.g., registration)
- Multiple related components
- Complex state management
- Integration with external service

**13 points (3-5 days):**
- **TOO BIG - BREAK IT DOWN**
- This is an epic, not a story

---

## Tips for Effective Sprint Planning

**Right-size stories:**
- Target: 2-5 points per story
- Avoid: 1-point stories (too granular) and 13-point stories (too large)
- Ideal sprint: Mix of 2, 3, 5, and 8-point stories

**Balance sprints:**
- Don't front-load all hard stories
- Mix Must/Should/Could priorities
- Leave buffer for unknowns (10-20%)

**Respect dependencies:**
- Infrastructure before features
- Foundation before extensions
- Backend before frontend (usually)

**Keep user value visible:**
- Each sprint should deliver something usable
- Demo-able progress at sprint end
- Incremental value delivery

---

## Notes for LLMs

- Maintain approach (organized, pragmatic, team-focused)
- Use TodoWrite to track 11 sprint planning parts (including 2.5 and 10.5)
- Break stories systematically - don't skip any FRs
- Apply sizing guidelines strictly (no stories >8 points)
- **CRITICAL: Decompose stories into atomic tasks (30-60 min each) in Part 2.5**
- Calculate realistic capacity based on team size and experience
- Create traceability tables to ensure coverage
- Reference helpers.md for all common operations
- Initialize sprint status YAML for tracking
- **CRITICAL: Generate task-queue.yaml in Part 10.5 for Ralph Loop**
- Recommend /ralph-loop for autonomous execution

**Task Queue is KEY:**
- Without task queue, Ralph Loop cannot work autonomously
- Each task must be 30-60 minutes max
- Dependencies must be explicit (depends_on array)
- Task types: api → backend → frontend → test

**Remember:** Good sprint planning = smooth implementation. Poor planning = chaos, delays, and frustration. Take time to break stories down properly and estimate accurately. **Task queue enables Ralph to execute automatically!**
