/**
 * Check Tests Pass Hook
 *
 * Runs test suite and verifies coverage threshold before session end.
 * Blocks if tests fail or coverage is below 80%.
 *
 * Event: Stop
 */

import { execSync } from 'child_process';
import { existsSync } from 'fs';
import { join } from 'path';
import { StopInput, HookOutput, readStdin, output } from './types';

const COVERAGE_THRESHOLD = 80;

interface TestResult {
  passed: boolean;
  output: string;
  coverage?: number;
}

function hasTestSetup(cwd: string): boolean {
  // Check for common test configuration files
  const testConfigs = [
    'jest.config.js',
    'jest.config.ts',
    'vitest.config.ts',
    'vitest.config.js',
  ];

  return testConfigs.some(config => existsSync(join(cwd, config)));
}

function hasPackageJson(cwd: string): boolean {
  return existsSync(join(cwd, 'package.json'));
}

function runTests(cwd: string): TestResult {
  try {
    // Run tests with coverage
    const testOutput = execSync('npm test -- --coverage --passWithNoTests 2>&1', {
      cwd,
      encoding: 'utf8',
      timeout: 300000, // 5 minute timeout
    });

    // Parse coverage from output
    const coverage = parseCoverage(testOutput);

    return {
      passed: true,
      output: testOutput,
      coverage,
    };
  } catch (error) {
    const execError = error as { stdout?: string; stderr?: string; message?: string };
    const errorOutput = execError.stdout || execError.stderr || execError.message || 'Unknown test error';

    // Try to parse coverage even from failed run
    const coverage = parseCoverage(errorOutput);

    return {
      passed: false,
      output: errorOutput,
      coverage,
    };
  }
}

function parseCoverage(output: string): number | undefined {
  // Try to find coverage percentage in Jest/Vitest output
  // Format: "All files | XX.XX | ..."
  const coverageMatch = output.match(/All files\s*\|\s*([\d.]+)/);
  if (coverageMatch) {
    return parseFloat(coverageMatch[1]);
  }

  // Alternative format: "Coverage: XX%"
  const altMatch = output.match(/Coverage:\s*([\d.]+)%/i);
  if (altMatch) {
    return parseFloat(altMatch[1]);
  }

  return undefined;
}

function formatTestSummary(result: TestResult): string {
  let summary = '';

  if (result.passed) {
    summary += 'Tests: PASSED\n';
  } else {
    summary += 'Tests: FAILED\n';
    summary += '\nTest Output:\n';
    // Truncate long output
    const maxLength = 2000;
    if (result.output.length > maxLength) {
      summary += result.output.slice(-maxLength) + '\n...(truncated)';
    } else {
      summary += result.output;
    }
  }

  if (result.coverage !== undefined) {
    summary += `\nCoverage: ${result.coverage.toFixed(2)}%`;
    if (result.coverage < COVERAGE_THRESHOLD) {
      summary += ` (below ${COVERAGE_THRESHOLD}% threshold)`;
    }
  }

  return summary;
}

async function main(): Promise<void> {
  const rawInput = await readStdin();

  let input: StopInput;
  try {
    input = JSON.parse(rawInput);
  } catch {
    output({ result: 'continue', message: 'Failed to parse hook input' });
    return;
  }

  const cwd = input.cwd || process.cwd();

  // Check if project has test setup
  if (!hasPackageJson(cwd)) {
    output({ result: 'continue', message: 'No package.json found - skipping tests' });
    return;
  }

  if (!hasTestSetup(cwd)) {
    output({ result: 'continue', message: 'No test configuration found - skipping tests' });
    return;
  }

  // Run tests
  const testResult = runTests(cwd);
  const summary = formatTestSummary(testResult);

  // Determine if we should block
  const shouldBlock =
    !testResult.passed ||
    (testResult.coverage !== undefined && testResult.coverage < COVERAGE_THRESHOLD);

  if (shouldBlock) {
    const blockReasons: string[] = [];

    if (!testResult.passed) {
      blockReasons.push('tests failed');
    }

    if (testResult.coverage !== undefined && testResult.coverage < COVERAGE_THRESHOLD) {
      blockReasons.push(`coverage ${testResult.coverage.toFixed(2)}% < ${COVERAGE_THRESHOLD}%`);
    }

    const result: HookOutput = {
      result: 'block',
      message: `Cannot complete: ${blockReasons.join(', ')}\n\n${summary}`,
    };
    output(result);
    return;
  }

  output({
    result: 'continue',
    message: `All checks passed.\n${summary}`,
  });
}

main().catch((error) => {
  output({ result: 'continue', message: `Hook error: ${error.message}` });
});
