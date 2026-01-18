#!/usr/bin/env node

const { execSync, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const REPO_URL = 'https://github.com/lindwerg/claude-starter';
const INSTALL_SCRIPT = 'https://raw.githubusercontent.com/lindwerg/claude-starter/main/install.sh';

console.log('');
console.log('\x1b[36m  ╔═══════════════════════════════════════════╗\x1b[0m');
console.log('\x1b[36m  ║       \x1b[32mProvide Starter Kit\x1b[36m                 ║\x1b[0m');
console.log('\x1b[36m  ║   \x1b[0mАвтономная разработка с Claude Code\x1b[36m   ║\x1b[0m');
console.log('\x1b[36m  ╚═══════════════════════════════════════════╝\x1b[0m');
console.log('');

// Check for curl
try {
  execSync('which curl', { stdio: 'ignore' });
} catch {
  console.error('\x1b[31m[✗] curl не найден. Установи curl и попробуй снова.\x1b[0m');
  process.exit(1);
}

// Run install script
console.log('\x1b[34m[→]\x1b[0m Запускаю установку...');
console.log('');

const install = spawn('bash', ['-c', `curl -fsSL ${INSTALL_SCRIPT} | bash`], {
  stdio: 'inherit',
  shell: true
});

install.on('close', (code) => {
  if (code !== 0) {
    console.error('\x1b[31m[✗] Установка завершилась с ошибкой\x1b[0m');
    process.exit(code);
  }
});
