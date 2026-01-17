# Workflow Guide

Complete guide to the BMAD workflow and Ralph Loop autonomous implementation.

---

## Overview

The Claude Starter Kit provides a structured workflow for product development:

```
Product Brief --> PRD --> Architecture --> Stories --> Implementation
                                                            |
                                                      Ralph Loop
                                                            |
                                    API --> Backend --> Frontend --> Tests --> Deploy --> Validate
```

---

## BMAD Phases

BMAD (Business, Marketing, Architecture, Development) provides a structured approach to product development.

### Phase 1: Product Brief

```bash
/product-brief
```

Creates a high-level product vision document:

- **Problem Statement** - What problem are we solving?
- **Target Audience** - Who are we building for?
- **Value Proposition** - Why will users choose this?
- **Success Metrics** - How do we measure success?
- **Constraints** - Budget, timeline, technology

**Output:** `docs/product-brief.md`

### Phase 2: PRD (Product Requirements)

```bash
/prd
```

Transforms product brief into detailed requirements:

- **User Personas** - Detailed user profiles
- **User Stories** - "As a... I want... So that..."
- **Acceptance Criteria** - Definition of done
- **Wireframes** - UI sketches (optional)
- **Priority Matrix** - MoSCoW prioritization

**Output:** `docs/prd.md`

### Phase 3: Architecture

```bash
/architecture
```

Technical design based on PRD:

- **System Overview** - High-level architecture diagram
- **Technology Stack** - Chosen technologies with rationale
- **Database Schema** - Entity relationships
- **API Design** - Endpoint structure
- **Security** - Authentication, authorization
- **Scalability** - Performance considerations

**Output:** `docs/architecture.md`, `openapi.yaml`

### Phase 4: Stories

```bash
/create-epics-and-stories
```

Breaks down requirements into implementable units:

- **Epics** - Large features (e.g., "User Authentication")
- **Stories** - Implementable units (e.g., "User Login")
- **Tasks** - Technical subtasks
- **Dependencies** - Story relationships

**Output:** `docs/epics/`, `docs/stories/`

### Phase 5: Implementation

```bash
/ralph-loop
```

Autonomous implementation of stories through the subagent pipeline.

---

## Ralph Loop

### What is Ralph Loop?

**RALPH** = **R**elentless **A**utonomous **L**oop for **P**roduct **H**acking

Ralph Loop is an autonomous implementation orchestrator that:

1. Takes a user story as input
2. Processes it through 6 specialized subagents
3. Produces working, tested code
4. Continues until completion or blocker

### Loop Flow

```
+----------------------------------------------------------+
|                      RALPH LOOP                           |
+----------------------------------------------------------+
|                                                           |
|  [Story] --> [API Agent] --> [Backend Agent]              |
|                   |                |                      |
|              openapi.yaml      VSA slice                  |
|                   |                |                      |
|              [Frontend Agent] <----+                      |
|                   |                                       |
|               FSD feature                                 |
|                   |                                       |
|              [Test Agent] --> [DevOps Agent]              |
|                   |                |                      |
|                tests           env/deploy                 |
|                   |                |                      |
|              [Validation Agent] <--+                      |
|                   |                                       |
|              arch checks                                  |
|                   |                                       |
|              COMPLETE or BLOCKED                          |
|                                                           |
+----------------------------------------------------------+
```

### Agent Pipeline

| Step | Agent | Input | Output |
|------|-------|-------|--------|
| 1 | API Agent | Story, existing openapi.yaml | Updated openapi.yaml |
| 2 | Backend Agent | openapi.yaml endpoints | VSA slice files |
| 3 | Frontend Agent | API types, UI requirements | FSD feature files |
| 4 | Test Agent | Implemented code | Unit, integration, E2E tests |
| 5 | DevOps Agent | Complete feature | Environment, CI/CD |
| 6 | Validation Agent | All changes | Validation report |

### Retry Logic

Each agent has retry capability:

```
MAX_RETRIES_PER_AGENT = 3

for agent in pipeline:
    retries = 0
    while retries < MAX_RETRIES:
        result = agent.execute()
        if result.success:
            break
        retries++
        if retries == MAX_RETRIES:
            return BLOCKED(agent, result.error)
```

