/**
 * Ralph Validation Cleanup Hook (PostToolUse Write)
 *
 * Срабатывает после записи файлов через Write tool.
 * Если записан task-queue.yaml и существует маркер валидации — удаляет маркер.
 * Это разблокирует Ralph Loop после успешного /validate-sprint.
 */

import * as fs from 'fs/promises';
import type { PostToolUseInput, HookOutput } from './types';
import { readStdin, output } from './types';

// ============================================================================
// Main Handler
// ============================================================================

async function main() {
  const input: PostToolUseInput = JSON.parse(await readStdin());

  try {
    // 1. Проверить, что записан task-queue.yaml
    const filePath = (input.tool_input.file_path as string) || '';
    const isTaskQueue = filePath.endsWith('task-queue.yaml');

    if (!isTaskQueue) {
      // Не task-queue.yaml → continue
      return output({ result: 'continue' });
    }

    // 2. Проверить, существует ли маркер валидации
    const markerExists = await fileExists('.bmad/sprint-validation-pending');

    if (!markerExists) {
      // Маркер отсутствует → continue (нечего удалять)
      return output({ result: 'continue' });
    }

    // 3. task-queue.yaml записан + маркер существует → удалить маркер
    await fs.unlink('.bmad/sprint-validation-pending');

    return output({
      result: 'continue',
      message: `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ SPRINT VALIDATION COMPLETED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

task-queue.yaml generated successfully.
Validation marker removed.

🚀 Ralph Loop is now UNLOCKED and ready to continue.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`
    });

  } catch (error) {
    console.error('❌ Validation cleanup error:', error);
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
