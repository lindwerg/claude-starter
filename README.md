# Claude Starter Kit

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)
![Claude Code](https://img.shields.io/badge/Claude%20Code-compatible-purple.svg)

> One command to set up autonomous full-stack development with Claude Code

Transform Claude Code into a fully autonomous development system with specialized subagents, architectural patterns, and production-ready workflows.

---

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/lindwerg/claude-starter/main/install.sh | bash
```

After installation, restart Claude Code and run:

```bash
mkdir my-app && cd my-app
/init-project
```

---

## What You Get

### 6 Specialized Subagents

| Agent | Responsibility |
|-------|----------------|
| **API Agent** | OpenAPI specification, type generation, API contracts |
| **Backend Agent** | VSA slices (Vertical Slice Architecture) |
| **Frontend Agent** | FSD components (Feature-Sliced Design) |
| **Test Agent** | TDD-first testing with Vitest and Playwright |
| **DevOps Agent** | Local environment, Docker, migrations |
| **Validation Agent** | Architecture checks, linting, coverage |

### BMAD v6 Workflow

Complete product development lifecycle:
- Product Brief creation
- PRD (Product Requirements Document)
- Technical Architecture
- Epic and Story breakdown
- Autonomous implementation

### Production-Ready Architecture

- **VSA (Vertical Slice Architecture)** for backend
- **FSD (Feature-Sliced Design)** for frontend
- **OpenAPI 3.1** as the single source of truth
- **TypeScript strict mode** everywhere
- **Zod validation** for all inputs

### Automated Quality

- Pre-commit hooks for formatting and type-checking
- Test coverage thresholds (80% minimum)
- Architecture validation (VSA/FSD rules)
- OpenAPI sync verification

---

## Architecture Overview

### Ralph Loop

The autonomous implementation orchestrator:

```
+----------------------------------------------------------+
|                      RALPH LOOP                           |
+----------------------------------------------------------+
|  Story --> API Agent --> Backend Agent --> Frontend Agent |
|                |              |                |          |
|           openapi.yaml    VSA slice       FSD feature     |
|                |              |                |          |
|         Test Agent --> DevOps Agent --> Validation Agent  |
|                |              |                |          |
|            tests         CI/deploy        arch check      |
|                              |                            |
|                       COMPLETE / BLOCKED                  |
+----------------------------------------------------------+
```

**RALPH** = **R**elentless **A**utonomous **L**oop for **P**roduct **H**acking

The loop continues until completion or an explicit blocker requiring human decision.

### Subagent Pipeline

1. **API Agent** - Defines the contract before implementation
2. **Backend Agent** - Implements VSA vertical slice
3. **Frontend Agent** - Implements FSD feature components
4. **Test Agent** - Writes tests (TDD-first approach)
5. **DevOps Agent** - Sets up environment and deployment
6. **Validation Agent** - Final architecture and quality checks

---

## Directory Structure

After installation, your `~/.claude/` directory will contain:

```
~/.claude/
├── CLAUDE.md              # Global instructions
├── settings.json          # Claude Code settings
├── mcp_config.json        # MCP server configuration
│
├── agents/                # Subagent definitions
│   ├── api-agent.md
│   ├── backend-agent.md
│   ├── frontend-agent.md
│   ├── test-agent.md
│   ├── devops-agent.md
│   └── validation-agent.md
│
├── skills/                # Skill definitions
│   ├── bmad/              # BMAD workflow skills
│   ├── ralph-loop/        # Ralph Loop orchestrator
│   ├── vsa-fsd/           # Architecture skills
│   └── testing-modern/    # Testing strategies
│
├── rules/                 # Development rules
│   ├── api-first.md
│   ├── fsd-architecture.md
│   ├── vsa-architecture.md
│   ├── typescript-strict.md
│   └── testing-strategy.md
│
├── hooks/                 # Automation hooks
│   ├── auto-format.sh
│   ├── typescript-preflight.sh
│   ├── check-tests-pass.sh
│   ├── vsa-validate.sh
│   └── session-start-continuity.sh
│
├── commands/              # Custom slash commands
├── templates/             # Project templates
└── scripts/               # Utility scripts
```

---

## Workflow

### 1. Initialize Project

```bash
/init-project
```

Creates project structure with:
- TypeScript configuration (strict mode)
- ESLint and Prettier setup
- Docker Compose for local development
- OpenAPI template
- VSA backend structure
- FSD frontend structure

### 2. Start BMAD Workflow

```bash
/workflow-init
```

Initializes the BMAD (Business, Marketing, Architecture, Development) workflow.

### 3. Create Product Brief

```bash
/product-brief
```

Define your product vision, target audience, and success metrics.

### 4. Generate PRD

```bash
/prd
```

Creates detailed Product Requirements Document with user stories.

### 5. Design Architecture

```bash
/architecture
```

Technical architecture document covering:
- System design
- Database schema
- API structure
- Security considerations

### 6. Create Stories

```bash
/create-epics-and-stories
```

Breaks down PRD into implementable epics and user stories.

### 7. Run Ralph Loop

```bash
/ralph-loop
```

Autonomous implementation of stories:
- Processes stories sequentially
- Each story goes through all 6 subagents
- Continues until completion or blocker
- Updates ledger with progress

---

## Commands Reference

### Project Setup

| Command | Description |
|---------|-------------|
| `/init-project` | Create new project with full setup |
| `/workflow-init` | Initialize BMAD workflow |

### BMAD Workflow

| Command | Description |
|---------|-------------|
| `/product-brief` | Create product brief |
| `/prd` | Generate PRD from brief |
| `/architecture` | Design technical architecture |
| `/create-epics-and-stories` | Break down into stories |

### Implementation

| Command | Description |
|---------|-------------|
| `/ralph-loop` | Start autonomous implementation |
| `/ralph-loop --resume` | Resume after blocker |
| `/ralph-loop --batch` | Process multiple stories |

### Validation

| Command | Description |
|---------|-------------|
| `/validate-all` | Run full validation suite |
| `/validate:vsa` | Check VSA architecture |
| `/validate:fsd` | Check FSD architecture |
| `/validate:api` | Verify OpenAPI sync |

### Utilities

| Command | Description |
|---------|-------------|
| `/commit` | Create git commit (no Claude attribution) |
| `/create_handoff` | Create handoff document |
| `/resume_handoff` | Resume from handoff |

---

## VSA Architecture (Backend)

Vertical Slice Architecture organizes code by feature:

```
src/
├── features/
│   └── users/
│       └── create-user/
│           ├── controller.ts    # HTTP handler
│           ├── service.ts       # Business logic
│           ├── repository.ts    # Data access
│           ├── dto.ts           # Zod schemas
│           └── index.ts         # Public API
├── shared/
│   ├── middleware/
│   ├── utils/
│   └── types/
└── prisma/
    └── schema.prisma
```

**Rules:**
- Each feature is self-contained
- No cross-feature imports
- Controller -> Service -> Repository hierarchy
- All inputs validated with Zod

---

## FSD Architecture (Frontend)

Feature-Sliced Design organizes code by layers:

```
src/
├── app/           # Initialization, providers
├── pages/         # Full pages (1 per route)
├── widgets/       # Compound UI blocks
├── features/      # Business features
├── entities/      # Business entities
└── shared/        # UI kit, hooks, utils, api
```

**Import Rules (top to bottom only):**
- `pages` -> widgets, features, entities, shared
- `widgets` -> features, entities, shared
- `features` -> entities, shared
- `entities` -> shared
- `shared` -> external packages only

---

## Testing Strategy

Inverted Test Pyramid (70% integration):

```
        /\
       /E2E\        5-10%
      /------\
     /Integr- \     70%
    /  ation   \
   /------------\
  /    Unit      \  20%
 /________________\
```

- **Unit tests**: Pure functions, utilities (Vitest)
- **Integration tests**: API endpoints, DB queries (Vitest + Supertest)
- **E2E tests**: Critical user flows (Playwright MCP)

**Minimum coverage: 80%**

---

## Requirements

### Required

- **Claude Code** - CLI installed and authenticated
- **Node.js** >= 18.x
- **Git** >= 2.x
- **pnpm** >= 8.x (installed automatically if missing)

### Optional

- **Docker** >= 24.x (for local development)
- **jq** (for smart settings merging during install)

### Check Prerequisites

```bash
node --version  # >= 18.x
git --version   # >= 2.x
pnpm --version  # >= 8.x
docker --version  # >= 24.x (optional)
```

---

## Installation

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/lindwerg/claude-starter/main/install.sh | bash
```

### Manual Install

```bash
git clone https://github.com/kirill/claude-starter.git
cd claude-starter
./install.sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/lindwerg/claude-starter/main/install.ps1 | iex
```

### What Gets Installed

1. Skills, rules, hooks, commands, agents -> `~/.claude/`
2. Settings merged (preserves your existing settings)
3. MCP config merged (preserves your existing servers)
4. Templates and scripts installed
5. Backup of existing config created

---

## Uninstall

```bash
./uninstall.sh
```

Or manually:

```bash
rm -rf ~/.claude/skills/bmad
rm -rf ~/.claude/skills/ralph-loop
rm -rf ~/.claude/agents
# etc.
```

Restore from backup:

```bash
cp -r ~/.claude-backup-<timestamp>/* ~/.claude/
```

---

## Upgrading

```bash
# Pull latest version
cd claude-starter
git pull origin main

# Re-run installer (merges settings)
./install.sh
```

---

## Troubleshooting

### Skills not loading

1. Restart Claude Code
2. Check `~/.claude/settings.json` for syntax errors
3. Verify skill files exist in `~/.claude/skills/`

### Hooks not running

1. Check hook files are executable: `chmod +x ~/.claude/hooks/*.sh`
2. Verify hooks are registered in `~/.claude/settings.json`
3. Test manually: `echo '{"test": true}' | ~/.claude/hooks/auto-format.sh`

### MCP servers not connecting

1. Check `~/.claude/mcp_config.json` syntax
2. Verify server dependencies installed
3. Check server logs in Claude Code output

---

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Make changes
4. Test installation on clean system
5. Submit pull request

---

## License

MIT License

Copyright (c) 2024

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## Acknowledgments

- [Claude Code](https://claude.ai/claude-code) by Anthropic
- [Feature-Sliced Design](https://feature-sliced.design/)
- [Vertical Slice Architecture](https://www.jimmybogard.com/vertical-slice-architecture/)
- [BMAD Method](https://bmad.dev/)
