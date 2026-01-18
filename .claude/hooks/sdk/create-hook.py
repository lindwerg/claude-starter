#!/usr/bin/env python3
"""Hook generator using cchooks SDK"""
import argparse
from pathlib import Path

HOOK_TEMPLATE = '''#!/usr/bin/env python3
from cchooks import create_context

c = create_context()

# TODO: Implement hook logic
if c.tool_name == "{tool_name}":
    # Your logic here
    c.output.exit_success()
else:
    c.output.exit_success()
'''

SHELL_WRAPPER = '''#!/bin/bash
set -e
cd "$CLAUDE_PROJECT_DIR/.claude/hooks"
cat | uv run python {hook_name}.py
'''

def main():
    parser = argparse.ArgumentParser(
        description='Generate Claude Code hook using cchooks SDK'
    )
    parser.add_argument('--name', required=True, help='Hook name (e.g., code-review)')
    parser.add_argument(
        '--event',
        required=True,
        choices=['PreToolUse', 'PostToolUse', 'UserPromptSubmit', 'SessionStart', 'SessionEnd', 'PreCompact', 'Stop'],
        help='Hook event type'
    )
    parser.add_argument('--tool', required=True, help='Tool name (e.g., Edit, Write, Bash)')
    args = parser.parse_args()

    hooks_dir = Path('.claude/hooks')
    if not hooks_dir.exists():
        print(f"Error: {hooks_dir} does not exist")
        return 1

    # Create Python hook
    hook_file = hooks_dir / f"{args.name}.py"
    hook_file.write_text(HOOK_TEMPLATE.format(tool_name=args.tool))
    hook_file.chmod(0o755)

    # Create shell wrapper
    shell_file = hooks_dir / f"{args.name}.sh"
    shell_file.write_text(SHELL_WRAPPER.format(hook_name=args.name))
    shell_file.chmod(0o755)

    print(f"✓ Created {hook_file}")
    print(f"✓ Created {shell_file}")
    print(f"\nNext: Add to .claude/settings.json:")
    print(f'"{args.event}": [{{"matcher": ["{args.tool}"], "hooks": [{{"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/{args.name}.sh"}}]}}]')

    return 0

if __name__ == '__main__':
    exit(main())