If an agent fails 3 times, Ralph Loop reports a blocker requiring human decision.

### Output Format

**Success:**

```xml
<promise>COMPLETE</promise>
<summary>
  - Created: 5 files
  - Modified: 3 files
  - Tests: 24 passed
  - Coverage: 87%
</summary>
```

**Blocked:**

```xml
<promise>BLOCKED</promise>
<blocker>
  Agent: Backend
  Error: Prisma migration conflict
  Requires: Human decision on schema change
</blocker>
```

---

## Using Ralph Loop

### Single Story

```bash
/ralph-loop

Story: Implement user authentication
- Login with email/password
- JWT token generation
- Protected route middleware
```

### Batch Stories

Process multiple stories sequentially:

```bash
/ralph-loop --batch

Stories:
1. User registration
2. Email verification
3. Password reset
4. Profile management
```

### Resume After Block

If Ralph Loop encounters a blocker:

```bash
# Human resolves the blocker
# Then resume:

/ralph-loop --resume

Continuing from: Backend Agent (retry 2/3)
Last error: Database connection timeout
```

---

## Ledger Integration

Ralph Loop maintains state in a continuity ledger:

```
thoughts/ledgers/CONTINUITY_CLAUDE-ralph.md
```

### Ledger Structure

```markdown
## Goal
Complete authentication feature with all stories.

## State
- Done:
  - [x] Story 1: User registration
  - [x] Story 2: Email verification
- Now: [->] Story 3: Password reset (Backend Agent)
- Next: Story 4: Profile management

## Working Set
- Branch: feature/auth
- Files: src/features/auth/
- Tests: pnpm test src/features/auth/
```

### State Tracking

- `[x]` - Completed
- `[->]` - In progress (current)
- `[ ]` - Pending

### After Context Clear

If you need to clear context:

1. Ralph saves state to ledger
2. After `/clear`, ledger loads automatically
3. Find `[->]` to see current progress
4. Continue from where you left off

---

## Monitoring Progress

### Check Loop Status

```bash
cat thoughts/ledgers/CONTINUITY_CLAUDE-ralph.md
```

### View Agent Logs

```bash
tail -f .claude/cache/ralph-loop.log
```

### Check Test Coverage

```bash
pnpm test -- --coverage
```

---

## Best Practices

### Story Size

- Keep stories small (implementable in 1-2 hours)
- One story = one feature slice
- Clear acceptance criteria

### API-First

- Always update `openapi.yaml` first
- Generate types before coding
- Validate implementation against spec

### Incremental Commits

Ralph Loop commits after each successful agent:

```
feat(api): add user endpoints to openapi.yaml
feat(backend): implement user VSA slice
feat(frontend): add user FSD feature
test: add user feature tests
```

### Handling Blockers

When blocked:

1. Read the blocker message
2. Resolve the underlying issue
3. Run `/ralph-loop --resume`

Common blockers:
- Database migration conflicts
- Missing environment variables
- External API unavailable
- Architecture violations

---

## Example Workflow

### Complete Example

```bash
# 1. Create project
mkdir my-saas && cd my-saas
/init-project

# 2. Define product
/product-brief
# Fill in: SaaS dashboard for analytics

# 3. Generate requirements
/prd
# Generates user stories, personas, priorities

# 4. Design architecture
/architecture
# Creates system design, database schema, API spec

# 5. Create stories
/create-epics-and-stories
# Breaks down into implementable stories

# 6. Start implementation
/ralph-loop
# Story: User dashboard with charts
# -> API Agent creates endpoints
# -> Backend Agent implements data layer
# -> Frontend Agent builds UI
# -> Test Agent writes tests
# -> DevOps Agent sets up env
# -> Validation Agent verifies

# 7. Continue with next story
/ralph-loop
# Story: Report generation
# ...

# 8. Validate everything
/validate-all
```

---

## Related Documentation

- [AGENTS.md](./AGENTS.md) - Detailed agent documentation
- [INSTALLATION.md](./INSTALLATION.md) - Installation guide
- [README.md](../README.md) - Project overview
