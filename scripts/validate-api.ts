#!/usr/bin/env npx tsx
/**
 * OpenAPI Validator
 * Validates that code matches OpenAPI specification
 *
 * Usage: npx tsx scripts/validate-api.ts [--spec openapi.yaml] [--src src/]
 */

import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'yaml';

interface Endpoint {
  method: string;
  path: string;
  operationId?: string;
  requestBody?: boolean;
  responses: string[];
}

interface ValidationResult {
  specEndpoints: Endpoint[];
  codeEndpoints: Endpoint[];
  missing: Endpoint[];      // In spec but not in code
  undocumented: Endpoint[]; // In code but not in spec
  schemaIssues: string[];
}

function parseOpenApiSpec(specPath: string): Endpoint[] {
  const content = fs.readFileSync(specPath, 'utf-8');
  const spec = yaml.parse(content);
  const endpoints: Endpoint[] = [];

  const paths = spec.paths || {};

  for (const [pathPattern, methods] of Object.entries(paths)) {
    for (const [method, config] of Object.entries(methods as Record<string, any>)) {
      if (['get', 'post', 'put', 'patch', 'delete'].includes(method)) {
        endpoints.push({
          method: method.toUpperCase(),
          path: pathPattern,
          operationId: config.operationId,
          requestBody: !!config.requestBody,
          responses: Object.keys(config.responses || {}),
        });
      }
    }
  }

  return endpoints;
}

