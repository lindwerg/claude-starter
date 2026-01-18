/**
 * Ralph Validation Enforcer Hook (PreToolUse Task)
 *
 * Срабатывает перед spawn subagent (Task tool).
 * Блокирует запуск Ralph если существует маркер .bmad/sprint-validation-pending.
 * Enforcement: физически невозможно продолжить без /validate-sprint.
 */

import * as fs from 'fs/promises';
import type { PreToolUseInput, HookOutput } from './types';
import { readStdin, output } from './types';

// ============================================================================
// Main Handler
// ============================================================================

async function main() {
  const input: PreToolUseInput = JSON.parse(await readStdin());

  try {
    // Проверяем, существует ли маркер валидации
    const markerExists = await fileExists('.bmad/sprint-validation-pending');

    if (!markerExists) {
      // Маркер отсутствует → всё ОК, continue
      return output({ result: 'continue' });
    }

    // Маркер существует → БЛОКИРОВКА
    return output({
      result: 'block',
      message: `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  SPRINT VALIDATION REQUIRED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Sprint completed but not validated yet.

📋 REQUIRED ACTION:
   Run /validate-sprint to:
   1. Test the application manually
   2. Generate task-queue.yaml for next sprint
   3. Unlock Ralph Loop

⛔ Ralph Loop is BLOCKED until validation completes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`
    });

  } catch (error) {
    console.error('❌ Validation enforcer error:', error);
    return output({ result: 'continue' }); // Fallback to continue on errors
  }
}

// ============================================================================
// Helpers
// ============================================================================

async function fileExists(filePath: string): Promise<boolean> {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

// ============================================================================
// Run
// ============================================================================

main();
