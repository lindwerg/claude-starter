/**
 * VSA Validation Hook
 *
 * Validates Vertical Slice Architecture structure for backend files.
 * Checks import paths and required files in slices.
 *
 * Event: PostToolUse (Edit|Write)
 */

import { existsSync, readFileSync } from 'fs';
import { dirname, basename, join, relative } from 'path';
import { PostToolUseInput, HookOutput, readStdin, output } from './types';

interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

// Required files in a VSA slice
const SLICE_REQUIRED_FILES = [
  'index.ts',
];

// Recommended files (warn if missing)
const SLICE_RECOMMENDED_FILES = [
  '*.controller.ts',
  '*.service.ts',
  '*.schema.ts',
];

function isBackendFile(filePath: string): boolean {
  // Check if file is in src/features/ (backend VSA structure)
  return filePath.includes('/src/features/') && /\.(ts|tsx)$/.test(filePath);
}

function getFilePath(input: PostToolUseInput): string | null {
  const toolInput = input.tool_input;
  return (toolInput.file_path as string) || (toolInput.path as string) || null;
}

function getSliceDir(filePath: string): string | null {
  // Extract slice directory from path like src/features/auth/auth.service.ts
  const match = filePath.match(/(.+\/src\/features\/[^/]+)/);
  return match ? match[1] : null;
}

function validateImports(filePath: string, content: string): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  // Parse import statements
  const importRegex = /import\s+(?:(?:\{[^}]*\}|\*\s+as\s+\w+|\w+)\s+from\s+)?['"]([^'"]+)['"]/g;
  let match;

  while ((match = importRegex.exec(content)) !== null) {
    const importPath = match[1];

    // Skip external packages
    if (!importPath.startsWith('.') && !importPath.startsWith('/')) {
      continue;
    }

    // Check cross-slice imports
    if (importPath.includes('/features/') && !importPath.includes('/features/shared')) {
      const currentSlice = filePath.match(/\/features\/([^/]+)/)?.[1];
      const importSlice = importPath.match(/\/features\/([^/]+)/)?.[1];

      if (currentSlice && importSlice && currentSlice !== importSlice) {
        // Cross-slice import must go through index.ts
        if (!importPath.endsWith('/index') && !importPath.match(/\/[^/]+$/)) {
          errors.push(
            `Cross-slice import must use index.ts: "${importPath}" should import from "../${importSlice}" or "../${importSlice}/index"`
          );
        }
      }
    }

    // Warn about deep imports into shared
    if (importPath.includes('/shared/') && importPath.split('/shared/')[1]?.includes('/')) {
      const deepPath = importPath.split('/shared/')[1];
      if (deepPath.split('/').length > 2) {
        warnings.push(`Deep import into shared: "${importPath}" - consider flattening`);
      }
    }
  }

  return { valid: errors.length === 0, errors, warnings };
}

function validateSliceStructure(sliceDir: string): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  // Check required files
  for (const required of SLICE_REQUIRED_FILES) {
    const filePath = join(sliceDir, required);
    if (!existsSync(filePath)) {
      errors.push(`Missing required file: ${required}`);
    }
  }

  // Check recommended files (just warn)
  for (const pattern of SLICE_RECOMMENDED_FILES) {
    if (pattern.includes('*')) {
      // Glob pattern - check if any matching file exists
      const basePattern = pattern.replace('*.', '.');
      const sliceName = basename(sliceDir);
      const expectedFile = `${sliceName}${basePattern}`;
      const filePath = join(sliceDir, expectedFile);

      if (!existsSync(filePath)) {
        warnings.push(`Consider adding: ${expectedFile}`);
      }
    }
  }

  return { valid: errors.length === 0, errors, warnings };
}

async function main(): Promise<void> {
  const rawInput = await readStdin();

  let input: PostToolUseInput;
  try {
    input = JSON.parse(rawInput);
  } catch {
    output({ result: 'continue', message: 'Failed to parse hook input' });
    return;
  }

  // Only process Edit and Write tools
  if (!['Edit', 'Write'].includes(input.tool_name)) {
    output({ result: 'continue' });
    return;
  }

  const filePath = getFilePath(input);
  if (!filePath) {
    output({ result: 'continue' });
    return;
  }

  // Only validate backend files in VSA structure
  if (!isBackendFile(filePath)) {
    output({ result: 'continue' });
    return;
  }

  const allErrors: string[] = [];
  const allWarnings: string[] = [];

  // Read file content for import validation
  try {
    const content = readFileSync(filePath, 'utf8');
    const importResult = validateImports(filePath, content);
    allErrors.push(...importResult.errors);
    allWarnings.push(...importResult.warnings);
  } catch {
    // File might not exist yet or be unreadable
  }

  // Validate slice structure
  const sliceDir = getSliceDir(filePath);
  if (sliceDir && existsSync(sliceDir)) {
    const structureResult = validateSliceStructure(sliceDir);
    allErrors.push(...structureResult.errors);
    allWarnings.push(...structureResult.warnings);
  }

  // Build result message
  let message = '';

  if (allErrors.length > 0) {
    message += `VSA Validation Errors:\n${allErrors.map(e => `  - ${e}`).join('\n')}\n`;
  }

  if (allWarnings.length > 0) {
    message += `\nVSA Warnings:\n${allWarnings.map(w => `  - ${w}`).join('\n')}`;
  }

  if (allErrors.length > 0) {
    output({ result: 'block', message });
    return;
  }

  output({
    result: 'continue',
    message: allWarnings.length > 0 ? message : `VSA structure valid for ${basename(filePath)}`,
  });
}

main().catch((error) => {
  output({ result: 'continue', message: `Hook error: ${error.message}` });
});
