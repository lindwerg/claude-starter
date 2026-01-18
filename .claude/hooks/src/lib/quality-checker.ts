/**
 * Quality Checker - проверка quality gates
 *
 * Запускает:
 * - typecheck (tsc --noEmit)
 * - lint (eslint)
 * - tests (vitest/jest)
 * - coverage (из coverage/coverage-summary.json)
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs/promises';

const execAsync = promisify(exec);

// ============================================================================
// Types
// ============================================================================

export interface TypecheckResult {
  passed: boolean;
  errors: string[];
}

export interface LintResult {
  passed: boolean;
  warnings: number;
  errors: number;
}

export interface TestsResult {
  passed: boolean;
  total: number;
  passed_count: number;
  failed: number;
}

export interface CoverageResult {
  lines: number;
  statements: number;
  functions: number;
  branches: number;
}

export interface QualityReport {
  allPassed: boolean;
  typecheck: TypecheckResult;
  lint: LintResult;
  tests: TestsResult;
  coverage: CoverageResult;
  errors: string[]; // Все ошибки для отображения
}

// ============================================================================
// Run Quality Check
// ============================================================================

/**
 * Запустить все quality gates
 */
export async function runQualityCheck(): Promise<QualityReport> {
  console.log('\n🔍 Running quality gates...\n');

  const errors: string[] = [];

  // 1. Typecheck
  console.log('📝 Running typecheck...');
  const typecheck = await runTypecheck();
  if (!typecheck.passed) {
    errors.push(...typecheck.errors);
    console.error(`  ❌ Typecheck failed: ${typecheck.errors.length} error(s)`);
  } else {
    console.log(`  ✅ Typecheck passed`);
  }

  // 2. Lint
  console.log('\n🔧 Running lint...');
  const lint = await runLint();
  if (!lint.passed) {
    errors.push(`Lint: ${lint.errors} error(s), ${lint.warnings} warning(s)`);
    console.error(`  ❌ Lint failed: ${lint.errors} error(s)`);
  } else {
    console.log(`  ✅ Lint passed (${lint.warnings} warnings)`);
  }

  // 3. Tests
  console.log('\n🧪 Running tests...');
  const tests = await runTests();
  if (!tests.passed) {
    errors.push(`Tests: ${tests.failed}/${tests.total} failed`);
    console.error(`  ❌ Tests failed: ${tests.failed}/${tests.total}`);
  } else {
    console.log(`  ✅ Tests passed: ${tests.passed_count}/${tests.total}`);
  }

  // 4. Coverage
  console.log('\n📊 Reading coverage...');
  const coverage = await readCoverage();
  console.log(`  📈 Coverage: ${coverage.lines}% lines`);

  const allPassed = typecheck.passed && lint.passed && tests.passed;

  return {
    allPassed,
    typecheck,
    lint,
    tests,
    coverage,
    errors
  };
}

// ============================================================================
// Individual Checks
// ============================================================================

/**
 * Typecheck (tsc --noEmit)
 */
async function runTypecheck(): Promise<TypecheckResult> {
  try {
    await execAsync('pnpm typecheck', { timeout: 60000 });
    return { passed: true, errors: [] };
  } catch (error) {
    const stderr = (error as any).stderr || '';
    const errors = parseTypescriptErrors(stderr);
    return { passed: false, errors };
  }
}

/**
 * Lint (eslint)
 */
async function runLint(): Promise<LintResult> {
  try {
    const { stdout } = await execAsync('pnpm lint', { timeout: 60000 });
    // Если вернуло 0, значит passed
    return { passed: true, warnings: 0, errors: 0 };
  } catch (error) {
    // Парсим вывод ESLint
    const stdout = (error as any).stdout || '';
    const parsed = parseEslintOutput(stdout);
    return {
      passed: parsed.errors === 0,
      warnings: parsed.warnings,
      errors: parsed.errors
    };
  }
}

/**
 * Tests (vitest/jest)
 */
async function runTests(): Promise<TestsResult> {
  try {
    const { stdout } = await execAsync('pnpm test -- --reporter=json', {
      timeout: 300000 // 5 min
    });

    // Парсим JSON отчёт
    const report = JSON.parse(stdout);

    return {
      passed: report.numFailedTests === 0,
      total: report.numTotalTests || 0,
      passed_count: report.numPassedTests || 0,
      failed: report.numFailedTests || 0
    };
  } catch (error) {
    // Fallback: попробовать без --reporter=json
    try {
      await execAsync('pnpm test', { timeout: 300000 });
      return { passed: true, total: 0, passed_count: 0, failed: 0 };
    } catch (fallbackError) {
      return { passed: false, total: 0, passed_count: 0, failed: 1 };
    }
  }
}

/**
 * Coverage (из coverage/coverage-summary.json)
 */
async function readCoverage(): Promise<CoverageResult> {
  try {
    const content = await fs.readFile('coverage/coverage-summary.json', 'utf-8');
    const summary = JSON.parse(content);

    const total = summary.total || {};

    return {
      lines: total.lines?.pct || 0,
      statements: total.statements?.pct || 0,
      functions: total.functions?.pct || 0,
      branches: total.branches?.pct || 0
    };
  } catch (error) {
    // Coverage не найден
    return { lines: 0, statements: 0, functions: 0, branches: 0 };
  }
}

// ============================================================================
// Parsers
// ============================================================================

/**
 * Парсинг TypeScript ошибок
 */
function parseTypescriptErrors(stderr: string): string[] {
  const lines = stderr.split('\n').filter(line => line.includes('error TS'));
  return lines.slice(0, 10); // Первые 10 ошибок
}

/**
 * Парсинг ESLint вывода
 */
function parseEslintOutput(stdout: string): { warnings: number; errors: number } {
  const warningsMatch = stdout.match(/(\d+) warnings?/);
  const errorsMatch = stdout.match(/(\d+) errors?/);

  return {
    warnings: warningsMatch ? parseInt(warningsMatch[1], 10) : 0,
    errors: errorsMatch ? parseInt(errorsMatch[1], 10) : 0
  };
}
