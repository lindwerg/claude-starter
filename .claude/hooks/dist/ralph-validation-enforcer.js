// src/ralph-validation-enforcer.ts
import * as fs from "fs/promises";

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

// src/ralph-validation-enforcer.ts
async function main() {
  const input = JSON.parse(await readStdin());
  try {
    const markerExists = await fileExists(".bmad/sprint-validation-pending");
    if (!markerExists) {
      return output({ result: "continue" });
    }
    return output({
      result: "block",
      message: `
\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501
\u26A0\uFE0F  SPRINT VALIDATION REQUIRED
\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501

Sprint completed but not validated yet.

\u{1F4CB} REQUIRED ACTION:
   Run /validate-sprint to:
   1. Test the application manually
   2. Generate task-queue.yaml for next sprint
   3. Unlock Ralph Loop

\u26D4 Ralph Loop is BLOCKED until validation completes
\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501
`
    });
  } catch (error) {
    console.error("\u274C Validation enforcer error:", error);
    return output({ result: "continue" });
  }
}
async function fileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}
main();
