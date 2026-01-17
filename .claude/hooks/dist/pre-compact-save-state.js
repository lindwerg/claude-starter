// src/pre-compact-save-state.ts
import { readdirSync, readFileSync, writeFileSync, existsSync, mkdirSync, statSync } from "fs";
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

// src/pre-compact-save-state.ts
var LEDGER_DIR = "thoughts/ledgers";
var LEDGER_PREFIX = "CONTINUITY_CLAUDE-";
function findLedgers(cwd) {
  const ledgerPath = join(cwd, LEDGER_DIR);
  try {
    const files = readdirSync(ledgerPath);
    const ledgers = [];
    for (const file of files) {
      if (file.startsWith(LEDGER_PREFIX) && file.endsWith(".md")) {
        const fullPath = join(ledgerPath, file);
        const stats = statSync(fullPath);
        const content = readFileSync(fullPath, "utf8");
        ledgers.push({
          path: fullPath,
          name: file.replace(LEDGER_PREFIX, "").replace(".md", ""),
          mtime: stats.mtime,
          content
        });
      }
    }
    return ledgers.sort((a, b) => b.mtime.getTime() - a.mtime.getTime());
  } catch {
    return [];
  }
}
function updateTimestamp(content) {
  const now = (/* @__PURE__ */ new Date()).toISOString();
  const timestampLine = `_Last updated: ${now}_`;
  if (content.includes("_Last updated:")) {
    return content.replace(/_Last updated:.*_/, timestampLine);
  }
  const lines = content.split("\n");
  const titleIndex = lines.findIndex((line) => line.startsWith("# "));
  if (titleIndex !== -1) {
    lines.splice(titleIndex + 1, 0, "", timestampLine);
  } else {
    lines.unshift(timestampLine, "");
  }
  return lines.join("\n");
}
function markUnconfirmedItems(content) {
  let markedCount = 0;
  const updatedContent = content.replace(
    /## Open Questions\s*\n([\s\S]*?)(?=\n## |\n---|\$)/,
    (match, questionsContent) => {
      const lines = questionsContent.split("\n");
      const updatedLines = lines.map((line) => {
        if (line.trim().startsWith("- ") && !line.includes("UNCONFIRMED:")) {
          markedCount++;
          return line.replace(/^(\s*- )/, "$1UNCONFIRMED: ");
        }
        return line;
      });
      return `## Open Questions
${updatedLines.join("\n")}`;
    }
  );
  return { content: updatedContent, markedCount };
}
function addCompactionNote(content, contextTokens, maxTokens) {
  const now = (/* @__PURE__ */ new Date()).toISOString();
  let note = `
---
_Context compacted at ${now}`;
  if (contextTokens && maxTokens) {
    const percentage = (contextTokens / maxTokens * 100).toFixed(1);
    note += ` (${percentage}% context usage)`;
  }
  note += "_\n";
  if (content.includes("## Working Set")) {
    return content.replace(/## Working Set/, `${note}
## Working Set`);
  }
  return content + note;
}
function ensureLedgerDir(cwd) {
  const ledgerPath = join(cwd, LEDGER_DIR);
  if (!existsSync(ledgerPath)) {
    mkdirSync(ledgerPath, { recursive: true });
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
  const cwd = input.cwd || process.cwd();
  const ledgers = findLedgers(cwd);
  if (ledgers.length === 0) {
    output({
      result: "continue",
      message: "No continuity ledger found - state not saved before compaction"
    });
    return;
  }
  const activeLedger = ledgers[0];
  let updatedContent = activeLedger.content;
  updatedContent = updateTimestamp(updatedContent);
  const { content: markedContent, markedCount } = markUnconfirmedItems(updatedContent);
  updatedContent = markedContent;
  updatedContent = addCompactionNote(
    updatedContent,
    input.context_tokens,
    input.max_tokens
  );
  try {
    ensureLedgerDir(cwd);
    writeFileSync(activeLedger.path, updatedContent, "utf8");
    let message = `Ledger saved: ${activeLedger.name}`;
    if (markedCount > 0) {
      message += ` (marked ${markedCount} items as UNCONFIRMED)`;
    }
    output({
      result: "continue",
      message
    });
  } catch (error) {
    const writeError = error;
    output({
      result: "continue",
      message: `Failed to save ledger: ${writeError.message || "unknown error"}`
    });
  }
}
main().catch((error) => {
  output({ result: "continue", message: `Hook error: ${error.message}` });
});
