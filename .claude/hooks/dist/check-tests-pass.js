// src/check-tests-pass.ts
import { execSync } from "child_process";
import { existsSync } from "fs";
import { join } from "path";

// src/types.ts
async function readStdin() {
  return new Promise((resolve) => {
    let data = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => data += chunk);
    process.stdin.on("end", () => resolve(data));
  });
}
function output(result) {
  console.log(JSON.stringify(result));
}

// src/check-tests-pass.ts
var COVERAGE_THRESHOLD = 80;
function hasTestSetup(cwd) {
  const testConfigs = [
    "jest.config.js",
    "jest.config.ts",
    "vitest.config.ts",
    "vitest.config.js"
  ];
  return testConfigs.some((config) => existsSync(join(cwd, config)));
}
function hasPackageJson(cwd) {
  return existsSync(join(cwd, "package.json"));
}
function runTests(cwd) {
  try {
    const testOutput = execSync("npm test -- --coverage --passWithNoTests 2>&1", {
      cwd,
      encoding: "utf8",
      timeout: 3e5
      // 5 minute timeout
    });
    const coverage = parseCoverage(testOutput);
    return {
      passed: true,
      output: testOutput,
      coverage
    };
  } catch (error) {
    const execError = error;
    const errorOutput = execError.stdout || execError.stderr || execError.message || "Unknown test error";
    const coverage = parseCoverage(errorOutput);
    return {
      passed: false,
      output: errorOutput,
      coverage
    };
  }
}
function parseCoverage(output2) {
  const coverageMatch = output2.match(/All files\s*\|\s*([\d.]+)/);
  if (coverageMatch) {
    return parseFloat(coverageMatch[1]);
  }
  const altMatch = output2.match(/Coverage:\s*([\d.]+)%/i);
  if (altMatch) {
    return parseFloat(altMatch[1]);
  }
  return void 0;
}
function formatTestSummary(result) {
  let summary = "";
  if (result.passed) {
    summary += "Tests: PASSED\n";
  } else {
    summary += "Tests: FAILED\n";
    summary += "\nTest Output:\n";
    const maxLength = 2e3;
    if (result.output.length > maxLength) {
      summary += result.output.slice(-maxLength) + "\n...(truncated)";
    } else {
      summary += result.output;
    }
  }
  if (result.coverage !== void 0) {
    summary += `
Coverage: ${result.coverage.toFixed(2)}%`;
    if (result.coverage < COVERAGE_THRESHOLD) {
      summary += ` (below ${COVERAGE_THRESHOLD}% threshold)`;
    }
  }
  return summary;
}
async function main() {
  const rawInput = await readStdin();
  let input;
  try {
    input = JSON.parse(rawInput);
  } catch {
    output({ result: "continue", message: "Failed to parse hook input" });
    return;
  }
  const cwd = input.cwd || process.cwd();
  if (!hasPackageJson(cwd)) {
    output({ result: "continue", message: "No package.json found - skipping tests" });
    return;
  }
  if (!hasTestSetup(cwd)) {
    output({ result: "continue", message: "No test configuration found - skipping tests" });
    return;
  }
  const testResult = runTests(cwd);
  const summary = formatTestSummary(testResult);
  const shouldBlock = !testResult.passed || testResult.coverage !== void 0 && testResult.coverage < COVERAGE_THRESHOLD;
  if (shouldBlock) {
    const blockReasons = [];
    if (!testResult.passed) {
      blockReasons.push("tests failed");
    }
    if (testResult.coverage !== void 0 && testResult.coverage < COVERAGE_THRESHOLD) {
      blockReasons.push(`coverage ${testResult.coverage.toFixed(2)}% < ${COVERAGE_THRESHOLD}%`);
    }
    const result = {
      result: "block",
      message: `Cannot complete: ${blockReasons.join(", ")}

${summary}`
    };
    output(result);
    return;
  }
  output({
    result: "continue",
    message: `All checks passed.
${summary}`
  });
}
main().catch((error) => {
  output({ result: "continue", message: `Hook error: ${error.message}` });
});
