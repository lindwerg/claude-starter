# Project Instructions

> Inherits from `~/.claude/CLAUDE.md` (FSD + VSA standards)

## Communication

Always respond in **Russian**. Be direct, focus on architecture.

## Project Structure

- `backend/` — VSA (Vertical Slice Architecture)
- `frontend/` — FSD (Feature-Sliced Design)
- `docs/` — PRD, Architecture, API spec
- `.bmad/` — Sprint state and task queue

## Quick Commands

```bash
pnpm dev           # Start backend + frontend
pnpm typecheck     # TypeScript check
pnpm test          # Run tests
pnpm db:migrate    # Prisma migrations
pnpm db:studio     # Prisma Studio GUI
```

## Workflow

1. `/product-brief` — Business requirements
2. `/architecture` — Tech design
3. `/validate-sprint` — Generate task queue
4. `/ralph-loop` — Autonomous development
