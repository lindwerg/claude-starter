// src/typescript-preflight.ts
import { execSync } from "child_process";

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

// src/typescript-preflight.ts
function isTypeScriptFile(filePath) {
  return /\.(ts|tsx)$/.test(filePath);
}
function getFilePath(input) {
  const toolInput = input.tool_input;
  return toolInput.file_path || toolInput.path || null;
}
function runTypeScriptCheck(filePath, cwd) {
  try {
    execSync(`tsc --noEmit --skipLibCheck "${filePath}"`, {
      cwd,
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"]
    });
    return { success: true, errors: "" };
  } catch (error) {
    const execError = error;
    const errorOutput = execError.stderr || execError.stdout || "Unknown TypeScript error";
    return { success: false, errors: errorOutput };
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
  if (!["Edit", "Write"].includes(input.tool_name)) {
    output({ result: "continue" });
    return;
  }
  const filePath = getFilePath(input);
  if (!filePath) {
    output({ result: "continue" });
    return;
  }
  if (!isTypeScriptFile(filePath)) {
    output({ result: "continue" });
    return;
  }
  const cwd = input.cwd || process.cwd();
  const { success, errors } = runTypeScriptCheck(filePath, cwd);
  if (!success) {
    const result = {
      result: "block",
      message: `TypeScript errors in ${filePath}:

${errors}

Fix the errors before continuing.`
    };
    output(result);
    return;
  }
  output({
    result: "continue",
    message: `TypeScript check passed for ${filePath}`
  });
}
main().catch((error) => {
  output({ result: "continue", message: `Hook error: ${error.message}` });
});
