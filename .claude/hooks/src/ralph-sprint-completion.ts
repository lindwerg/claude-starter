/**
 * Ralph Sprint Completion Hook (Stop)
 *
 * Срабатывает при завершении Ralph Loop.
 * Проверяет, все ли задачи спринта выполнены.
 * Если да — архивирует спринт, создаёт маркер валидации, блокирует.
 */

import * as fs from 'fs/promises';
import * as path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';
import YAML from 'yaml';
import type { StopInput, HookOutput } from './types';
import { readStdin, output } from './types';
import type { TaskQueue } from './lib/task-queue-types';
import { generateSprintReview } from './lib/sprint-review-generator';
import { runQualityCheck } from './lib/quality-checker';
import { getCommitsFromTasks } from './lib/task-queue-types';

const execAsync = promisify(exec);

// ============================================================================
// Main Handler
// ============================================================================

async function main() {
  const input: StopInput = JSON.parse(await readStdin());

  try {
    // 1. Проверить существование task-queue.yaml
    const taskQueuePath = '.bmad/task-queue.yaml';
    const exists = await fileExists(taskQueuePath);

    if (!exists) {
      // Нет task-queue → Ralph не запущен → continue
      return output({ result: 'continue' });
    }

    // 2. Прочитать task-queue.yaml
    const content = await fs.readFile(taskQueuePath, 'utf-8');
    const queue: TaskQueue = YAML.parse(content);

    // 3. Проверить, все ли задачи done
    const allDone = queue.tasks.every(task => task.status === 'done');

    if (!allDone) {
      // Не все задачи done → continue (ralph-continue.sh продолжит loop)
      return output({ result: 'continue' });
    }

    // 4. ВСЕ ЗАДАЧИ DONE → Sprint завершён
    console.error('\n🎉 Sprint completed! Processing...\n');

    // 5. Генерировать Sprint Review
    const sprintReview = await generateSprintReview(queue);

    // 6. Запустить Quality Check
    const qualityReport = await runQualityCheck();

    // 7. Архивировать спринт
    await archiveSprint(queue, sprintReview, qualityReport);

    // 8. Создать маркер валидации
    await fs.writeFile('.bmad/sprint-validation-pending', new Date().toISOString(), 'utf-8');

    // 9. Открыть браузер для manual validation
    await openBrowser();

    // 10. Блокировать Stop с сообщением
    return output({
      result: 'block',
      message: `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏁 SPRINT ${queue.sprint} COMPLETED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ All tasks completed
📦 Archived to: .bmad/history/sprint-${queue.sprint}/
🔍 Quality gates: ${qualityReport.allPassed ? 'PASSED' : 'FAILED'}
🌐 Browser opened for manual validation

📋 NEXT STEP: Run /validate-sprint to:
   1. Test the application manually
   2. Generate task-queue.yaml for Sprint ${queue.sprint + 1}
   3. Continue Ralph Loop automatically

⚠️  Ralph Loop is BLOCKED until validation completes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`
    });

  } catch (error) {
    console.error('❌ Sprint completion error:', error);
    return output({ result: 'continue' }); // Fallback to continue on errors
  }
}

// ============================================================================
// Archive Sprint
// ============================================================================

async function archiveSprint(
  queue: TaskQueue,
  sprintReview: string,
  qualityReport: any
): Promise<void> {
  const sprintDir = `.bmad/history/sprint-${queue.sprint}`;

  // Создать директорию
  await fs.mkdir(sprintDir, { recursive: true });

  // 1. Копировать task-queue.yaml
  await fs.copyFile('.bmad/task-queue.yaml', path.join(sprintDir, 'task-queue.yaml'));

  // 2. Сохранить sprint-review.md
  await fs.writeFile(path.join(sprintDir, 'sprint-review.md'), sprintReview, 'utf-8');

  // 3. Сохранить quality-report.json
  await fs.writeFile(
    path.join(sprintDir, 'quality-report.json'),
    JSON.stringify(qualityReport, null, 2),
    'utf-8'
  );

  // 4. Сохранить commits.log
  const commits = getCommitsFromTasks(queue.tasks);
  await fs.writeFile(path.join(sprintDir, 'commits.log'), commits.join('\n'), 'utf-8');

  console.error(`✅ Sprint archived to: ${sprintDir}`);
}

// ============================================================================
// Open Browser (platform-specific)
// ============================================================================

async function openBrowser(): Promise<void> {
  const url = 'http://localhost:3000';

  try {
    let command: string;

    switch (process.platform) {
      case 'darwin': // macOS
        command = `open ${url}`;
        break;
      case 'linux':
        command = `xdg-open ${url}`;
        break;
      case 'win32': // Windows
        command = `start ${url}`;
        break;
      default:
        console.error(`⚠️  Platform not supported for browser opening: ${process.platform}`);
        console.error(`   Please open manually: ${url}`);
        return;
    }

    await execAsync(command);
    console.error(`✅ Browser opened: ${url}`);
  } catch (error) {
    console.error(`⚠️  Failed to open browser: ${(error as Error).message}`);
    console.error(`   Please open manually: ${url}`);
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
