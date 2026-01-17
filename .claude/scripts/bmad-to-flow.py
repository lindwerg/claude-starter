#!/usr/bin/env python3
"""
BMAD to Flow-Next Converter

Converts .bmad/task-queue.yaml to Flow-Next format (.flow/)
for use with gmickel's Flow-Next Ralph autonomous loop.

Usage:
    python bmad-to-flow.py [--task-queue PATH] [--flowctl PATH]

Example:
    python .claude/scripts/bmad-to-flow.py
    python .claude/scripts/bmad-to-flow.py --task-queue .bmad/task-queue.yaml
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

# Try to import yaml, fall back to manual parsing if not available
try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False


def parse_yaml_simple(content: str) -> dict:
    """Simple YAML parser for task-queue.yaml format."""
    import re

    result = {
        'version': '1.0',
        'project': '',
        'sprint': 1,
        'summary': {},
        'tasks': []
    }

    lines = content.split('\n')
    current_task = None
    current_list_key = None

    for line in lines:
        stripped = line.strip()

        # Skip comments and empty lines
        if not stripped or stripped.startswith('#'):
            continue

        # Top-level keys
        if line.startswith('version:'):
            result['version'] = stripped.split(':', 1)[1].strip().strip('"\'')
        elif line.startswith('project:'):
            result['project'] = stripped.split(':', 1)[1].strip().strip('"\'')
        elif line.startswith('sprint:'):
            result['sprint'] = int(stripped.split(':', 1)[1].strip())
        elif stripped.startswith('- id:'):
            # New task
            if current_task:
                result['tasks'].append(current_task)
            current_task = {'id': stripped.split(':', 1)[1].strip().strip('"\''), 'depends_on': [], 'outputs': [], 'acceptance': []}
            current_list_key = None
        elif current_task and ':' in stripped:
            key, value = stripped.split(':', 1)
            key = key.strip()
            value = value.strip().strip('"\'')

            if key in ('story_id', 'title', 'type', 'status'):
                current_task[key] = value
            elif key == 'estimated_minutes':
                current_task[key] = int(value) if value else 30
            elif key in ('depends_on', 'outputs', 'acceptance'):
                current_list_key = key
                if value and value != '[]':
                    current_task[key] = [v.strip().strip('"\'') for v in value.strip('[]').split(',')]
        elif current_task and stripped.startswith('- ') and current_list_key:
            current_task[current_list_key].append(stripped[2:].strip().strip('"\''))

    if current_task:
        result['tasks'].append(current_task)

    return result


def load_task_queue(path: str) -> dict:
    """Load task-queue.yaml file."""
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    if HAS_YAML:
        return yaml.safe_load(content)
    else:
        return parse_yaml_simple(content)


def run_flowctl(flowctl_path: str, *args) -> dict | None:
    """Run flowctl command and return JSON output."""
    cmd = [flowctl_path] + list(args)
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=os.getcwd()
        )
        if result.returncode != 0:
            print(f"flowctl error: {result.stderr}", file=sys.stderr)
            return None
        if result.stdout.strip():
            try:
                return json.loads(result.stdout)
            except json.JSONDecodeError:
                return {'output': result.stdout}
        return {}
    except FileNotFoundError:
        print(f"flowctl not found at: {flowctl_path}", file=sys.stderr)
        return None


def create_task_spec(task: dict, epic_id: str, task_num: int) -> str:
    """Generate task spec markdown."""
    task_id = f"{epic_id}.{task_num}"
    title = task.get('title', 'Untitled')
    story_id = task.get('story_id', 'Unknown')
    task_type = task.get('type', 'backend')
    estimated = task.get('estimated_minutes', 30)
    outputs = task.get('outputs', [])
    acceptance = task.get('acceptance', [])

    outputs_str = ', '.join(outputs) if outputs else 'None specified'
    acceptance_str = '\n'.join(f'- [ ] {a}' for a in acceptance) if acceptance else '- [ ] TBD'

    return f"""# {task_id} {title}

## Description
**Story:** {story_id}
**Type:** {task_type}
**Estimated:** {estimated} minutes
**Outputs:** {outputs_str}

