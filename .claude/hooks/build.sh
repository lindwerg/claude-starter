#!/bin/bash
# Build script for Claude Code hooks
# Compiles TypeScript to JavaScript using esbuild

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building hooks..."

# Ensure dist directory exists
mkdir -p dist

# Build each hook separately for better error isolation
HOOKS=(
  "types"
  "typescript-preflight"
  "vsa-validate"
  "auto-format"
  "check-tests-pass"
  "session-start-continuity"
  "pre-compact-save-state"
  "task-verification"
  "ralph-sprint-completion"
  "ralph-validation-enforcer"
  "ralph-validation-cleanup"
)

# First build types.ts as a separate module
npx esbuild src/types.ts \
  --bundle \
  --platform=node \
  --format=esm \
  --outfile=dist/types.js \
  --external:fs \
  --external:path \
  --external:child_process \
  --external:yaml

# Build each hook with types bundled
for hook in "${HOOKS[@]}"; do
  if [ "$hook" != "types" ]; then
    echo "  Building $hook..."
    npx esbuild "src/$hook.ts" \
      --bundle \
      --platform=node \
      --format=esm \
      --outfile="dist/$hook.js" \
      --external:fs \
      --external:path \
      --external:child_process \
      --external:yaml
  fi
done

echo "Build complete. Output in dist/"
ls -la dist/
