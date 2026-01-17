/**
 * Auto Format Hook
 *
 * Runs Prettier on created files to ensure consistent formatting.
 * Never blocks - formatting is non-critical.
 *
 * Event: PostToolUse (Write)
 */

import { execSync } from 'child_process';
import { existsSync } from 'fs';
import { PostToolUseInput, readStdin, output } from './types';

const FORMATTABLE_EXTENSIONS = [
  '.ts', '.tsx', '.js', '.jsx',
  '.json', '.md', '.yaml', '.yml',
  '.css', '.scss', '.html',
];

function isFormattable(filePath: string): boolean {
  return FORMATTABLE_EXTENSIONS.some(ext => filePath.endsWith(ext));
}

function getFilePath(input: PostToolUseInput): string | null {
  const toolInput = input.tool_input;
  return (toolInput.file_path as string) || (toolInput.path as string) || null;
}

function runPrettier(filePath: string, cwd: string): { success: boolean; message: string } {
  try {
    // Check if prettier is available
    execSync('which prettier || npx prettier --version', {
      cwd,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    // Run prettier --write
    execSync(`npx prettier --write "${filePath}"`, {
      cwd,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    return { success: true, message: `Formatted: ${filePath}` };
  } catch (error) {
    const execError = error as { message?: string };
    return {
      success: false,
      message: `Prettier not available or failed: ${execError.message || 'unknown error'}`
    };
  }
}

async function main(): Promise<void> {
  const rawInput = await readStdin();

  let input: PostToolUseInput;
  try {
    input = JSON.parse(rawInput);
  } catch {
    output({ result: 'continue', message: 'Failed to parse hook input' });
    return;
  }

  // Only process Write tool
  if (input.tool_name !== 'Write') {
    output({ result: 'continue' });
    return;
  }

  const filePath = getFilePath(input);
  if (!filePath) {
    output({ result: 'continue' });
    return;
  }

  // Check if file exists and is formattable
  if (!existsSync(filePath)) {
    output({ result: 'continue' });
    return;
  }

  if (!isFormattable(filePath)) {
    output({ result: 'continue' });
    return;
  }

  const cwd = input.cwd || process.cwd();
  const { success, message } = runPrettier(filePath, cwd);

  // Always continue - formatting is non-blocking
  output({
    result: 'continue',
    message: success ? message : `Skipped formatting: ${message}`,
  });
}

main().catch((error) => {
  output({ result: 'continue', message: `Hook error: ${error.message}` });
});
