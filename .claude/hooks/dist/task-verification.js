// src/task-verification.ts
import { execSync } from "child_process";
import * as fs from "fs";
import * as path from "path";

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

// src/task-verification.ts
function parseYaml(filePath) {
  try {
    const jsonOutput = execSync(`yq -o json '.' "${filePath}"`, {
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"]
    });
    return JSON.parse(jsonOutput);
  } catch {
    return null;
  }
}
function checkOutput(outputPattern, projectDir) {
  const fullPath = path.join(projectDir, outputPattern);
  if (outputPattern.includes("*")) {
    try {
      const dir = path.dirname(fullPath);
      const pattern = path.basename(outputPattern);
      const regex = new RegExp("^" + pattern.replace(/\*/g, ".*") + "$");
      if (fs.existsSync(dir)) {
        const files = fs.readdirSync(dir).filter((f) => regex.test(f));
        return { exists: files.length > 0, files: files.map((f) => path.join(dir, f)) };
      }
    } catch {
      return { exists: false, files: [] };
    }
  }
  const exists = fs.existsSync(fullPath);
  return { exists, files: exists ? [fullPath] : [] };
}
function runGates(gates, projectDir) {
  for (const gate of gates) {
    if (!gate.required)
      continue;
    try {
      execSync(gate.command, {
        cwd: projectDir,
        stdio: ["pipe", "pipe", "pipe"],
        timeout: 6e4
        // 60 second timeout per gate
      });
    } catch (err) {
      const error = err;
      const errorMsg = error.stderr?.toString() || error.stdout?.toString() || "Unknown error";
      return { passed: false, failed: gate.name, error: errorMsg.slice(0, 500) };
    }
  }
  return { passed: true };
}
function updateTaskStatus(taskId, projectDir) {
  const queuePath = path.join(projectDir, ".bmad/task-queue.yaml");
  const now = (/* @__PURE__ */ new Date()).toISOString();
  try {
    execSync(`yq -i '(.tasks[] | select(.id == "${taskId}") | .status) = "done"' "${queuePath}"`, {
      cwd: projectDir,
      stdio: ["pipe", "pipe", "pipe"]
    });
    execSync(`yq -i '(.tasks[] | select(.id == "${taskId}") | .completed_at) = "${now}"' "${queuePath}"`, {
      cwd: projectDir,
      stdio: ["pipe", "pipe", "pipe"]
    });
    execSync(`yq -i '.summary.completed_tasks += 1' "${queuePath}"`, {
      cwd: projectDir,
      stdio: ["pipe", "pipe", "pipe"]
    });
    execSync(`yq -i '.current_task = null' "${queuePath}"`, {
      cwd: projectDir,
      stdio: ["pipe", "pipe", "pipe"]
    });
    return true;
  } catch {
    return false;
  }
}
async function main() {
  const rawInput = await readStdin();
  let input;
  try {
    input = JSON.parse(rawInput);
  } catch {
    output({ result: "continue" });
    return;
  }
  if (!["Write", "Edit"].includes(input.tool_name)) {
    output({ result: "continue" });
    return;
  }
  const projectDir = process.env.CLAUDE_PROJECT_DIR || input.cwd || process.cwd();
  const queuePath = path.join(projectDir, ".bmad/task-queue.yaml");
  const ralphMarker = path.join(projectDir, ".bmad/ralph-in-progress");
  if (!fs.existsSync(ralphMarker)) {
    output({ result: "continue" });
    return;
  }
  if (!fs.existsSync(queuePath)) {
    output({ result: "continue" });
    return;
  }
  const queue = parseYaml(queuePath);
  if (!queue) {
    output({ result: "continue", message: "\u26A0\uFE0F Failed to parse task-queue.yaml" });
    return;
  }
  if (!queue.current_task) {
    output({ result: "continue" });
    return;
  }
  const currentTask = queue.tasks.find((t) => t.id === queue.current_task);
  if (!currentTask) {
    output({ result: "continue" });
    return;
  }
  const filePath = input.tool_input.file_path;
  if (!filePath) {
    output({ result: "continue" });
    return;
  }
  const relativePath = path.relative(projectDir, filePath);
  const outputPatterns = currentTask.outputs || [];
  const matchesOutput = outputPatterns.some((pattern) => {
    const normalizedPattern = pattern.replace(/^\.\//, "");
    const normalizedPath = relativePath.replace(/^\.\//, "");
    if (pattern.includes("*")) {
      const regex = new RegExp("^" + normalizedPattern.replace(/\*/g, ".*") + "$");
      return regex.test(normalizedPath);
    }
    return normalizedPattern === normalizedPath || pattern === filePath;
  });
  if (!matchesOutput) {
    output({ result: "continue" });
    return;
  }
  const outputResults = outputPatterns.map((pattern) => {
    const result = checkOutput(pattern, projectDir);
    return { pattern, ...result };
  });
  const existingCount = outputResults.filter((r) => r.exists).length;
  const totalCount = outputResults.length;
  if (existingCount < totalCount) {
    const missing = outputResults.filter((r) => !r.exists).map((r) => r.pattern);
    output({
      result: "continue",
      message: `\u{1F4E6} Output verified: ${relativePath}
Progress: ${existingCount}/${totalCount} outputs
Missing: ${missing.join(", ")}`
    });
    return;
  }
  const gates = queue.quality_gates || [];
  if (gates.length > 0) {
    const gateResult = runGates(gates, projectDir);
    if (!gateResult.passed) {
      output({
        result: "continue",
        message: `\u26A0\uFE0F All outputs created but gate '${gateResult.failed}' failed:

${gateResult.error}

Fix errors before task can be marked done.`
      });
      return;
    }
  }
  const updated = updateTaskStatus(currentTask.id, projectDir);
  if (!updated) {
    output({
      result: "continue",
      message: `\u26A0\uFE0F Task verified but failed to update task-queue.yaml`
    });
    return;
  }
  let duration = 0;
  if (currentTask.started_at) {
    const startTime = new Date(currentTask.started_at).getTime();
    duration = Math.round((Date.now() - startTime) / 6e4);
  }
  const outputsList = outputResults.map((r) => `  \u2713 ${r.pattern}`).join("\n");
  const gatesList = gates.length > 0 ? gates.filter((g) => g.required).map((g) => `  \u2713 ${g.name}`).join("\n") : "  (no gates configured)";
  output({
    result: "continue",
    message: `\u2705 ${currentTask.id} VERIFIED & DONE!

Outputs verified:
${outputsList}

Gates passed:
${gatesList}

Status updated in task-queue.yaml
` + (duration > 0 ? `Duration: ${duration} minutes
` : "") + `Ready for next task!`
  });
}
main().catch((error) => {
  output({ result: "continue", message: `Hook error: ${error.message}` });
});
