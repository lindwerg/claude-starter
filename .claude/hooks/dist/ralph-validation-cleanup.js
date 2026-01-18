// src/ralph-validation-cleanup.ts
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

// src/ralph-validation-cleanup.ts
async function main() {
  const input = JSON.parse(await readStdin());
  try {
    const filePath = input.tool_input.file_path || "";
    const isTaskQueue = filePath.endsWith("task-queue.yaml");
    if (!isTaskQueue) {
      return output({ result: "continue" });
    }
    const markerExists = await fileExists(".bmad/sprint-validation-pending");
    if (!markerExists) {
      return output({ result: "continue" });
    }
    await fs.unlink(".bmad/sprint-validation-pending");
    return output({
      result: "continue",
      message: `
\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501
\u2705 SPRINT VALIDATION COMPLETED
\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501

task-queue.yaml generated successfully.
Validation marker removed.

\u{1F680} Ralph Loop is now UNLOCKED and ready to continue.
\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501
`
    });
  } catch (error) {
    console.error("\u274C Validation cleanup error:", error);
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
