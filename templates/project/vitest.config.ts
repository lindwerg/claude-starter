import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    /* Global Settings */
    globals: true,
    environment: 'node', // Use 'jsdom' for frontend tests

    /* Test Files */
    include: ['**/*.{test,spec}.{ts,tsx}'],
    exclude: ['**/node_modules/**', '**/dist/**', '**/e2e/**'],

    /* Coverage */
    coverage: {
      enabled: true,
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      reportsDirectory: './coverage',
      thresholds: {
        statements: 80,
        branches: 80,
        functions: 80,
        lines: 80,
      },
      exclude: [
        'node_modules/',
        'dist/',
        '**/*.d.ts',
        '**/*.config.{ts,js}',
        '**/types/**',
        '**/__mocks__/**',
        '**/generated/**',
      ],
    },

    /* Setup */
    setupFiles: ['./vitest.setup.ts'],

    /* Timeouts */
    testTimeout: 10000,
    hookTimeout: 10000,

    /* Reporters */
    reporters: ['verbose'],
  },

  /* Resolve Aliases */
  resolve: {
    alias: {
      '@shared': path.resolve(__dirname, './packages/shared/src'),
      '@api-types': path.resolve(__dirname, './packages/api-types/src'),
      '@features': path.resolve(__dirname, './apps/backend/src/features'),
      '@app': path.resolve(__dirname, './apps/frontend/src/app'),
      '@pages': path.resolve(__dirname, './apps/frontend/src/pages'),
      '@widgets': path.resolve(__dirname, './apps/frontend/src/widgets'),
      '@entities': path.resolve(__dirname, './apps/frontend/src/entities'),
      '@frontend-features': path.resolve(
        __dirname,
        './apps/frontend/src/features'
      ),
      '@frontend-shared': path.resolve(
        __dirname,
        './apps/frontend/src/shared'
      ),
    },
  },
});