function extractRoutes(content: string): Array<{ method: string; path: string }> {
  const routes: Array<{ method: string; path: string }> = [];

  // Match Express/Fastify route patterns
  const patterns = [
    // app.get('/path', handler)
    /\.(get|post|put|patch|delete)\s*\(\s*['"`]([^'"`]+)['"`]/gi,
    // router.get('/path', handler)
    /router\.(get|post|put|patch|delete)\s*\(\s*['"`]([^'"`]+)['"`]/gi,
    // @Get('/path') decorator
    /@(Get|Post|Put|Patch|Delete)\s*\(\s*['"`]([^'"`]+)['"`]\s*\)/gi,
  ];

  for (const pattern of patterns) {
    let match;
    while ((match = pattern.exec(content)) !== null) {
      routes.push({
        method: match[1].toUpperCase(),
        path: match[2],
      });
    }
  }

  return routes;
}

function getAllControllers(srcPath: string): string[] {
  const files: string[] = [];

  function scan(dir: string): void {
    if (!fs.existsSync(dir)) return;

    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory() && !entry.name.startsWith('.') && entry.name !== 'node_modules') {
        scan(fullPath);
      } else if (
        entry.isFile() &&
        (entry.name.includes('controller') ||
          entry.name.includes('routes') ||
          entry.name.includes('router')) &&
        /\.(ts|js)$/.test(entry.name)
      ) {
        files.push(fullPath);
      }
    }
  }

  scan(srcPath);
  return files;
}

function parseCodeRoutes(srcPath: string): Endpoint[] {
  const controllers = getAllControllers(srcPath);
  const endpoints: Endpoint[] = [];

  for (const file of controllers) {
    const content = fs.readFileSync(file, 'utf-8');
    const routes = extractRoutes(content);

    for (const route of routes) {
      endpoints.push({
        method: route.method,
        path: route.path,
        responses: [],
      });
    }
  }

  return endpoints;
}

function normalizePath(p: string): string {
  // Convert :param to {param} for comparison
  return p.replace(/:([^/]+)/g, '{$1}').toLowerCase();
}

function matchEndpoint(a: Endpoint, b: Endpoint): boolean {
  return (
    a.method === b.method &&
    normalizePath(a.path) === normalizePath(b.path)
  );
}

function validateSchemas(specPath: string): string[] {
  const issues: string[] = [];
  const content = fs.readFileSync(specPath, 'utf-8');
  const spec = yaml.parse(content);

  const schemas = spec.components?.schemas || {};

  for (const [name, schema] of Object.entries(schemas as Record<string, any>)) {
    // Check for missing types
    if (!schema.type && !schema.$ref && !schema.allOf && !schema.oneOf) {
      issues.push(`Schema '${name}' missing type definition`);
    }

    // Check for missing required array when properties exist
    if (schema.properties && !schema.required) {
      issues.push(`Schema '${name}' has properties but no 'required' array`);
    }

    // Check for missing descriptions on operations
    if (schema.type === 'object' && schema.properties) {
      for (const [prop, propSchema] of Object.entries(schema.properties as Record<string, any>)) {
        if (!propSchema.description && !propSchema.$ref) {
          issues.push(`Schema '${name}.${prop}' missing description`);
        }
      }
    }
  }

  return issues;
}

function validate(specPath: string, srcPath: string): ValidationResult {
  const specEndpoints = parseOpenApiSpec(specPath);
  const codeEndpoints = parseCodeRoutes(srcPath);

  // Find missing (in spec but not in code)
  const missing = specEndpoints.filter(
    (spec) => !codeEndpoints.some((code) => matchEndpoint(spec, code))
  );

  // Find undocumented (in code but not in spec)
  const undocumented = codeEndpoints.filter(
    (code) => !specEndpoints.some((spec) => matchEndpoint(code, spec))
  );

  const schemaIssues = validateSchemas(specPath);

  return {
    specEndpoints,
    codeEndpoints,
    missing,
    undocumented,
    schemaIssues,
  };
}

function printResults(result: ValidationResult): void {
  console.log('\n=== OpenAPI Validation ===\n');

  console.log(`Spec endpoints: ${result.specEndpoints.length}`);
  console.log(`Code endpoints: ${result.codeEndpoints.length}`);

  if (result.missing.length === 0 && result.undocumented.length === 0) {
    console.log('\n\x1b[32mAll endpoints are documented and implemented!\x1b[0m');
  }

  if (result.missing.length > 0) {
    console.log(`\n\x1b[31mMissing implementations (${result.missing.length}):\x1b[0m`);
    for (const ep of result.missing) {
      console.log(`  - ${ep.method} ${ep.path}`);
      if (ep.operationId) console.log(`    operationId: ${ep.operationId}`);
    }
  }

  if (result.undocumented.length > 0) {
    console.log(`\n\x1b[33mUndocumented endpoints (${result.undocumented.length}):\x1b[0m`);
    for (const ep of result.undocumented) {
      console.log(`  - ${ep.method} ${ep.path}`);
    }
  }

  if (result.schemaIssues.length > 0) {
    console.log(`\n\x1b[33mSchema issues (${result.schemaIssues.length}):\x1b[0m`);
    for (const issue of result.schemaIssues) {
      console.log(`  - ${issue}`);
    }
  }

  console.log('');

  if (result.missing.length > 0 || result.undocumented.length > 0) {
    process.exit(1);
  }
}

function main(): void {
  const args = process.argv.slice(2);

  let specPath = 'openapi.yaml';
  let srcPath = 'src';

  const specIdx = args.indexOf('--spec');
  if (specIdx !== -1 && args[specIdx + 1]) {
    specPath = args[specIdx + 1];
  }

  const srcIdx = args.indexOf('--src');
  if (srcIdx !== -1 && args[srcIdx + 1]) {
    srcPath = args[srcIdx + 1];
  }

  const fullSpecPath = path.resolve(process.cwd(), specPath);
  const fullSrcPath = path.resolve(process.cwd(), srcPath);

  if (!fs.existsSync(fullSpecPath)) {
    console.log(`OpenAPI spec not found: ${fullSpecPath}`);
    console.log('Create openapi.yaml to validate API.');
    process.exit(0);
  }

  if (!fs.existsSync(fullSrcPath)) {
    console.log(`Source directory not found: ${fullSrcPath}`);
    process.exit(1);
  }

  const result = validate(fullSpecPath, fullSrcPath);
  printResults(result);
}

main();
