// src/session-start-continuity.ts
import { readdirSync, readFileSync, statSync } from "fs";
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

// src/session-start-continuity.ts
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
function parseStateSection(content) {
  const state = {
    done: [],
    now: null,
    next: [],
    remaining: []
  };
  const stateMatch = content.match(/## State\s*\n([\s\S]*?)(?=\n## |\n---|\$)/);
  if (!stateMatch)
    return state;
  const stateContent = stateMatch[1];
  const doneMatch = stateContent.match(/- Done:\s*\n((?:\s+- \[x\].*\n?)*)/);
  if (doneMatch) {
    const doneItems = doneMatch[1].match(/- \[x\] (.+)/g) || [];
    state.done = doneItems.map((item) => item.replace(/- \[x\] /, ""));
  }
  const nowMatch = stateContent.match(/- Now: \[→\] (.+)/);
  if (nowMatch) {
    state.now = nowMatch[1];
  }
  const nextMatch = stateContent.match(/- Next: (.+)/);
  if (nextMatch) {
    state.next = [nextMatch[1]];
  }
  const remainingMatch = stateContent.match(/- Remaining:\s*\n((?:\s+- \[ \].*\n?)*)/);
  if (remainingMatch) {
    const remainingItems = remainingMatch[1].match(/- \[ \] (.+)/g) || [];
    state.remaining = remainingItems.map((item) => item.replace(/- \[ \] /, ""));
  }
  return state;
}
function parseGoal(content) {
  const goalMatch = content.match(/## Goal\s*\n([\s\S]*?)(?=\n## |\n---)/);
  if (goalMatch) {
    return goalMatch[1].trim().split("\n")[0];
  }
  return null;
}
function parseOpenQuestions(content) {
  const questionsMatch = content.match(/## Open Questions\s*\n([\s\S]*?)(?=\n## |\n---|\$)/);
  if (!questionsMatch)
    return [];
  const questions = questionsMatch[1].match(/- UNCONFIRMED:.+/g) || [];
  return questions.map((q) => q.replace(/- /, ""));
}
function formatStatusLine(ledger) {
  const state = parseStateSection(ledger.content);
  const goal = parseGoal(ledger.content);
  const questions = parseOpenQuestions(ledger.content);
  let status = `\u{1F4CB} Ledger: ${ledger.name}
`;
  if (goal) {
    status += `\u{1F3AF} Goal: ${goal}
`;
  }
  if (state.done.length > 0) {
    status += `\u2713 Completed: ${state.done.length} phase(s)
`;
  }
  if (state.now) {
    status += `\u2192 Current: ${state.now}
`;
  }
  if (state.remaining.length > 0) {
    status += `\u25CB Remaining: ${state.remaining.length} phase(s)
`;
  }
  if (questions.length > 0) {
    status += `
\u26A0\uFE0F UNCONFIRMED items:
`;
    questions.forEach((q) => {
      status += `  - ${q}
`;
    });
  }
  return status;
}
function formatFullContext(ledger) {
  const state = parseStateSection(ledger.content);
  const goal = parseGoal(ledger.content);
  let context = `
${"=".repeat(60)}
`;
  context += `CONTINUITY LEDGER: ${ledger.name}
`;
  context += `${"=".repeat(60)}

`;
  if (goal) {
    context += `GOAL: ${goal}

`;
  }
  context += `PROGRESS:
`;
  state.done.forEach((item, i) => {
    context += `  [x] Phase ${i + 1}: ${item}
`;
  });
  if (state.now) {
    context += `  [\u2192] CURRENT: ${state.now}
`;
  }
  state.remaining.forEach((item, i) => {
    context += `  [ ] Pending ${i + 1}: ${item}
`;
  });
  context += `
${"=".repeat(60)}
`;
  context += `Full ledger: ${ledger.path}
`;
  context += `${"=".repeat(60)}
`;
  return context;
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
  const eventType = input.type || "start";
  const ledgers = findLedgers(cwd);
  if (ledgers.length === 0) {
    output({
      result: "continue",
      message: `Session ${eventType}: No continuity ledger found in ${LEDGER_DIR}/`
    });
    return;
  }
  const activeLedger = ledgers[0];
  let message;
  switch (eventType) {
    case "resume":
      message = `\u{1F504} Resuming session with continuity ledger.

${formatStatusLine(activeLedger)}${formatFullContext(activeLedger)}`;
      break;
    case "compact":
      message = `\u{1F4E6} Context compacted. Ledger state preserved.

${formatStatusLine(activeLedger)}`;
      break;
    case "clear":
      message = `\u{1F9F9} Context cleared. Loading ledger state.

${formatStatusLine(activeLedger)}${formatFullContext(activeLedger)}`;
      break;
    default:
      message = `\u{1F680} Session started. Found continuity ledger.

${formatStatusLine(activeLedger)}`;
  }
  output({
    result: "continue",
    message
  });
}
main().catch((error) => {
  output({ result: "continue", message: `Hook error: ${error.message}` });
});
