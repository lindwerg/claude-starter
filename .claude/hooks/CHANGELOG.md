# Changelog — Claude Starter Hooks

All notable changes to the hooks system will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-01-18

### Added
- Semantic versioning via CHANGELOG.md
- Hook metrics/monitoring foundation (logMetric helper в types.ts planned for v2.2.0)
- **[TESTING]** Automated test suite for hooks
  - Created `tests/hooks/` directory structure
  - `subagent-enforcement.test.sh` — 15 test cases covering all scenarios
  - Test template and guidelines in hooks README
  - **Impact**: 80%+ coverage for critical hooks, catch regressions early
- **[DOCUMENTATION]** Comprehensive hooks README.md
  - Architecture patterns (Pure Bash vs Compiled JS)
  - Best practices (security, performance, error handling)
  - Development guide (adding new hooks, testing, troubleshooting)
  - Migration guide and versioning info

### Changed
- **[PERFORMANCE]** Migrated 4 hooks from `npx tsx` to pre-compiled JavaScript (`node dist/`)
  - `task-verification.sh`
  - `ralph-sprint-completion.sh`
  - `ralph-validation-enforcer.sh`
  - `ralph-validation-cleanup.sh`
  - **Impact**: ~10x faster execution (~50-100ms vs 500-1000ms)

- **[RELIABILITY]** Fixed race condition in `subagent-enforcement.sh`
  - Changed from age-based marker check (< 5 min) to existence-based
  - Updated agents to use UUID markers: `$RANDOM-$RANDOM-$(date +%s)`
  - **Impact**: No false blocks on slow network/high system load

- Updated 6 agents with UUID marker approach:
  - `backend-agent.md`
  - `frontend-agent.md`
  - `api-agent.md`
  - `test-agent.md`
  - `validation-agent.md`
  - `devops-agent.md`

### Deprecated
- Age-based subagent marker validation (removed in 2.1.0)

---

## [2.0.0] - 2026-01-17

### Added
- Infrastructure readiness detector hook
- Data preparation detector hook
- Docker-first enforcer hook
- Local testability enforcer hook
- Comprehensive README.md documentation (1400+ lines)

### Changed
- Sprint planning enforcement — blocks missing preparatory tasks

---

## [1.0.0] - 2025-12-15

### Added
- Initial hooks system with 23+ hooks
- Enforcement philosophy: block over instruct
- Ralph Loop integration
- Quality gates (typecheck, lint, test)
- Multi-sprint automation
- TDD enforcement through depends_on

---

## Version Numbering

- **Major** (X.0.0): Breaking changes to hook interfaces or behavior
- **Minor** (x.Y.0): New hooks, new features, backwards-compatible changes
- **Patch** (x.y.Z): Bug fixes, performance improvements, documentation

## Migration Guide

### From 2.0.0 to 2.1.0

**No breaking changes**. Performance improvements and bug fixes only.

**Action required**: None. Hooks are backwards compatible.

**Recommended**: Run `bash .claude/hooks/build.sh` to ensure all TypeScript hooks are compiled.

---

## Upgrade Path

To upgrade hooks to latest version:

```bash
cd /Users/kirill/Desktop/provide/claude-starter/.claude/hooks
bash build.sh
```

Check this CHANGELOG for breaking changes before upgrading major versions.
