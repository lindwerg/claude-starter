---
date: 2026-01-17T23:42:58+03:00
session_name: general
researcher: claude
git_commit: 0d1fde8
branch: main
repository: claude-starter
topic: "Ralph Loop Improvements - Subagents, Auto-restart, Auto-commit"
tags: [ralph-loop, automation, hooks, subagents]
status: partial
last_updated: 2026-01-17
last_updated_by: claude
type: implementation_strategy
root_span_id:
turn_span_id:
---

# Handoff: Ralph Loop Automation Improvements

## Task(s)

1. **Enforce subagent usage in Ralph Loop** — COMPLETED
   - Added MANDATORY section to SKILL.md requiring Task tool for each task
   - Ralph now spawns backend-agent, frontend-agent etc.

2. **Auto-restart on context overflow** — COMPLETED (semi-automatic)
   - Modified `skill-activation-prompt.mjs` for Ralph-specific warnings at 85%
   - Created `session-start-ralph.sh` hook to prompt resume after /clear
   - Added progress marker `.bmad/ralph-in-progress`

3. **Auto-commit without confirmation** — PARTIALLY DONE
   - Changed SKILL.md to use direct `git add -A && git commit` instead of /commit skill
   - BUT: Ralph still not committing after each task — needs verification

4. **lindwerg-go npm package** — COMPLETED
   - Published `npx lindwerg-go` for one-command project creation
   - Version 1.0.3 on npm

## Critical References

- `.claude/skills/ralph-loop/SKILL.md` — Main skill file with MANDATORY section
- `~/.claude/hooks/dist/skill-activation-prompt.mjs:123-145` — Context warning logic
- `.claude/hooks/session-start-ralph.sh` — Resume prompt hook

## Recent changes

- `.claude/skills/ralph-loop/SKILL.md:7-62` — MANDATORY: FIRST ACTIONS section
- `.claude/skills/ralph-loop/SKILL.md:350-360` — Auto-commit without /commit skill
- `.claude/hooks/session-start-ralph.sh` — New hook for Ralph resume
- `.claude/settings.json:66-72` — Registered session-start-ralph hook
- `~/.claude/hooks/dist/skill-activation-prompt.mjs:123-145` — Ralph-specific context warnings
- `packages/lindwerg-go/` — npm package for project scaffolding

## Learnings

1. **SKILL.md instructions are not reliably followed** — Claude reads skills but doesn't always follow all instructions. Need to put CRITICAL actions at the very top in MANDATORY section.

2. **Hooks can't control Claude directly** — Hooks can only return messages or block actions. Auto-restart is semi-automatic (shows prompt, user must act).

3. **yq not installed on user system** — Ralph falls back to TypeScript for YAML updates, which works but is less elegant.

4. **npm publish requires granular token** — With 2FA enabled, need token with "bypass 2FA" permission.

## Post-Mortem

### What Worked
- Adding MANDATORY section at top of SKILL.md — Ralph now uses subagents
- Semi-automatic context warning system — hooks show messages at 85%
- npm package lindwerg-go works perfectly

### What Failed
- Tried: Putting marker creation in "Step 0" deeper in file → Failed: Claude didn't read that far
- Tried: Using /commit skill for auto-commit → Failed: It asks for confirmation
- Error: hooks format "matcher must be string" → Fixed by splitting array into separate entries

### Key Decisions
- Decision: Semi-automatic restart instead of full auto
  - Alternatives: Full automation (not possible with hooks)
  - Reason: Hooks can't execute /clear or /ralph-loop

- Decision: Direct `git commit` instead of /commit skill
  - Alternatives: Modify /commit skill to have --no-confirm flag
  - Reason: Faster to change SKILL.md instruction

## Artifacts

- `.claude/skills/ralph-loop/SKILL.md` — Updated with MANDATORY section, marker, auto-commit
- `.claude/hooks/session-start-ralph.sh` — New hook
- `.claude/settings.json` — Updated hooks config
- `~/.claude/hooks/dist/skill-activation-prompt.mjs` — Modified for Ralph warnings
- `packages/lindwerg-go/` — npm package

## Action Items & Next Steps

1. **VERIFY auto-commit working** — Ralph should do `git add -A && git commit` after each task without asking. If not, need to make instruction more explicit.

2. **Add auto-push** — User asked for auto-push after each commit. Add `&& git push` to commit command in SKILL.md.

3. **Test full flow** — Run `/ralph-loop` in lolporn, verify:
   - Creates `.bmad/ralph-in-progress` marker
   - Uses subagents for tasks
   - Commits automatically
   - Shows warning at 85% context
   - After /clear shows resume prompt

4. **Install yq on user system** — `brew install yq` for cleaner YAML updates

## Other Notes

- lolporn project at `/Users/kirill/Desktop/lolporn` — test project created with lindwerg-go
- All changes also copied to lolporn (skills, hooks, settings)
- Context was 82% when handoff started
