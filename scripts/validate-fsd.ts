#!/usr/bin/env npx tsx
/**
 * FSD Architecture Validator
 * Validates Feature-Sliced Design structure for frontend
 *
 * Usage: npx tsx scripts/validate-fsd.ts [--path src/]
 */

import * as fs from 'fs';
import * as path from 'path';

interface ImportViolation {
  file: string;
  line: number;
  importPath: string;
  fromLayer: string;
  toLayer: string;
  message: string;
}

interface LayerResult {
  layer: string;
  exists: boolean;
  violations: ImportViolation[];
}

// FSD layer hierarchy (top to bottom)
const FSD_LAYERS = ['app', 'pages', 'widgets', 'features', 'entities', 'shared'] as const;
type Layer = (typeof FSD_LAYERS)[number];

// Import rules: layer -> allowed imports
const IMPORT_RULES: Record<Layer, Layer[]> = {
  app: ['pages', 'widgets', 'features', 'entities', 'shared'],
  pages: ['widgets', 'features', 'entities', 'shared'],
  widgets: ['features', 'entities', 'shared'],
  features: ['entities', 'shared'],
  entities: ['shared'],
  shared: [],
};

function getLayerFromPath(importPath: string): Layer | null {
  for (const layer of FSD_LAYERS) {
    if (
      importPath.startsWith(`@/${layer}`) ||
      importPath.startsWith(`@${layer}`) ||
      importPath.includes(`/${layer}/`) ||
      importPath.startsWith(`./${layer}`) ||
      importPath.startsWith(`../${layer}`)
    ) {
      return layer;
    }
  }
  return null;
}

function getLayerFromFilePath(filePath: string): Layer | null {
  for (const layer of FSD_LAYERS) {
    if (filePath.includes(`/src/${layer}/`) || filePath.includes(`\\src\\${layer}\\`)) {
      return layer;
    }
  }
  return null;
}

function isValidImport(fromLayer: Layer, toLayer: Layer): boolean {
  return IMPORT_RULES[fromLayer].includes(toLayer);
}

function extractImports(content: string): Array<{ line: number; path: string }> {
  const imports: Array<{ line: number; path: string }> = [];
  const lines = content.split('\n');

  lines.forEach((line, idx) => {
    // Match import statements
    const importMatch = line.match(/(?:import|from)\s+['"]([^'"]+)['"]/);
    if (importMatch) {
      imports.push({ line: idx + 1, path: importMatch[1] });
    }

    // Match dynamic imports
    const dynamicMatch = line.match(/import\(['"]([^'"]+)['"]\)/);
    if (dynamicMatch) {
      imports.push({ line: idx + 1, path: dynamicMatch[1] });
    }
  });

  return imports;
}

function validateFile(filePath: string): ImportViolation[] {
  const violations: ImportViolation[] = [];
  const fromLayer = getLayerFromFilePath(filePath);

  if (!fromLayer) return violations;

  const content = fs.readFileSync(filePath, 'utf-8');
  const imports = extractImports(content);

  for (const imp of imports) {
    const toLayer = getLayerFromPath(imp.path);

    if (!toLayer) continue; // External or relative within same layer

    if (!isValidImport(fromLayer, toLayer)) {
      violations.push({
        file: filePath,
        line: imp.line,
        importPath: imp.path,
        fromLayer,
        toLayer,
        message: `${fromLayer} cannot import from ${toLayer}. Allowed: ${IMPORT_RULES[fromLayer].join(', ') || 'none'}`,
      });
    }
  }

  return violations;
}

function getAllTsFiles(dir: string): string[] {
  const files: string[] = [];

  if (!fs.existsSync(dir)) return files;

  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory() && !entry.name.startsWith('.') && entry.name !== 'node_modules') {
      files.push(...getAllTsFiles(fullPath));
    } else if (entry.isFile() && /\.(ts|tsx)$/.test(entry.name)) {
      files.push(fullPath);
    }
  }

  return files;
}

function checkLayerStructure(srcPath: string): LayerResult[] {
  const results: LayerResult[] = [];

  for (const layer of FSD_LAYERS) {
    const layerPath = path.join(srcPath, layer);
    const exists = fs.existsSync(layerPath);
    const violations: ImportViolation[] = [];

    if (exists) {
      const files = getAllTsFiles(layerPath);
      for (const file of files) {
        violations.push(...validateFile(file));
      }
    }

    results.push({ layer, exists, violations });
  }

  return results;
}

function printResults(results: LayerResult[], srcPath: string): void {
  console.log('\n=== FSD Architecture Validation ===\n');
  console.log(`Source: ${srcPath}\n`);

  // Layer structure
  console.log('Layer Structure:');
  for (const result of results) {
    const status = result.exists ? '\x1b[32m[OK]\x1b[0m' : '\x1b[33m[--]\x1b[0m';
    console.log(`  ${status} ${result.layer}/`);
  }

  console.log('\nImport Rules:');
  for (const layer of FSD_LAYERS) {
    const allowed = IMPORT_RULES[layer].join(', ') || 'nothing (leaf layer)';
    console.log(`  ${layer} -> ${allowed}`);
  }

  // Violations
  const allViolations = results.flatMap((r) => r.violations);

  if (allViolations.length === 0) {
    console.log('\n\x1b[32mNo import violations found!\x1b[0m\n');
    return;
  }

  console.log(`\n\x1b[31mFound ${allViolations.length} violation(s):\x1b[0m\n`);

  for (const v of allViolations) {
    const relativePath = path.relative(process.cwd(), v.file);
    console.log(`\x1b[31m[VIOLATION]\x1b[0m ${relativePath}:${v.line}`);
    console.log(`  Import: ${v.importPath}`);
    console.log(`  Rule: ${v.message}`);
    console.log(`  Fix: Move shared code to lower layer or restructure\n`);
  }

  process.exit(1);
}

function main(): void {
  const args = process.argv.slice(2);
  let srcPath = 'src';

  const pathIdx = args.indexOf('--path');
  if (pathIdx !== -1 && args[pathIdx + 1]) {
    srcPath = args[pathIdx + 1];
  }

  const fullPath = path.resolve(process.cwd(), srcPath);

  if (!fs.existsSync(fullPath)) {
    console.log(`Source directory not found: ${fullPath}`);
    console.log('Create src/ with FSD layers to validate.');
    process.exit(0);
  }

  const results = checkLayerStructure(fullPath);
  printResults(results, fullPath);
}

main();
