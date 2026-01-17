#!/usr/bin/env npx tsx
/**
 * Scaffolding Tool
 * Generates boilerplate for FSD/VSA architecture
 *
 * Usage:
 *   npx tsx scripts/scaffold.ts feature <name>  - Create VSA feature slice
 *   npx tsx scripts/scaffold.ts page <name>     - Create FSD page
 *   npx tsx scripts/scaffold.ts entity <name>   - Create FSD entity
 */

import * as fs from 'fs';
import * as path from 'path';

type ScaffoldType = 'feature' | 'page' | 'entity';

interface Template {
  path: string;
  content: string;
}

// VSA Feature templates
function getFeatureTemplates(name: string): Template[] {
  const pascal = toPascalCase(name);
  const camel = toCamelCase(name);

  return [
    {
      path: `src/features/${name}/${name}.controller.ts`,
      content: `import { Router, Request, Response, NextFunction } from 'express';
import { ${pascal}Service } from './${name}.service';
import { Create${pascal}Schema, Update${pascal}Schema } from './${name}.schema';
import { validateBody } from '@shared/middleware/validate';

const router = Router();
const service = new ${pascal}Service();

router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const items = await service.findAll();
    res.json(items);
  } catch (error) {
    next(error);
  }
});

router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const item = await service.findById(req.params.id);
    if (!item) {
      return res.status(404).json({ error: '${pascal} not found' });
    }
    res.json(item);
  } catch (error) {
    next(error);
  }
});

router.post('/', validateBody(Create${pascal}Schema), async (req: Request, res: Response, next: NextFunction) => {
  try {
    const item = await service.create(req.body);
    res.status(201).json(item);
  } catch (error) {
    next(error);
  }
});

router.put('/:id', validateBody(Update${pascal}Schema), async (req: Request, res: Response, next: NextFunction) => {
  try {
    const item = await service.update(req.params.id, req.body);
    res.json(item);
  } catch (error) {
    next(error);
  }
});

router.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    await service.delete(req.params.id);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

export const ${camel}Router = router;
`,
    },
    {
      path: `src/features/${name}/${name}.service.ts`,
      content: `import { ${pascal}Repository } from './${name}.repository';
import { Create${pascal}Dto, Update${pascal}Dto, ${pascal} } from './${name}.types';

export class ${pascal}Service {
  private repository: ${pascal}Repository;

  constructor() {
    this.repository = new ${pascal}Repository();
  }

  async findAll(): Promise<${pascal}[]> {
    return this.repository.findAll();
  }

  async findById(id: string): Promise<${pascal} | null> {
    return this.repository.findById(id);
  }

  async create(dto: Create${pascal}Dto): Promise<${pascal}> {
    return this.repository.create(dto);
  }

  async update(id: string, dto: Update${pascal}Dto): Promise<${pascal}> {
    return this.repository.update(id, dto);
  }

  async delete(id: string): Promise<void> {
    return this.repository.delete(id);
  }
}
`,
    },
    {
      path: `src/features/${name}/${name}.repository.ts`,
      content: `import { prisma } from '@shared/lib/prisma';
import { Create${pascal}Dto, Update${pascal}Dto, ${pascal} } from './${name}.types';

export class ${pascal}Repository {
  async findAll(): Promise<${pascal}[]> {
    return prisma.${camel}.findMany();
  }

  async findById(id: string): Promise<${pascal} | null> {
    return prisma.${camel}.findUnique({ where: { id } });
  }

  async create(data: Create${pascal}Dto): Promise<${pascal}> {
    return prisma.${camel}.create({ data });
  }

  async update(id: string, data: Update${pascal}Dto): Promise<${pascal}> {
    return prisma.${camel}.update({ where: { id }, data });
  }

  async delete(id: string): Promise<void> {
    await prisma.${camel}.delete({ where: { id } });
  }
}
`,
    },
    {
      path: `src/features/${name}/${name}.schema.ts`,
      content: `import { z } from 'zod';

export const ${pascal}Schema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(255),
  createdAt: z.date(),
  updatedAt: z.date(),
});

export const Create${pascal}Schema = ${pascal}Schema.omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});

export const Update${pascal}Schema = Create${pascal}Schema.partial();

export type ${pascal}Input = z.infer<typeof ${pascal}Schema>;
export type Create${pascal}Input = z.infer<typeof Create${pascal}Schema>;
export type Update${pascal}Input = z.infer<typeof Update${pascal}Schema>;
`,
    },
    {
      path: `src/features/${name}/${name}.types.ts`,
      content: `export interface ${pascal} {
  id: string;
  name: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Create${pascal}Dto {
  name: string;
}

export interface Update${pascal}Dto {
  name?: string;
}
`,
    },
    {
      path: `src/features/${name}/index.ts`,
      content: `export { ${camel}Router } from './${name}.controller';
export { ${pascal}Service } from './${name}.service';
export { ${pascal}Repository } from './${name}.repository';
export * from './${name}.schema';
export * from './${name}.types';
`,
    },
  ];
}

