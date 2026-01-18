import { defineConfig } from 'vitest/config';
// TDD Guard integration - uncomment when vitest is installed:
// import { VitestReporter } from 'tdd-guard-vitest';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['**/*.test.ts', '**/*.spec.ts'],
    // TDD Guard reporter - uncomment when tdd-guard-vitest is installed:
    // reporters: [
    //   'default',
    //   new VitestReporter(process.cwd()),
    // ],
  },
});
