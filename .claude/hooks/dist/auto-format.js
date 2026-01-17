// src/auto-format.ts
import { execSync } from "child_process";
import { existsSync } from "fs";

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

// src/auto-format.ts
var FORMATTABLE_EXTENSIONS = [
  ".ts",
  ".tsx",
  ".js",
  ".jsx",
  ".json",
  ".md",
  ".yaml",
  ".yml",
  ".css",
  ".scss",
  ".html"
];
function isFormattable(filePath) {
  return FORMATTABLE_EXTENSIONS.some((ext) => filePath.endsWith(ext));
}
function getFilePath(input) {
  const toolInput = input.tool_input;
  return toolInput.file_path || toolInput.path || null;
}
function runPrettier(filePath, cwd) {
  try {
    execSync("which prettier || npx prettier --version", {
      cwd,
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"]
    });
    execSync(`npx prettier --write "${filePath}"`, {
      cwd,
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"]
    });
    return { success: true, message: `Formatted: ${filePath}` };
  } catch (error) {
    const execError = error;
    return {
      success: false,
      message: `Prettier not available or failed: ${execError.message || "unknown error"}`
    };
  }
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
  if (input.tool_name !== "Write") {
    output({ result: "continue" });
    return;
  }
  const filePath = getFilePath(input);
  if (!filePath) {
    output({ result: "continue" });
    return;
  }
  if (!existsSync(filePath)) {
    output({ result: "continue" });
    return;
  }
  if (!isFormattable(filePath)) {
    output({ result: "continue" });
    return;
  }
  const cwd = input.cwd || process.cwd();
  const { success, message } = runPrettier(filePath, cwd);
  output({
    result: "continue",
    message: success ? message : `Skipped formatting: ${message}`
  });
}
main().catch((error) => {
  output({ result: "continue", message: `Hook error: ${error.message}` });
});