// FSD Page templates
function getPageTemplates(name: string): Template[] {
  const pascal = toPascalCase(name);

  return [
    {
      path: `src/pages/${name}/index.ts`,
      content: `export { ${pascal}Page } from './ui/${pascal}Page';
`,
    },
    {
      path: `src/pages/${name}/ui/${pascal}Page.tsx`,
      content: `import { FC } from 'react';

interface ${pascal}PageProps {
  className?: string;
}

export const ${pascal}Page: FC<${pascal}PageProps> = ({ className }) => {
  return (
    <div className={className}>
      <h1>${pascal}</h1>
      {/* Page content */}
    </div>
  );
};
`,
    },
  ];
}

// FSD Entity templates
function getEntityTemplates(name: string): Template[] {
  const pascal = toPascalCase(name);
  const camel = toCamelCase(name);

  return [
    {
      path: `src/entities/${name}/index.ts`,
      content: `export { ${pascal}Card } from './ui/${pascal}Card';
export { use${pascal} } from './model/use${pascal}';
export type { ${pascal} } from './model/types';
`,
    },
    {
      path: `src/entities/${name}/model/types.ts`,
      content: `export interface ${pascal} {
  id: string;
  name: string;
  createdAt: string;
  updatedAt: string;
}
`,
    },
    {
      path: `src/entities/${name}/model/use${pascal}.ts`,
      content: `import { useQuery } from '@tanstack/react-query';
import { ${camel}Api } from '../api/${camel}Api';
import { ${pascal} } from './types';

export function use${pascal}(id: string) {
  return useQuery<${pascal}>({
    queryKey: ['${camel}', id],
    queryFn: () => ${camel}Api.getById(id),
    enabled: !!id,
  });
}

export function use${pascal}List() {
  return useQuery<${pascal}[]>({
    queryKey: ['${camel}s'],
    queryFn: () => ${camel}Api.getAll(),
  });
}
`,
    },
    {
      path: `src/entities/${name}/api/${camel}Api.ts`,
      content: `import { apiClient } from '@shared/api/client';
import { ${pascal} } from '../model/types';

export const ${camel}Api = {
  getAll: async (): Promise<${pascal}[]> => {
    const response = await apiClient.get('/${name}s');
    return response.data;
  },

  getById: async (id: string): Promise<${pascal}> => {
    const response = await apiClient.get(\`/${name}s/\${id}\`);
    return response.data;
  },
};
`,
    },
    {
      path: `src/entities/${name}/ui/${pascal}Card.tsx`,
      content: `import { FC } from 'react';
import { ${pascal} } from '../model/types';

interface ${pascal}CardProps {
  ${camel}: ${pascal};
  className?: string;
}

export const ${pascal}Card: FC<${pascal}CardProps> = ({ ${camel}, className }) => {
  return (
    <div className={className}>
      <h3>{${camel}.name}</h3>
    </div>
  );
};
`,
    },
  ];
}

// Utility functions
function toPascalCase(str: string): string {
  return str
    .split(/[-_]/)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join('');
}

function toCamelCase(str: string): string {
  const pascal = toPascalCase(str);
  return pascal.charAt(0).toLowerCase() + pascal.slice(1);
}

function createFiles(templates: Template[]): void {
  for (const template of templates) {
    const fullPath = path.resolve(process.cwd(), template.path);
    const dir = path.dirname(fullPath);

    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    fs.writeFileSync(fullPath, template.content);
    console.log(`  \x1b[32m+\x1b[0m ${template.path}`);
  }
}

function scaffold(type: ScaffoldType, name: string): void {
  console.log(`\nScaffolding ${type}: ${name}\n`);

  let templates: Template[];

  switch (type) {
    case 'feature':
      templates = getFeatureTemplates(name);
      break;
    case 'page':
      templates = getPageTemplates(name);
      break;
    case 'entity':
      templates = getEntityTemplates(name);
      break;
    default:
      throw new Error(`Unknown scaffold type: ${type}`);
  }

  createFiles(templates);

  console.log(`\n\x1b[32mDone!\x1b[0m ${type} "${name}" created.\n`);
}

function printUsage(): void {
  console.log(`
Usage: npx tsx scripts/scaffold.ts <type> <name>

Types:
  feature <name>  Create VSA feature slice (backend)
  page <name>     Create FSD page (frontend)
  entity <name>   Create FSD entity (frontend)

Examples:
  npx tsx scripts/scaffold.ts feature user
  npx tsx scripts/scaffold.ts page dashboard
  npx tsx scripts/scaffold.ts entity product
`);
}

// Main
function main(): void {
  const [type, name] = process.argv.slice(2);

  if (!type || !name) {
    printUsage();
    process.exit(1);
  }

  if (!['feature', 'page', 'entity'].includes(type)) {
    console.error(`Unknown type: ${type}`);
    printUsage();
    process.exit(1);
  }

  scaffold(type as ScaffoldType, name.toLowerCase());
}

main();
