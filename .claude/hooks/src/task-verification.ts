/**
 * Task Verification Hook (PostToolUse)
 *
 * Automatically verifies task completion after Write/Edit:
 * 1. Checks if created file is in current task's outputs
 * 2. Verifies all outputs exist
 * 3. Runs quality gates
 * 4. Updates task-queue.yaml status
 */

import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import { minimatch } from 'minimatch';
import { PostToolUseInput, HookOutput, readStdin, output } from './types';

// Task queue types
interface Task {
  id: string;
  title: string;
  status: string;
  outputs: string[];
  acceptance?: string[];
  started_at?: string;
  retries?: number;
}

interface QualityGate {
  name: string;
  command: string;
  required: boolean;
}

interface TaskQueue {
  current_task: string | null;
  tasks: Task[];
  quality_gates?: QualityGate[];
}

// Parse YAML using yq (to avoid adding yaml dependency)
function parseYaml(filePath: string): TaskQueue | null {
  try {
    const jsonOutput = execSync(`yq -o json '.' "${filePath}"`, {
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    return JSON.parse(jsonOutput);
  } catch {
    return null;
  }
}

// Check if file exists (supports full glob patterns with minimatch)
function checkOutput(outputPattern: string, projectDir: string): { exists: boolean; files: string[] } {
  const fullPath = path.join(projectDir, outputPattern);

  // Glob support with minimatch (supports *, **, ?, [], etc.)
  if (outputPattern.includes('*') || outputPattern.includes('?') || outputPattern.includes('[')) {
    try {
      // For ** patterns, need to recursively search
      if (outputPattern.includes('**')) {
        const matchedFiles = findFilesRecursive(projectDir, outputPattern);
        return { exists: matchedFiles.length > 0, files: matchedFiles };
      }

      // For simple * patterns in single directory
      const dir = path.dirname(fullPath);
      const pattern = path.basename(outputPattern);

      if (fs.existsSync(dir)) {
        const files = fs.readdirSync(dir)
          .filter((f) => minimatch(f, pattern, { dot: true }))
          .map((f) => path.join(dir, f));
        return { exists: files.length > 0, files };
      }
    } catch {
      return { exists: false, files: [] };
    }
  }

  // Direct file check
  const exists = fs.existsSync(fullPath);
  return { exists, files: exists ? [fullPath] : [] };
}

// Recursively find files matching glob pattern (for ** support)
function findFilesRecursive(dir: string, pattern: string): string[] {
  const results: string[] = [];

  function walk(currentDir: string) {
    try {
      const entries = fs.readdirSync(currentDir, { withFileTypes: true });

      for (const entry of entries) {
        const fullPath = path.join(currentDir, entry.name);
        const relativePath = path.relative(dir, fullPath);

        // Skip node_modules and .git
        if (relativePath.includes('node_modules') || relativePath.includes('.git')) {
          continue;
        }

        if (entry.isDirectory()) {
          walk(fullPath);
        } else if (minimatch(relativePath, pattern, { dot: true })) {
          results.push(fullPath);
        }
      }
    } catch {
      // Ignore permission errors
    }
  }

  walk(dir);
  return results;
}

// Run quality gates
function runGates(gates: QualityGate[], projectDir: string): { passed: boolean; failed?: string; error?: string } {
  for (const gate of gates) {
    if (!gate.required) continue;

    try {
      execSync(gate.command, {
        cwd: projectDir,
        stdio: ['pipe', 'pipe', 'pipe'],
        timeout: 60000, // 60 second timeout per gate
      });
    } catch (err: unknown) {
      const error = err as { stderr?: Buffer; stdout?: Buffer };
      const errorMsg = error.stderr?.toString() || error.stdout?.toString() || 'Unknown error';
      return { passed: false, failed: gate.name, error: errorMsg.slice(0, 500) };
    }
  }

  return { passed: true };
}

// Update task status using yq
function updateTaskStatus(taskId: string, projectDir: string): boolean {
  const queuePath = path.join(projectDir, '.bmad/task-queue.yaml');
  const now = new Date().toISOString();

  try {
    // Update status to done
    execSync(`yq -i '(.tasks[] | select(.id == "${taskId}") | .status) = "done"' "${queuePath}"`, {
      cwd: projectDir,
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    // Set completed_at timestamp
    execSync(`yq -i '(.tasks[] | select(.id == "${taskId}") | .completed_at) = "${now}"' "${queuePath}"`, {
      cwd: projectDir,
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    // Increment completed_tasks counter
    execSync(`yq -i '.summary.completed_tasks += 1' "${queuePath}"`, {
      cwd: projectDir,
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    // Clear current_task
    execSync(`yq -i '.current_task = null' "${queuePath}"`, {
      cwd: projectDir,
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    return true;
  } catch {
    return false;
  }
}

async function main(): Promise<void> {
  // Read stdin input
  const rawInput = await readStdin();

  let input: PostToolUseInput;
  try {
    input = JSON.parse(rawInput);
  } catch {
    output({ result: 'continue' });
    return;
  }

  // Only process Write/Edit
  if (!['Write', 'Edit'].includes(input.tool_name)) {
    output({ result: 'continue' });
    return;
  }

  const projectDir = process.env.CLAUDE_PROJECT_DIR || input.cwd || process.cwd();
  const queuePath = path.join(projectDir, '.bmad/task-queue.yaml');
  const ralphMarker = path.join(projectDir, '.bmad/ralph-in-progress');

  // Check Ralph is active
  if (!fs.existsSync(ralphMarker)) {
    output({ result: 'continue' });
    return;
  }

  // Check task-queue.yaml exists
  if (!fs.existsSync(queuePath)) {
    output({ result: 'continue' });
    return;
  }

  // Parse task queue
  const queue = parseYaml(queuePath);
  if (!queue) {
    output({ result: 'continue', message: '⚠️ Failed to parse task-queue.yaml' });
    return;
  }

  // Get current task
  if (!queue.current_task) {
    output({ result: 'continue' });
    return;
  }

  const currentTask = queue.tasks.find((t) => t.id === queue.current_task);
  if (!currentTask) {
    output({ result: 'continue' });
    return;
  }

  // Get written file path
  const filePath = input.tool_input.file_path as string;
  if (!filePath) {
    output({ result: 'continue' });
    return;
  }

  // Normalize path for comparison
  const relativePath = path.relative(projectDir, filePath);

  // Check if file matches any expected output
  const outputPatterns = currentTask.outputs || [];
  const matchesOutput = outputPatterns.some((pattern) => {
    // Normalize both for comparison
    const normalizedPattern = pattern.replace(/^\.\//, '');
    const normalizedPath = relativePath.replace(/^\.\//, '');

    // Use minimatch for glob patterns (supports *, **, ?, etc.)
    if (pattern.includes('*') || pattern.includes('?') || pattern.includes('[')) {
      return minimatch(normalizedPath, normalizedPattern, { dot: true });
    }

    return normalizedPattern === normalizedPath || pattern === filePath;
  });

  if (!matchesOutput) {
    // File written but not part of task outputs - skip silently
    output({ result: 'continue' });
    return;
  }

  // Check all outputs exist
  const outputResults = outputPatterns.map((pattern) => {
    const result = checkOutput(pattern, projectDir);
    return { pattern, ...result };
  });

  const existingCount = outputResults.filter((r) => r.exists).length;
  const totalCount = outputResults.length;

  if (existingCount < totalCount) {
    // Not all outputs created yet - show progress
    const missing = outputResults.filter((r) => !r.exists).map((r) => r.pattern);
    output({
      result: 'continue',
      message:
        `📦 Output verified: ${relativePath}\n` +
        `Progress: ${existingCount}/${totalCount} outputs\n` +
        `Missing: ${missing.join(', ')}`,
    });
    return;
  }

  // All outputs exist! Run quality gates
  const gates = queue.quality_gates || [];
  if (gates.length > 0) {
    const gateResult = runGates(gates, projectDir);

    if (!gateResult.passed) {
      output({
        result: 'continue',
        message:
          `⚠️ All outputs created but gate '${gateResult.failed}' failed:\n\n` +
          `${gateResult.error}\n\n` +
          `Fix errors before task can be marked done.`,
      });
      return;
    }
  }

  // All gates passed! Update task status
  const updated = updateTaskStatus(currentTask.id, projectDir);

  if (!updated) {
    output({
      result: 'continue',
      message: `⚠️ Task verified but failed to update task-queue.yaml`,
    });
    return;
  }

  // Calculate duration if started_at exists
  let duration = 0;
  if (currentTask.started_at) {
    const startTime = new Date(currentTask.started_at).getTime();
    duration = Math.round((Date.now() - startTime) / 60000);
  }

  // Success message
  const outputsList = outputResults.map((r) => `  ✓ ${r.pattern}`).join('\n');
  const gatesList =
    gates.length > 0
      ? gates
          .filter((g) => g.required)
          .map((g) => `  ✓ ${g.name}`)
          .join('\n')
      : '  (no gates configured)';

  output({
    result: 'continue',
    message:
      `✅ ${currentTask.id} VERIFIED & DONE!\n\n` +
      `Outputs verified:\n${outputsList}\n\n` +
      `Gates passed:\n${gatesList}\n\n` +
      `Status updated in task-queue.yaml\n` +
      (duration > 0 ? `Duration: ${duration} minutes\n` : '') +
      `Ready for next task!`,
  });
}

main().catch((error) => {
  output({ result: 'continue', message: `Hook error: ${error.message}` });
});