## Acceptance
{acceptance_str}

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
"""


def build_dependency_map(tasks: list) -> dict[str, int]:
    """Build mapping from BMAD task ID to sequential index."""
    return {task['id']: i + 1 for i, task in enumerate(tasks)}


def convert_dependencies(task: dict, dep_map: dict[str, int], epic_id: str) -> list[str]:
    """Convert BMAD dependencies to Flow-Next format."""
    deps = task.get('depends_on', [])
    flow_deps = []
    for dep in deps:
        if dep in dep_map:
            flow_deps.append(f"{epic_id}.{dep_map[dep]}")
    return flow_deps


def main():
    parser = argparse.ArgumentParser(description='Convert BMAD task-queue to Flow-Next format')
    parser.add_argument('--task-queue', default='.bmad/task-queue.yaml', help='Path to task-queue.yaml')
    parser.add_argument('--flowctl', default='./scripts/ralph/flowctl', help='Path to flowctl')
    parser.add_argument('--dry-run', action='store_true', help='Print actions without executing')
    args = parser.parse_args()

    # Validate paths
    if not os.path.exists(args.task_queue):
        print(f"Error: task-queue.yaml not found at {args.task_queue}", file=sys.stderr)
        sys.exit(1)

    if not os.path.exists(args.flowctl) and not args.dry_run:
        print(f"Error: flowctl not found at {args.flowctl}", file=sys.stderr)
        sys.exit(1)

    # Load task queue
    print(f"Loading {args.task_queue}...")
    queue = load_task_queue(args.task_queue)
    tasks = queue.get('tasks', [])
    sprint = queue.get('sprint', 1)
    project = queue.get('project', 'project')

    print(f"Found {len(tasks)} tasks for Sprint {sprint}")

    if args.dry_run:
        print("\n[DRY RUN] Would execute:")
        print(f"  flowctl init")
        print(f"  flowctl epic create --title 'Sprint {sprint}: {project}'")
        for i, task in enumerate(tasks, 1):
            print(f"  flowctl task create --epic fn-1 --title '{task.get('title', '')}'")
        return

    # Initialize .flow/
    print("\nInitializing .flow/...")
    run_flowctl(args.flowctl, 'init')

    # Create epic
    print(f"\nCreating epic for Sprint {sprint}...")
    epic_result = run_flowctl(
        args.flowctl, 'epic', 'create',
        '--title', f"Sprint {sprint}: {project}",
        '--json'
    )

    if not epic_result or 'id' not in epic_result:
        # Try to get existing epic
        epics_result = run_flowctl(args.flowctl, 'epics', '--json')
        if epics_result and isinstance(epics_result, list) and len(epics_result) > 0:
            epic_id = epics_result[-1].get('id', 'fn-1')
        else:
            epic_id = 'fn-1'
        print(f"Using existing epic: {epic_id}")
    else:
        epic_id = epic_result['id']
        print(f"Created epic: {epic_id}")

    # Build dependency map
    dep_map = build_dependency_map(tasks)

    # Create tasks
    print(f"\nCreating {len(tasks)} tasks...")
    flow_dir = Path('.flow')
    tasks_dir = flow_dir / 'tasks'
    tasks_dir.mkdir(parents=True, exist_ok=True)

    for i, task in enumerate(tasks, 1):
        title = task.get('title', f'Task {i}')
        deps = convert_dependencies(task, dep_map, epic_id)
        deps_str = ','.join(deps) if deps else ''

        # Create task
        task_args = [
            args.flowctl, 'task', 'create',
            '--epic', epic_id,
            '--title', title,
            '--json'
        ]
        if deps_str:
            task_args.extend(['--deps', deps_str])

        result = run_flowctl(*task_args)
        task_flow_id = f"{epic_id}.{i}"

        if result:
            print(f"  [{i}/{len(tasks)}] Created {task_flow_id}: {title[:40]}...")
        else:
            print(f"  [{i}/{len(tasks)}] Failed to create task: {title[:40]}...")
            continue

        # Write task spec (always overwrite with our acceptance criteria)
        spec_content = create_task_spec(task, epic_id, i)
        spec_path = tasks_dir / f"{task_flow_id}.md"
        spec_path.write_text(spec_content, encoding='utf-8')

    # Summary
    print(f"\n{'='*50}")
    print("Conversion complete!")
    print(f"{'='*50}")
    print(f"Epic: {epic_id}")
    print(f"Tasks: {len(tasks)}")
    print(f"\nNext steps:")
    print(f"  1. Review: ./scripts/ralph/flowctl tasks --epic {epic_id} --json")
    print(f"  2. Check ready: ./scripts/ralph/flowctl ready --epic {epic_id} --json")
    print(f"  3. Run Ralph: ./scripts/ralph/ralph.sh")


if __name__ == '__main__':
    main()
