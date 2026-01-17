/**
 * Session Start Continuity Hook
 *
 * Loads continuity ledger on session start/resume/compact.
 * Injects current state into system reminder.
 *
 * Event: SessionStart (resume|compact|clear|start)
 */

import { readdirSync, readFileSync, statSync } from 'fs';
import { join, basename } from 'path';
import { SessionStartInput, HookOutput, readStdin, output } from './types';

const LEDGER_DIR = 'thoughts/ledgers';
const LEDGER_PREFIX = 'CONTINUITY_CLAUDE-';

interface LedgerInfo {
  path: string;
  name: string;
  mtime: Date;
  content: string;
}

interface StateSection {
  done: string[];
  now: string | null;
  next: string[];
  remaining: string[];
}

function findLedgers(cwd: string): LedgerInfo[] {
  const ledgerPath = join(cwd, LEDGER_DIR);

  try {
    const files = readdirSync(ledgerPath);
    const ledgers: LedgerInfo[] = [];

    for (const file of files) {
      if (file.startsWith(LEDGER_PREFIX) && file.endsWith('.md')) {
        const fullPath = join(ledgerPath, file);
        const stats = statSync(fullPath);
        const content = readFileSync(fullPath, 'utf8');

        ledgers.push({
          path: fullPath,
          name: file.replace(LEDGER_PREFIX, '').replace('.md', ''),
          mtime: stats.mtime,
          content,
        });
      }
    }

    // Sort by modification time, most recent first
    return ledgers.sort((a, b) => b.mtime.getTime() - a.mtime.getTime());
  } catch {
    return [];
  }
}

function parseStateSection(content: string): StateSection {
  const state: StateSection = {
    done: [],
    now: null,
    next: [],
    remaining: [],
  };

  // Find State section
  const stateMatch = content.match(/## State\s*\n([\s\S]*?)(?=\n## |\n---|\$)/);
  if (!stateMatch) return state;

  const stateContent = stateMatch[1];

  // Parse Done items
  const doneMatch = stateContent.match(/- Done:\s*\n((?:\s+- \[x\].*\n?)*)/);
  if (doneMatch) {
    const doneItems = doneMatch[1].match(/- \[x\] (.+)/g) || [];
    state.done = doneItems.map(item => item.replace(/- \[x\] /, ''));
  }

  // Parse Now (current phase)
  const nowMatch = stateContent.match(/- Now: \[→\] (.+)/);
  if (nowMatch) {
    state.now = nowMatch[1];
  }

  // Parse Next
  const nextMatch = stateContent.match(/- Next: (.+)/);
  if (nextMatch) {
    state.next = [nextMatch[1]];
  }

  // Parse Remaining items
  const remainingMatch = stateContent.match(/- Remaining:\s*\n((?:\s+- \[ \].*\n?)*)/);
  if (remainingMatch) {
    const remainingItems = remainingMatch[1].match(/- \[ \] (.+)/g) || [];
    state.remaining = remainingItems.map(item => item.replace(/- \[ \] /, ''));
  }

  return state;
}

function parseGoal(content: string): string | null {
  const goalMatch = content.match(/## Goal\s*\n([\s\S]*?)(?=\n## |\n---)/);
  if (goalMatch) {
    return goalMatch[1].trim().split('\n')[0];
  }
  return null;
}

function parseOpenQuestions(content: string): string[] {
  const questionsMatch = content.match(/## Open Questions\s*\n([\s\S]*?)(?=\n## |\n---|\$)/);
  if (!questionsMatch) return [];

  const questions = questionsMatch[1].match(/- UNCONFIRMED:.+/g) || [];
  return questions.map(q => q.replace(/- /, ''));
}

function formatStatusLine(ledger: LedgerInfo): string {
  const state = parseStateSection(ledger.content);
  const goal = parseGoal(ledger.content);
  const questions = parseOpenQuestions(ledger.content);

  let status = `📋 Ledger: ${ledger.name}\n`;

  if (goal) {
    status += `🎯 Goal: ${goal}\n`;
  }

  if (state.done.length > 0) {
    status += `✓ Completed: ${state.done.length} phase(s)\n`;
  }

  if (state.now) {
    status += `→ Current: ${state.now}\n`;
  }

  if (state.remaining.length > 0) {
    status += `○ Remaining: ${state.remaining.length} phase(s)\n`;
  }

  if (questions.length > 0) {
    status += `\n⚠️ UNCONFIRMED items:\n`;
    questions.forEach(q => {
      status += `  - ${q}\n`;
    });
  }

  return status;
}

function formatFullContext(ledger: LedgerInfo): string {
  const state = parseStateSection(ledger.content);
  const goal = parseGoal(ledger.content);

  let context = `\n${'='.repeat(60)}\n`;
  context += `CONTINUITY LEDGER: ${ledger.name}\n`;
  context += `${'='.repeat(60)}\n\n`;

  if (goal) {
    context += `GOAL: ${goal}\n\n`;
  }

  context += `PROGRESS:\n`;
  state.done.forEach((item, i) => {
    context += `  [x] Phase ${i + 1}: ${item}\n`;
  });

  if (state.now) {
    context += `  [→] CURRENT: ${state.now}\n`;
  }

  state.remaining.forEach((item, i) => {
    context += `  [ ] Pending ${i + 1}: ${item}\n`;
  });

  context += `\n${'='.repeat(60)}\n`;
  context += `Full ledger: ${ledger.path}\n`;
  context += `${'='.repeat(60)}\n`;

  return context;
}

async function main(): Promise<void> {
  const rawInput = await readStdin();

  let input: SessionStartInput;
  try {
    input = JSON.parse(rawInput);
  } catch {
    output({ result: 'continue', message: 'Failed to parse hook input' });
    return;
  }

  const cwd = input.cwd || process.cwd();
  const eventType = input.type || 'start';

  // Find available ledgers
  const ledgers = findLedgers(cwd);

  if (ledgers.length === 0) {
    output({
      result: 'continue',
      message: `Session ${eventType}: No continuity ledger found in ${LEDGER_DIR}/`,
    });
    return;
  }

  // Use the most recent ledger
  const activeLedger = ledgers[0];

  // Format message based on event type
  let message: string;

  switch (eventType) {
    case 'resume':
      message = `🔄 Resuming session with continuity ledger.\n\n${formatStatusLine(activeLedger)}${formatFullContext(activeLedger)}`;
      break;
    case 'compact':
      message = `📦 Context compacted. Ledger state preserved.\n\n${formatStatusLine(activeLedger)}`;
      break;
    case 'clear':
      message = `🧹 Context cleared. Loading ledger state.\n\n${formatStatusLine(activeLedger)}${formatFullContext(activeLedger)}`;
      break;
    default:
      message = `🚀 Session started. Found continuity ledger.\n\n${formatStatusLine(activeLedger)}`;
  }

  output({
    result: 'continue',
    message,
  });
}

main().catch((error) => {
  output({ result: 'continue', message: `Hook error: ${error.message}` });
});
