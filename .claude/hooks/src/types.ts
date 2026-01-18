/**
 * Common types for Claude Code hooks
 */

import { z } from 'zod';

// ============================================================================
// Zod Validation Schemas
// ============================================================================

export const BaseHookInputSchema = z.object({
  session_id: z.string().optional(),
  cwd: z.string().optional(),
});

export const PreToolUseInputSchema = BaseHookInputSchema.extend({
  tool_name: z.string(),
  tool_input: z.record(z.unknown()),
});

export const PostToolUseInputSchema = BaseHookInputSchema.extend({
  tool_name: z.string(),
  tool_input: z.record(z.unknown()),
  tool_output: z.string().optional(),
});

export const SessionStartInputSchema = BaseHookInputSchema.extend({
  type: z.enum(['resume', 'compact', 'clear', 'start']),
});

export const PreCompactInputSchema = BaseHookInputSchema.extend({
  context_tokens: z.number().optional(),
  max_tokens: z.number().optional(),
});

export const StopInputSchema = BaseHookInputSchema.extend({
  reason: z.string().optional(),
});

export const HookOutputSchema = z.object({
  result: z.enum(['continue', 'block']),
  message: z.string().optional(),
});

// ============================================================================
// TypeScript Interfaces (inferred from Zod schemas)
// ============================================================================

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

// ============================================================================
// Input Validation Helpers
// ============================================================================

/**
 * Validate hook input against Zod schema with helpful error messages.
 *
 * Usage:
 *   const input = validateInput(PreToolUseInputSchema, rawInput, 'PreToolUse');
 *   if (!input) return; // Already output error and exit
 */
export function validateInput<T>(
  schema: z.ZodSchema<T>,
  rawInput: string,
  hookName: string
): T | null {
  try {
    const parsed = JSON.parse(rawInput);
    const result = schema.safeParse(parsed);

    if (!result.success) {
      const errors = result.error.errors
        .map((e) => `  - ${e.path.join('.')}: ${e.message}`)
        .join('\n');

      output({
        result: 'continue',
        message: `[${hookName}] Invalid input:\n${errors}`,
      });
      return null;
    }

    return result.data;
  } catch (error) {
    output({
      result: 'continue',
      message: `[${hookName}] Failed to parse input: ${error}`,
    });
    return null;
  }
}

// ============================================================================
// Hook Metrics & Monitoring
// ============================================================================

export interface HookMetric {
  timestamp: string;
  hook_name: string;
  event_type: 'PreToolUse' | 'PostToolUse' | 'SessionStart' | 'PreCompact' | 'Stop';
  duration_ms: number;
  result: 'continue' | 'block';
  tool_name?: string;
  file_path?: string;
  error?: string;
}

/**
 * Log hook execution metrics to JSONL file for monitoring and analysis.
 *
 * Usage:
 *   const start = Date.now();
 *   // ... hook logic ...
 *   logMetric({
 *     hook_name: 'backpressure-gate',
 *     event_type: 'PreToolUse',
 *     duration_ms: Date.now() - start,
 *     result: 'block',
 *     tool_name: input.tool_name,
 *     file_path: input.tool_input.file_path
 *   });
 */
export function logMetric(metric: HookMetric): void {
  try {
    const fs = require('fs');
    const path = require('path');

    // Create metrics directory if doesn't exist
    const metricsDir = path.join(process.cwd(), '.claude', 'hooks', 'metrics');
    if (!fs.existsSync(metricsDir)) {
      fs.mkdirSync(metricsDir, { recursive: true });
    }

    // Append to daily log file (YYYY-MM-DD.jsonl)
    const date = new Date().toISOString().split('T')[0];
    const logFile = path.join(metricsDir, `${date}.jsonl`);

    const entry = {
      ...metric,
      timestamp: new Date().toISOString(),
    };

    fs.appendFileSync(logFile, JSON.stringify(entry) + '\n', 'utf8');
  } catch (error) {
    // Fail silently - metrics should never break hooks
    console.error(`[logMetric] Failed to log metric: ${error}`);
  }
}
