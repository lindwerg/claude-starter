/**
 * TypeScript Preflight Hook
 *
 * Validates TypeScript files after Edit/Write operations.
 * Runs tsc --noEmit to check for compilation errors.
 *
 * Event: PostToolUse (Edit|Write)
 */

import { execSync } from 'child_process';
import { PostToolUseInput, HookOutput, readStdin, output } from './types';

function isTypeScriptFile(filePath: string): boolean {
  return /\.(ts|tsx)$/.test(filePath);
}

function getFilePath(input: PostToolUseInput): string | null {
  const toolInput = input.tool_input;
  return (toolInput.file_path as string) || (toolInput.path as string) || null;
}

function runTypeScriptCheck(filePath: string, cwd: string): { success: boolean; errors: string } {
  try {
    // Try to find tsconfig.json in project
    execSync(`tsc --noEmit --skipLibCheck "${filePath}"`, {
      cwd,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    return { success: true, errors: '' };
  } catch (error) {
    const execError = error as { stderr?: string; stdout?: string };
    const errorOutput = execError.stderr || execError.stdout || 'Unknown TypeScript error';
    return { success: false, errors: errorOutput };
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

  // Only process Edit and Write tools
  if (!['Edit', 'Write'].includes(input.tool_name)) {
    output({ result: 'continue' });
    return;
  }

  const filePath = getFilePath(input);
  if (!filePath) {
    output({ result: 'continue' });
    return;
  }

  // Only check TypeScript files
  if (!isTypeScriptFile(filePath)) {
    output({ result: 'continue' });
    return;
  }

  const cwd = input.cwd || process.cwd();
  const { success, errors } = runTypeScriptCheck(filePath, cwd);

  if (!success) {
    const result: HookOutput = {
      result: 'block',
      message: `TypeScript errors in ${filePath}:\n\n${errors}\n\nFix the errors before continuing.`,
    };
    output(result);
    return;
  }

  output({
    result: 'continue',
    message: `TypeScript check passed for ${filePath}`,
  });
}

main().catch((error) => {
  output({ result: 'continue', message: `Hook error: ${error.message}` });
});
