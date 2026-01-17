/**
 * Pre-Compact Save State Hook
 *
 * Saves current state to continuity ledger before context compaction.
 * Updates timestamp and marks uncertain items as UNCONFIRMED.
 *
 * Event: PreCompact
 */

import { readdirSync, readFileSync, writeFileSync, existsSync, mkdirSync, statSync } from 'fs';
import { join } from 'path';
import { PreCompactInput, HookOutput, readStdin, output } from './types';

const LEDGER_DIR = 'thoughts/ledgers';
const LEDGER_PREFIX = 'CONTINUITY_CLAUDE-';

interface LedgerInfo {
  path: string;
  name: string;
  mtime: Date;
  content: string;
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

    return ledgers.sort((a, b) => b.mtime.getTime() - a.mtime.getTime());
  } catch {
    return [];
  }
}

function updateTimestamp(content: string): string {
  const now = new Date().toISOString();
  const timestampLine = `_Last updated: ${now}_`;

  // Check if timestamp exists
  if (content.includes('_Last updated:')) {
    return content.replace(/_Last updated:.*_/, timestampLine);
  }

  // Add timestamp after title
  const lines = content.split('\n');
  const titleIndex = lines.findIndex(line => line.startsWith('# '));

  if (titleIndex !== -1) {
    lines.splice(titleIndex + 1, 0, '', timestampLine);
  } else {
    lines.unshift(timestampLine, '');
  }

  return lines.join('\n');
}

function markUnconfirmedItems(content: string): { content: string; markedCount: number } {
  let markedCount = 0;

  // Find Open Questions section and mark items that aren't already UNCONFIRMED
  const updatedContent = content.replace(
    /## Open Questions\s*\n([\s\S]*?)(?=\n## |\n---|\$)/,
    (match, questionsContent) => {
      const lines = questionsContent.split('\n');
      const updatedLines = lines.map((line: string) => {
        // If it's a list item that isn't already marked as UNCONFIRMED
        if (line.trim().startsWith('- ') && !line.includes('UNCONFIRMED:')) {
          markedCount++;
          return line.replace(/^(\s*- )/, '$1UNCONFIRMED: ');
        }
        return line;
      });
      return `## Open Questions\n${updatedLines.join('\n')}`;
    }
  );

  return { content: updatedContent, markedCount };
}

function addCompactionNote(content: string, contextTokens?: number, maxTokens?: number): string {
  const now = new Date().toISOString();
  let note = `\n---\n_Context compacted at ${now}`;

  if (contextTokens && maxTokens) {
    const percentage = ((contextTokens / maxTokens) * 100).toFixed(1);
    note += ` (${percentage}% context usage)`;
  }

  note += '_\n';

  // Add note before the last section or at the end
  if (content.includes('## Working Set')) {
    return content.replace(/## Working Set/, `${note}\n## Working Set`);
  }

  return content + note;
}

function ensureLedgerDir(cwd: string): void {
  const ledgerPath = join(cwd, LEDGER_DIR);
  if (!existsSync(ledgerPath)) {
    mkdirSync(ledgerPath, { recursive: true });
  }
}

async function main(): Promise<void> {
  const rawInput = await readStdin();

  let input: PreCompactInput;
  try {
    input = JSON.parse(rawInput);
  } catch {
    output({ result: 'continue', message: 'Failed to parse hook input' });
    return;
  }

  const cwd = input.cwd || process.cwd();

  // Find active ledger
  const ledgers = findLedgers(cwd);

  if (ledgers.length === 0) {
    output({
      result: 'continue',
      message: 'No continuity ledger found - state not saved before compaction',
    });
    return;
  }

  const activeLedger = ledgers[0];
  let updatedContent = activeLedger.content;

  // Update timestamp
  updatedContent = updateTimestamp(updatedContent);

  // Mark unconfirmed items
  const { content: markedContent, markedCount } = markUnconfirmedItems(updatedContent);
  updatedContent = markedContent;

  // Add compaction note
  updatedContent = addCompactionNote(
    updatedContent,
    input.context_tokens,
    input.max_tokens
  );

  // Save updated ledger
  try {
    ensureLedgerDir(cwd);
    writeFileSync(activeLedger.path, updatedContent, 'utf8');

    let message = `Ledger saved: ${activeLedger.name}`;
    if (markedCount > 0) {
      message += ` (marked ${markedCount} items as UNCONFIRMED)`;
    }

    output({
      result: 'continue',
      message,
    });
  } catch (error) {
    const writeError = error as { message?: string };
    output({
      result: 'continue',
      message: `Failed to save ledger: ${writeError.message || 'unknown error'}`,
    });
  }
}

main().catch((error) => {
  output({ result: 'continue', message: `Hook error: ${error.message}` });
});
