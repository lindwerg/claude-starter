/**
 * Infrastructure Manager - управление docker, backend, frontend
 *
 * Поднимает и останавливает всю инфраструктуру для E2E тестов:
 * - Docker Compose (PostgreSQL, Redis)
 * - Backend (pnpm dev:backend)
 * - Frontend (pnpm dev:frontend)
 *
 * С healthchecks и graceful shutdown.
 */

import { exec, ChildProcess } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs/promises';

const execAsync = promisify(exec);

// ============================================================================
// Types
// ============================================================================

export interface HealthcheckConfig {
  command?: string;
  url?: string;
  retries: number;
  interval?: number; // milliseconds
}

export interface ServiceConfig {
  command: string;
  cwd?: string;
  port?: number;
  healthcheck: HealthcheckConfig;
}

export interface InfrastructureConfig {
  database: ServiceConfig & {
    compose_file?: string;
    service?: string;
  };
  backend: ServiceConfig;
  frontend: ServiceConfig;
}

export interface InfrastructureHandle {
  dbProcess?: ChildProcess;
  backendProcess?: ChildProcess;
  frontendProcess?: ChildProcess;
  pids: number[];
}

// ============================================================================
// Default Configuration (claude-starter projects)
// ============================================================================

const DEFAULT_INFRASTRUCTURE: InfrastructureConfig = {
  database: {
    command: 'docker compose up -d postgres redis',
    compose_file: 'docker-compose.yml',
    service: 'postgres',
    healthcheck: {
      command: 'pg_isready -U postgres',
      retries: 10,
      interval: 2000
    }
  },
  backend: {
    command: 'pnpm dev:backend',
    cwd: './',
    port: 4000,
    healthcheck: {
      url: 'http://localhost:4000/health',
      retries: 15,
      interval: 2000
    }
  },
  frontend: {
    command: 'pnpm dev:frontend',
    cwd: './',
    port: 3000,
    healthcheck: {
      url: 'http://localhost:3000',
      retries: 15,
      interval: 2000
    }
  }
};

// ============================================================================
// Load Configuration
// ============================================================================

/**
 * Загрузить конфигурацию инфраструктуры
 *
 * Порядок приоритета:
 * 1. .bmad/infrastructure.yaml (если существует)
 * 2. DEFAULT_INFRASTRUCTURE (hardcoded defaults)
 */
export async function loadInfrastructureConfig(): Promise<InfrastructureConfig> {
  const configPath = '.bmad/infrastructure.yaml';

  try {
    const content = await fs.readFile(configPath, 'utf-8');
    const parsed = JSON.parse(content); // TODO: Use YAML parser when available

    console.log(`✅ Loaded infrastructure config from ${configPath}`);
    return parsed as InfrastructureConfig;
  } catch (error) {
    console.log(`📋 Using default infrastructure config (${configPath} not found)`);
    return DEFAULT_INFRASTRUCTURE;
  }
}

// ============================================================================
// Healthcheck Helpers
// ============================================================================

/**
 * Ожидание healthcheck (retry logic)
 */
async function waitForHealthcheck(
  name: string,
  config: HealthcheckConfig
): Promise<boolean> {
  const interval = config.interval || 2000;
  let attempt = 0;

  while (attempt < config.retries) {
    attempt++;

    try {
      if (config.url) {
        // HTTP healthcheck
        const response = await fetch(config.url);
        if (response.ok) {
          console.log(`  ✅ ${name} healthcheck passed (attempt ${attempt}/${config.retries})`);
          return true;
        }
      } else if (config.command) {
        // Command healthcheck
        await execAsync(config.command);
        console.log(`  ✅ ${name} healthcheck passed (attempt ${attempt}/${config.retries})`);
        return true;
      }
    } catch (error) {
      // Healthcheck failed, retry
      if (attempt < config.retries) {
        console.log(`  ⏳ ${name} healthcheck failed (attempt ${attempt}/${config.retries}), retrying in ${interval}ms...`);
        await new Promise(resolve => setTimeout(resolve, interval));
      }
    }
  }

  throw new Error(`${name} healthcheck failed after ${config.retries} attempts`);
}

// ============================================================================
// Start Infrastructure
// ============================================================================

