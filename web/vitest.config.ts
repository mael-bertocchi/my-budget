import path from 'node:path';

import { defineConfig } from 'vitest/config';

export default defineConfig({
  resolve: {
    alias: {
      '@application': path.resolve(import.meta.dirname, 'src/application'),
      '@components': path.resolve(import.meta.dirname, 'src/components'),
      '@core': path.resolve(import.meta.dirname, 'src/core'),
      '@pages': path.resolve(import.meta.dirname, 'src/pages'),
      '@': path.resolve(import.meta.dirname, 'src'),
    },
  },
  test: {
    environment: 'node',
    env: {
      TZ: 'Europe/Paris',
    },
    include: ['tests/**/*.test.ts'],
    setupFiles: ['tests/support/setup.ts'],
  },
});
