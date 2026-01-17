// src/vsa-validate.ts
import { existsSync, readFileSync } from "fs";
import { basename, join } from "path";

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

// src/vsa-validate.ts
var SLICE_REQUIRED_FILES = [
  "index.ts"
];
var SLICE_RECOMMENDED_FILES = [
  "*.controller.ts",
  "*.service.ts",
  "*.schema.ts"
];
function isBackendFile(filePath) {
  return filePath.includes("/src/features/") && /\.(ts|tsx)$/.test(filePath);
}
function getFilePath(input) {
  const toolInput = input.tool_input;
  return toolInput.file_path || toolInput.path || null;
}
function getSliceDir(filePath) {
  const match = filePath.match(/(.+\/src\/features\/[^/]+)/);
  return match ? match[1] : null;
}
function validateImports(filePath, content) {
  const errors = [];
  const warnings = [];
  const importRegex = /import\s+(?:(?:\{[^}]*\}|\*\s+as\s+\w+|\w+)\s+from\s+)?['"]([^'"]+)['"]/g;
  let match;
  while ((match = importRegex.exec(content)) !== null) {
    const importPath = match[1];
    if (!importPath.startsWith(".") && !importPath.startsWith("/")) {
      continue;
    }
    if (importPath.includes("/features/") && !importPath.includes("/features/shared")) {
      const currentSlice = filePath.match(/\/features\/([^/]+)/)?.[1];
      const importSlice = importPath.match(/\/features\/([^/]+)/)?.[1];
      if (currentSlice && importSlice && currentSlice !== importSlice) {
        if (!importPath.endsWith("/index") && !importPath.match(/\/[^/]+$/)) {
          errors.push(
            `Cross-slice import must use index.ts: "${importPath}" should import from "../${importSlice}" or "../${importSlice}/index"`
          );
        }
      }
    }
    if (importPath.includes("/shared/") && importPath.split("/shared/")[1]?.includes("/")) {
      const deepPath = importPath.split("/shared/")[1];
      if (deepPath.split("/").length > 2) {
        warnings.push(`Deep import into shared: "${importPath}" - consider flattening`);
      }
    }
  }
  return { valid: errors.length === 0, errors, warnings };
}
function validateSliceStructure(sliceDir) {
  const errors = [];
  const warnings = [];
  for (const required of SLICE_REQUIRED_FILES) {
    const filePath = join(sliceDir, required);
    if (!existsSync(filePath)) {
      errors.push(`Missing required file: ${required}`);
    }
  }
  for (const pattern of SLICE_RECOMMENDED_FILES) {
    if (pattern.includes("*")) {
      const basePattern = pattern.replace("*.", ".");
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
async function main() {
  const rawInput = await readStdin();
  let input;
  try {
    input = JSON.parse(rawInput);
  } catch {
    output({ result: "continue", message: "Failed to parse hook input" });
    return;
  }
  if (!["Edit", "Write"].includes(input.tool_name)) {
    output({ result: "continue" });
    return;
  }
  const filePath = getFilePath(input);
  if (!filePath) {
    output({ result: "continue" });
    return;
  }
  if (!isBackendFile(filePath)) {
    output({ result: "continue" });
    return;
  }
  const allErrors = [];
  const allWarnings = [];
  try {
    const content = readFileSync(filePath, "utf8");
    const importResult = validateImports(filePath, content);
    allErrors.push(...importResult.errors);
    allWarnings.push(...importResult.warnings);
  } catch {
  }
  const sliceDir = getSliceDir(filePath);
  if (sliceDir && existsSync(sliceDir)) {
    const structureResult = validateSliceStructure(sliceDir);
    allErrors.push(...structureResult.errors);
    allWarnings.push(...structureResult.warnings);
  }
  let message = "";
  if (allErrors.length > 0) {
    message += `VSA Validation Errors:
${allErrors.map((e) => `  - ${e}`).join("\n")}
`;
  }
  if (allWarnings.length > 0) {
    message += `
VSA Warnings:
${allWarnings.map((w) => `  - ${w}`).join("\n")}`;
  }
  if (allErrors.length > 0) {
    output({ result: "block", message });
    return;
  }
  output({
    result: "continue",
    message: allWarnings.length > 0 ? message : `VSA structure valid for ${basename(filePath)}`
  });
}
main().catch((error) => {
  output({ result: "continue", message: `Hook error: ${error.message}` });
});