/**
 * Запустить всю инфраструктуру
 *
 * Порядок:
 * 1. Docker Compose (PostgreSQL, Redis)
 * 2. Backend (с healthcheck)
 * 3. Frontend (с healthcheck)
 *
 * @returns handle для остановки
 */
export async function startInfrastructure(): Promise<InfrastructureHandle> {
  console.log('\n🚀 Starting infrastructure...\n');

  const config = await loadInfrastructureConfig();
  const handle: InfrastructureHandle = { pids: [] };

  // 1. Start Database (Docker Compose)
  console.log('📦 Starting database (Docker Compose)...');
  try {
    await execAsync(config.database.command);
    console.log(`  ✅ Docker Compose started`);

    // Wait for database healthcheck
    await waitForHealthcheck('Database', config.database.healthcheck);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`Failed to start database: ${message}`);
  }

  // 2. Start Backend
  console.log('\n🔧 Starting backend...');
  try {
    const backendProcess = exec(config.backend.command, {
      cwd: config.backend.cwd || process.cwd()
    });

    handle.backendProcess = backendProcess;
    if (backendProcess.pid) {
      handle.pids.push(backendProcess.pid);
    }

    // Log output for debugging
    backendProcess.stdout?.on('data', (data) => {
      console.log(`[backend] ${data.toString().trim()}`);
    });
    backendProcess.stderr?.on('data', (data) => {
      console.error(`[backend] ${data.toString().trim()}`);
    });

    // Wait for backend healthcheck
    await waitForHealthcheck('Backend', config.backend.healthcheck);
  } catch (error) {
    // Cleanup on failure
    await stopInfrastructure(handle);
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`Failed to start backend: ${message}`);
  }

  // 3. Start Frontend
  console.log('\n🎨 Starting frontend...');
  try {
    const frontendProcess = exec(config.frontend.command, {
      cwd: config.frontend.cwd || process.cwd()
    });

    handle.frontendProcess = frontendProcess;
    if (frontendProcess.pid) {
      handle.pids.push(frontendProcess.pid);
    }

    // Log output for debugging
    frontendProcess.stdout?.on('data', (data) => {
      console.log(`[frontend] ${data.toString().trim()}`);
    });
    frontendProcess.stderr?.on('data', (data) => {
      console.error(`[frontend] ${data.toString().trim()}`);
    });

    // Wait for frontend healthcheck
    await waitForHealthcheck('Frontend', config.frontend.healthcheck);
  } catch (error) {
    // Cleanup on failure
    await stopInfrastructure(handle);
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`Failed to start frontend: ${message}`);
  }

  console.log('\n✅ Infrastructure ready!\n');
  return handle;
}

// ============================================================================
// Stop Infrastructure
// ============================================================================

/**
 * Остановить всю инфраструктуру (graceful shutdown)
 *
 * Порядок:
 * 1. Kill frontend process
 * 2. Kill backend process
 * 3. Docker Compose down
 */
export async function stopInfrastructure(handle: InfrastructureHandle): Promise<void> {
  console.log('\n🛑 Stopping infrastructure...\n');

  // 1. Stop Frontend
  if (handle.frontendProcess && !handle.frontendProcess.killed) {
    console.log('🎨 Stopping frontend...');
    try {
      handle.frontendProcess.kill('SIGTERM');
      console.log('  ✅ Frontend stopped');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error(`  ⚠️  Failed to stop frontend: ${message}`);
    }
  }

  // 2. Stop Backend
  if (handle.backendProcess && !handle.backendProcess.killed) {
    console.log('🔧 Stopping backend...');
    try {
      handle.backendProcess.kill('SIGTERM');
      console.log('  ✅ Backend stopped');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error(`  ⚠️  Failed to stop backend: ${message}`);
    }
  }

  // 3. Stop Docker Compose
  console.log('📦 Stopping Docker Compose...');
  try {
    await execAsync('docker compose down');
    console.log('  ✅ Docker Compose stopped');
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`  ⚠️  Failed to stop Docker Compose: ${message}`);
  }

  // 4. Kill remaining processes (fallback)
  for (const pid of handle.pids) {
    try {
      process.kill(pid, 'SIGKILL');
    } catch (error) {
      // Process already dead
    }
  }

  console.log('\n✅ Infrastructure stopped\n');
}
