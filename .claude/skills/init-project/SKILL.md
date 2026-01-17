---
name: init-project
description: Initialize full-stack project with FSD/VSA architecture
allowed-tools: [Bash, Read, Write, Glob]
---

# Init Project Skill

Initialize a new full-stack project with:
- **Backend**: VSA (Vertical Slice Architecture) with Express + Prisma
- **Frontend**: FSD (Feature-Sliced Design) with React + TanStack Query
- **Infrastructure**: Docker Compose with PostgreSQL + Redis
- **MCP servers**: context7, playwright

## When to Use

Run this when:
- Starting a new full-stack project from scratch
- User says "создай проект", "новый проект", "init project"

## Usage

```bash
# Interactive mode (asks for project name)
bash ~/.claude/scripts/init-fullstack-project.sh

# With project name
bash ~/.claude/scripts/init-fullstack-project.sh my-app

# With options
bash ~/.claude/scripts/init-fullstack-project.sh my-app --no-docker --no-git
```

## Options

| Flag | Description |
|------|-------------|
| `--no-docker` | Skip Docker setup |
| `--no-git` | Skip git initialization |
| `--no-deps` | Skip dependency installation |

## What It Creates

```
my-app/
├── backend/
│   ├── src/
│   │   ├── features/health/     # Health check endpoint
│   │   ├── shared/              # Middleware, utils, types
│   │   └── app.ts
│   ├── prisma/schema.prisma
│   └── package.json
├── frontend/
│   ├── src/
│   │   ├── app/                 # Providers, global styles
│   │   ├── pages/               # Route pages
│   │   ├── widgets/             # Complex UI blocks
│   │   ├── features/            # Business features
│   │   ├── entities/            # Business entities
│   │   └── shared/              # UI kit, hooks, api
│   └── package.json
├── docker-compose.yml
├── .mcp.json                    # MCP servers config
└── .env
```

## After Running

1. Check Docker containers: `docker compose ps`
2. Start backend: `cd backend && pnpm dev`
3. Start frontend: `cd frontend && pnpm dev`
4. Health check: `curl http://localhost:3000/api/health`

## Workflow

```
1. /init-project my-app     → Creates project structure
2. /ralph-loop              → Autonomous implementation loop
3. /commit                  → Commit changes
```
