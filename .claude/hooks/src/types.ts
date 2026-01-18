/**
 * Common types for Claude Code hooks
 */

// Base hook input structure
export interface BaseHookInput {
  session_id?: string;
  cwd?: string;
}

// PreToolUse hook input
export interface PreToolUseInput extends BaseHookInput {
  tool_name: string;
  tool_input: Record<string, unknown>;
}

// PostToolUse hook input
export interface PostToolUseInput extends BaseHookInput {
  tool_name: string;
  tool_input: Record<string, unknown>;
  tool_output?: string;
}

// SessionStart hook input
export interface SessionStartInput extends BaseHookInput {
  type: 'resume' | 'compact' | 'clear' | 'start';
}

// PreCompact hook input
export interface PreCompactInput extends BaseHookInput {
  context_tokens?: number;
  max_tokens?: number;
}

// Stop hook input
export interface StopInput extends BaseHookInput {
  reason?: string;
}

// Hook output structure
export interface HookOutput {
  result: 'continue' | 'block';
  message?: string;
}

// Helper to read stdin
export async function readStdin(): Promise<string> {
  return new Promise((resolve) => {
    let data = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (chunk) => (data += chunk));
    process.stdin.on('end', () => resolve(data));
  });
}

// Helper to output result
export function output(result: HookOutput): void {
  console.log(JSON.stringify(result));
}
