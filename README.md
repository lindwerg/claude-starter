<p align="center">
  <img src="https://img.shields.io/badge/version-2.1.0-blue?style=for-the-badge" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-green?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/node-%3E%3D18-brightgreen?style=for-the-badge" alt="Node">
  <img src="https://img.shields.io/badge/Claude%20Code-required-orange?style=for-the-badge" alt="Claude Code">
</p>

<h1 align="center">Provide Starter Kit</h1>

<p align="center">
  <strong>Autonomous Full-Stack Development with Claude Code</strong>
</p>

<p align="center">
  Transform Claude Code into a production-ready development pipeline.<br>
  From idea to deployed app — <em>automatically</em>.
</p>

---

## Why Provide?

Most starter kits give you **files**. Provide gives you a **development pipeline**.

| Traditional Templates | Provide Starter Kit |
|----------------------|---------------------|
| Copy files, figure out the rest | Automated workflow from planning to deployment |
| Manual code review | Quality gates that **block** bad code |
| Hope tests pass | TDD enforced through task dependencies |
| Context lost between sessions | Full traceability with sprint archives |

**Result:** Claude Code autonomously implements features, writes tests, and maintains code quality — while you focus on the product.

---

## Quick Start

### 1. Install (30 seconds)

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/lindwerg/claude-starter/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/lindwerg/claude-starter/main/install.ps1 | iex
```

### 2. Create Your First Project

```bash
mkdir my-app && cd my-app
claude
```

### 3. Start Building

```bash
/init-project      # Creates FSD/VSA project structure
/ralph-loop        # Starts autonomous development
```

**That's it!** Claude will now autonomously implement your features.

---

## Features

<table>
<tr>
<td width="50%">

### Ralph Loop
Autonomous task execution. Processes **100+ tasks** without human intervention. Each task gets fresh context = no hallucinations.

</td>
<td width="50%">

### Quality Gates
TypeScript errors? **Blocked.** ESLint warnings? **Blocked.** Tests failing? **Blocked.** No bad code gets through.

</td>
</tr>
<tr>
<td width="50%">

### Architecture First
**FSD** (Feature-Sliced Design) for frontend. **VSA** (Vertical Slice Architecture) for backend. Production patterns from day one.

</td>
<td width="50%">

### TDD Enforced
Tests come first. Task dependencies ensure `test → implementation → verify` order. No skipping allowed.

</td>
</tr>
<tr>
<td width="50%">

### API-First Development
OpenAPI spec is the single source of truth. Types are generated, not written. Backend validates against spec.

</td>
<td width="50%">

### Multi-Sprint Support
Seamless sprint transitions. Archives preserve full history. Pick up exactly where you left off.

</td>
</tr>
</table>

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PROVIDE WORKFLOW                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   /init-project        /architecture        /ralph-loop             │
│        │                    │                    │                   │
│        ▼                    ▼                    ▼                   │
│   ┌─────────┐         ┌─────────┐         ┌─────────────┐           │
│   │ Project │         │  Tech   │         │  Autonomous │           │
│   │Structure│    →    │ Design  │    →    │  Execution  │           │
│   └─────────┘         └─────────┘         └─────────────┘           │
│                                                  │                   │
│                                                  ▼                   │
│                                           ┌───────────┐             │
│                                           │  Quality  │             │
│                                           │   Gates   │             │
│                                           └───────────┘             │
│                                                  │                   │
│                                    ┌─────────────┼─────────────┐    │
│                                    │             │             │    │
│                                    ▼             ▼             ▼    │
│                               TypeCheck       Lint          Test    │
│                                    │             │             │    │
│                                    └─────────────┴─────────────┘    │
│                                                  │                   │
│                                                  ▼                   │
│                                              COMMIT                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Commands Reference

### Core Workflow

| Command | Description |
|---------|-------------|
| `/init-project` | Create FSD/VSA project structure with all configs |
| `/product-brief` | Business analysis and requirements gathering |
| `/prd` | Generate Product Requirements Document |
| `/architecture` | Design technical architecture + openapi.yaml |
| `/sprint-planning` | Break down into epics and stories |
| `/validate-sprint` | Generate task queue from sprint plan |
| `/ralph-loop` | **Start autonomous execution** |

### Validation & Quality

| Command | Description |
|---------|-------------|
| `/validate-all` | Full architecture validation (VSA/FSD) |
| `/vsa-fsd` | Check architecture pattern compliance |
| `/workflow-status` | Show current project progress |

### Utilities

| Command | Description |
|---------|-------------|
| `/help` | Show all available commands |
| `/create-story` | Create a single story manually |
| `/dev-story` | Develop one story interactively |
| `/commit` | Git commit (no Claude attribution) |

---

## Project Structure

After `/init-project`, you get:

```
my-app/
├── backend/
│   ├── src/
│   │   ├── features/          # VSA vertical slices
│   │   │   └── users/
│   │   │       └── createUser/
│   │   │           ├── controller.ts
│   │   │           ├── service.ts
│   │   │           ├── repository.ts
│   │   │           └── dto.ts
│   │   └── shared/            # Middleware, utils
│   ├── prisma/schema.prisma   # Database schema
│   └── openapi.yaml           # API contract
│
├── frontend/
│   └── src/
│       ├── app/               # App initialization
│       ├── pages/             # Route pages
│       ├── widgets/           # Standalone UI blocks
│       ├── features/          # Business features
│       ├── entities/          # Business entities
│       └── shared/            # UI kit, hooks, utils
│
├── docker-compose.yml         # PostgreSQL + Redis
├── package.json
└── .claude/                   # Claude Code config
```

---

## Tech Stack

| Layer | Technologies |
|-------|-------------|
| **Frontend** | React 18+, TypeScript (strict), TanStack Query, Zustand, Tailwind CSS |
| **Backend** | Node.js, Express/Fastify, Prisma, PostgreSQL, Zod |
| **Testing** | Vitest, Testing Library, Playwright |
| **Infrastructure** | Docker, pnpm, Vite |

---

## Requirements

| Requirement | Version | Notes |
|-------------|---------|-------|
| **Node.js** | >= 18 | Required |
| **Claude Code** | Latest | Install: `npm install -g @anthropic-ai/claude-code` |
| **Git** | >= 2.x | For version control |
| **Docker** | Latest | Optional, for databases |

---

## Installation Options

### Option 1: One-liner (Recommended)

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/lindwerg/claude-starter/main/install.sh | bash
```

