#!/usr/bin/env npx tsx
/**
 * VSA Architecture Validator
 * Validates Vertical Slice Architecture structure for backend
 *
 * Usage: npx tsx scripts/validate-vsa.ts [--path src/]
 */

import * as fs from 'fs';
import * as path from 'path';

interface ValidationResult {
  feature: string;
  passed: boolean;
  errors: string[];
  warnings: string[];
}

interface VSAConfig {
  srcPath: string;
  requiredFiles: string[];
  forbiddenPatterns: RegExp[];
}

const DEFAULT_CONFIG: VSAConfig = {
  srcPath: 'src/features',
  requiredFiles: ['controller.ts', 'service.ts', 'repository.ts', 'index.ts'],
  forbiddenPatterns: [
    /from ['"]\.\.\/(?!shared)[^'"]+['"]/,  // Cross-feature imports
    /from ['"]@features\/[^/]+\/(?!index)[^'"]+['"]/,  // Direct file imports
  ],
};

function getFeatures(featuresPath: string): string[] {
  if (!fs.existsSync(featuresPath)) {
    return [];
  }
  return fs.readdirSync(featuresPath).filter((name) => {
    const fullPath = path.join(featuresPath, name);
    return fs.statSync(fullPath).isDirectory();
  });
}

function checkRequiredFiles(featurePath: string, required: string[]): string[] {
  const errors: string[] = [];
  const files = fs.readdirSync(featurePath);

  for (const req of required) {
    // Check for exact match or alternative (dto.ts vs schema.ts)
    const alternatives = req === 'dto.ts' ? ['dto.ts', 'schema.ts'] : [req];
    const found = alternatives.some((alt) =>
      files.some((f) => f === alt || f.endsWith(`.${alt}`))
    );

    if (!found && req !== 'dto.ts') {
      errors.push(`Missing required file: ${req}`);
    }
  }

  // Check for dto.ts OR schema.ts
  const hasDtoOrSchema = files.some(
    (f) => f.includes('dto.ts') || f.includes('schema.ts')
  );
  if (!hasDtoOrSchema) {
    errors.push('Missing dto.ts or schema.ts for validation schemas');
  }

  return errors;
}

function checkImports(featurePath: string, featureName: string): string[] {
  const errors: string[] = [];
  const files = fs.readdirSync(featurePath).filter((f) => f.endsWith('.ts'));

  for (const file of files) {
    const filePath = path.join(featurePath, file);
    const content = fs.readFileSync(filePath, 'utf-8');
    const lines = content.split('\n');

    lines.forEach((line, idx) => {
      // Check for cross-feature imports
      const crossFeatureMatch = line.match(
        /from ['"]@features\/([^/'"]+)(?:\/[^'"]+)?['"]/
      );
      if (crossFeatureMatch && crossFeatureMatch[1] !== featureName) {
        const importedFeature = crossFeatureMatch[1];
        // Allow only index imports
        if (!line.includes(`@features/${importedFeature}'`) &&
            !line.includes(`@features/${importedFeature}"`)) {
          errors.push(
            `${file}:${idx + 1} - Cross-feature import must use index: ${line.trim()}`
          );
        }
      }

      // Check for relative cross-feature imports
      const relativeMatch = line.match(/from ['"](\.\.\/[^'"]+)['"]/);
      if (relativeMatch && !relativeMatch[1].startsWith('../shared')) {
        errors.push(
          `${file}:${idx + 1} - Relative cross-feature import forbidden: ${line.trim()}`
        );
      }
    });
  }

  return errors;
}

function checkIndexExports(featurePath: string): string[] {
  const warnings: string[] = [];
  const indexPath = path.join(featurePath, 'index.ts');

  if (!fs.existsSync(indexPath)) {
    return ['index.ts not found'];
  }

  const content = fs.readFileSync(indexPath, 'utf-8');

  // Check that index exports main components
  const expectedExports = ['controller', 'service', 'routes'];
  for (const exp of expectedExports) {
    if (!content.toLowerCase().includes(exp)) {
      warnings.push(`index.ts might be missing export for: ${exp}`);
    }
  }

  return warnings;
}

function validateFeature(
  featuresPath: string,
  featureName: string,
  config: VSAConfig
): ValidationResult {
  const featurePath = path.join(featuresPath, featureName);
  const errors: string[] = [];
  const warnings: string[] = [];

  // Check required files
  errors.push(...checkRequiredFiles(featurePath, config.requiredFiles));

  // Check imports
  errors.push(...checkImports(featurePath, featureName));

  // Check index exports
  warnings.push(...checkIndexExports(featurePath));

  return {
    feature: featureName,
    passed: errors.length === 0,
    errors,
    warnings,
  };
}

function printResults(results: ValidationResult[]): void {
  console.log('\n=== VSA Architecture Validation ===\n');

  let totalPassed = 0;
  let totalFailed = 0;

  for (const result of results) {
    const status = result.passed ? '\x1b[32mPASS\x1b[0m' : '\x1b[31mFAIL\x1b[0m';
    console.log(`[${status}] Feature: ${result.feature}`);

    if (result.errors.length > 0) {
      console.log('  Errors:');
      result.errors.forEach((e) => console.log(`    - ${e}`));
    }

    if (result.warnings.length > 0) {
      console.log('  Warnings:');
      result.warnings.forEach((w) => console.log(`    - ${w}`));
    }

    if (result.passed) totalPassed++;
    else totalFailed++;

    console.log('');
  }

  console.log('---');
  console.log(`Total: ${results.length} features`);
  console.log(`Passed: ${totalPassed} | Failed: ${totalFailed}`);

  if (totalFailed > 0) {
    process.exit(1);
  }
}

function main(): void {
  const args = process.argv.slice(2);
  let srcPath = DEFAULT_CONFIG.srcPath;

  const pathIdx = args.indexOf('--path');
  if (pathIdx !== -1 && args[pathIdx + 1]) {
    srcPath = path.join(args[pathIdx + 1], 'features');
  }

  const featuresPath = path.resolve(process.cwd(), srcPath);

  if (!fs.existsSync(featuresPath)) {
    console.log(`Features directory not found: ${featuresPath}`);
    console.log('Create src/features/ with VSA slices to validate.');
    process.exit(0);
  }

  const features = getFeatures(featuresPath);

  if (features.length === 0) {
    console.log('No features found to validate.');
    process.exit(0);
  }

  const results = features.map((f) =>
    validateFeature(featuresPath, f, DEFAULT_CONFIG)
  );

  printResults(results);
}

main();
