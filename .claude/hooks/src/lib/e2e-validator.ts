/**
 * E2E Validator - E2E validation через Playwright
 *
 * NOTE: В будущем можно добавить MCP Playwright интеграцию через Python script.
 * Сейчас используем прямой вызов Playwright CLI для простоты.
 */

import * as fs from 'fs/promises';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

// ============================================================================
// Types
// ============================================================================

export interface E2EStep {
  action: 'navigate' | 'fill' | 'click' | 'waitForNavigation' | 'expect' | 'screenshot';
  selector?: string;
  value?: string;
  url?: string;
  state?: 'visible' | 'hidden' | 'enabled' | 'disabled';
  timeout?: number;
  description?: string;
}

export interface E2EScenario {
  id: string;
  name: string;
  description?: string;
  story_id: string;
  steps: E2EStep[];
}

export interface E2EScenarioResult {
  scenario_id: string;
  scenario_name: string;
  status: 'passed' | 'failed' | 'skipped';
  duration_ms: number;
  error?: string;
  screenshots: string[];
}

export interface E2EReport {
  total: number;
  passed: number;
  failed: number;
  skipped: number;
  scenarios: E2EScenarioResult[];
  duration_ms: number;
}

export interface E2EScenariosFile {
  version: string;
  scenarios: E2EScenario[];
}

// ============================================================================
// Load E2E Scenarios
// ============================================================================

/**
 * Загрузить E2E сценарии из .bmad/e2e-scenarios.yaml
 */
export async function loadE2EScenarios(): Promise<E2EScenario[]> {
  const scenariosPath = '.bmad/e2e-scenarios.yaml';

  try {
    const content = await fs.readFile(scenariosPath, 'utf-8');

    // TODO: Use YAML parser when available
    // For now, expect JSON format or create Python script to convert YAML -> JSON
    const parsed = JSON.parse(content) as E2EScenariosFile;

    console.log(`✅ Loaded ${parsed.scenarios.length} E2E scenarios from ${scenariosPath}`);
    return parsed.scenarios;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
      console.log(`📋 No E2E scenarios found (${scenariosPath} not found)`);
      return [];
    }

    throw error;
  }
}

// ============================================================================
// Generate Playwright Test from Scenario
// ============================================================================

/**
 * Генерировать Playwright тест из декларативного сценария
 */
function generatePlaywrightTest(scenario: E2EScenario): string {
  const steps = scenario.steps.map(step => {
    switch (step.action) {
      case 'navigate':
        return `  await page.goto('${step.url}');`;

      case 'fill':
        return `  await page.fill('${step.selector}', '${step.value}');`;

      case 'click':
        return `  await page.click('${step.selector}');`;

      case 'waitForNavigation':
        return `  await page.waitForURL('${step.url}', { timeout: ${step.timeout || 5000} });`;

      case 'expect':
        const stateCheck = step.state === 'visible'
          ? `await expect(page.locator('${step.selector}')).toBeVisible({ timeout: ${step.timeout || 5000} });`
          : `await expect(page.locator('${step.selector}')).toBeHidden({ timeout: ${step.timeout || 5000} });`;
        return `  ${stateCheck}`;

      case 'screenshot':
        return `  await page.screenshot({ path: '${step.value}' });`;

      default:
        return `  // Unknown action: ${step.action}`;
    }
  }).join('\n');

  return `
import { test, expect } from '@playwright/test';

test('${scenario.name}', async ({ page }) => {
${steps}
});
`;
}

// ============================================================================
// Run E2E Validation
// ============================================================================

/**
 * Запустить E2E валидацию
 *
 * NOTE: Сейчас генерируем временные Playwright тесты и запускаем через CLI.
 * В будущем можно использовать MCP Playwright для более детального контроля.
 */
export async function runE2EValidation(scenarios: E2EScenario[]): Promise<E2EReport> {
  if (scenarios.length === 0) {
    return {
      total: 0,
      passed: 0,
      failed: 0,
      skipped: 0,
      scenarios: [],
      duration_ms: 0
    };
  }

  console.log(`\n🧪 Running ${scenarios.length} E2E scenarios...\n`);

  const startTime = Date.now();
  const results: E2EScenarioResult[] = [];

  // Временная директория для тестов
  const tempDir = '.bmad/e2e-temp';
  await fs.mkdir(tempDir, { recursive: true });

  try {
    // Генерируем Playwright тесты
    for (const scenario of scenarios) {
      const testCode = generatePlaywrightTest(scenario);
      const testFile = `${tempDir}/${scenario.id}.spec.ts`;
      await fs.writeFile(testFile, testCode);
    }

    // Запускаем Playwright
    console.log('🎭 Running Playwright tests...');

    try {
      const { stdout, stderr } = await execAsync(
        `npx playwright test ${tempDir} --reporter=json`,
        { timeout: 300000 } // 5 min timeout
      );

      // Парсим JSON отчёт Playwright
      const report = JSON.parse(stdout);

      for (const scenario of scenarios) {
        // Найти результат для этого сценария
        const testResult = report.suites?.find((suite: any) =>
          suite.specs?.some((spec: any) => spec.title === scenario.name)
        );

        if (testResult) {
          results.push({
            scenario_id: scenario.id,
            scenario_name: scenario.name,
            status: testResult.specs[0].ok ? 'passed' : 'failed',
            duration_ms: testResult.specs[0].tests[0].results[0].duration,
            error: testResult.specs[0].ok ? undefined : testResult.specs[0].tests[0].results[0].error?.message,
            screenshots: []
          });
        }
      }

      console.log(`✅ E2E tests completed`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);

      // Все тесты упали
      for (const scenario of scenarios) {
        results.push({
          scenario_id: scenario.id,
          scenario_name: scenario.name,
          status: 'failed',
          duration_ms: 0,
          error: message,
          screenshots: []
        });
      }
    }
  } finally {
    // Cleanup temp directory
    await fs.rm(tempDir, { recursive: true, force: true });
  }

  const duration = Date.now() - startTime;
  const passed = results.filter(r => r.status === 'passed').length;
  const failed = results.filter(r => r.status === 'failed').length;

  return {
    total: scenarios.length,
    passed,
    failed,
    skipped: 0,
    scenarios: results,
    duration_ms: duration
  };
}

// ============================================================================
// Save E2E Failures
// ============================================================================

/**
 * Сохранить E2E failures в .bmad/e2e-failures/sprint-N/
 */
export async function saveE2EFailures(sprint: number, report: E2EReport | Error): Promise<void> {
  const failuresDir = `.bmad/e2e-failures/sprint-${sprint}-attempt-${Date.now()}`;
  await fs.mkdir(failuresDir, { recursive: true });

  if (report instanceof Error) {
    // Сохранить error
    await fs.writeFile(
      `${failuresDir}/error.txt`,
      report.stack || report.message
    );
  } else {
    // Сохранить E2E отчёт
    await fs.writeFile(
      `${failuresDir}/e2e-report.json`,
      JSON.stringify(report, null, 2)
    );

    // Копировать скриншоты если есть
    for (const scenario of report.scenarios) {
      if (scenario.screenshots.length > 0) {
        const screenshotsDir = `${failuresDir}/screenshots`;
        await fs.mkdir(screenshotsDir, { recursive: true });

        for (const screenshot of scenario.screenshots) {
          const basename = screenshot.split('/').pop();
          await fs.copyFile(screenshot, `${screenshotsDir}/${basename}`);
        }
      }
    }
  }

  console.log(`💾 E2E failures saved to ${failuresDir}/`);
}