**Windows:**
```powershell
irm https://raw.githubusercontent.com/lindwerg/claude-starter/main/install.ps1 | iex
```

### Option 2: npx (No Install)

```bash
npx lindwerg-go init
```

### Option 3: Global Install

```bash
npm install -g lindwerg-go
provide-starter init
```

### What Gets Installed

```
~/.claude/
├── skills/         # Slash commands (/init-project, /ralph-loop, etc.)
├── rules/          # Code quality rules (FSD, VSA, TypeScript strict)
├── agents/         # Subagents for Ralph Loop
├── hooks/          # Quality enforcement hooks
├── templates/      # Project templates
└── settings.json   # Hook configuration
```

---

## Uninstall

```bash
bash ~/.claude/uninstall.sh
```

Or manually:
```bash
rm -rf ~/.claude/skills/provide
rm -rf ~/.claude/rules
rm -rf ~/.claude/hooks
```

---

## FAQ

<details>
<summary><strong>What is Ralph Loop?</strong></summary>

**R**elentless **A**utonomous **L**oop for **P**roduct **H**acking.

Ralph reads `task-queue.yaml` and executes tasks one by one:
1. Pick next pending task
2. Spawn specialized subagent (backend/frontend/test)
3. Implement with fresh context
4. Run quality gates (typecheck/lint/test)
5. Commit if all pass
6. Move to next task

</details>

<details>
<summary><strong>How do Quality Gates work?</strong></summary>

Hooks intercept Edit/Write operations and block if:
- TypeScript has errors → **BLOCKED**
- ESLint has errors → **BLOCKED**
- Tests are failing → **BLOCKED**

No way to bypass. Code quality is **enforced**, not suggested.

</details>

<details>
<summary><strong>What's FSD / VSA?</strong></summary>

**FSD (Feature-Sliced Design)** — Frontend architecture with clear layer boundaries:
- `app/` → `pages/` → `widgets/` → `features/` → `entities/` → `shared/`
- Import only from layers below

**VSA (Vertical Slice Architecture)** — Backend pattern where each endpoint is isolated:
- `createUser/` contains controller, service, repository, dto
- No cross-feature imports

</details>

<details>
<summary><strong>Can I use this with existing projects?</strong></summary>

Yes! Run install script, then in your project:
```bash
claude
/validate-all    # Check current architecture
/help            # See available commands
```

</details>

---

## Contributing

Contributions welcome! Areas for improvement:

- [ ] E2E scenario validator enhancements
- [ ] Parallel task execution
- [ ] New blocker type detectors
- [ ] Coverage threshold gates
- [ ] Docker-compose auto-generation

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

---

## Documentation

| Document | Description |
|----------|-------------|
| [INSTALLATION.md](./docs/INSTALLATION.md) | Detailed installation guide |
| [WORKFLOW.md](./docs/WORKFLOW.md) | BMAD workflow explanation |
| [AGENTS.md](./docs/AGENTS.md) | Subagent roles and capabilities |
| [HOOKS.md](./.claude/hooks/README.md) | Hook system documentation |

---

## License

MIT — see [LICENSE](./LICENSE) for details.

---

<p align="center">
  <strong>Built for Claude Code</strong> — The best AI pair programmer.
</p>

<p align="center">
  <a href="https://github.com/lindwerg/claude-starter/issues">Report Bug</a>
  ·
  <a href="https://github.com/lindwerg/claude-starter/issues">Request Feature</a>
</p>
