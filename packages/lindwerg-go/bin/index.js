#!/usr/bin/env node

const readline = require('readline');
const { execSync, spawn } = require('child_process');
const path = require('path');
const os = require('os');
const fs = require('fs');

// Colors
const green = (s) => `\x1b[32m${s}\x1b[0m`;
const blue = (s) => `\x1b[34m${s}\x1b[0m`;
const yellow = (s) => `\x1b[33m${s}\x1b[0m`;
const red = (s) => `\x1b[31m${s}\x1b[0m`;

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

const question = (q) => new Promise((resolve) => rl.question(q, resolve));

const exec = (cmd, options = {}) => {
  try {
    return execSync(cmd, { encoding: 'utf-8', stdio: 'pipe', ...options });
  } catch (e) {
    return null;
  }
};

async function main() {
  console.log(blue('═══════════════════════════════════════'));
  console.log(blue('   🚀 lindwerg-go: Create New Project'));
  console.log(blue('═══════════════════════════════════════'));
  console.log();

  // Check gh CLI
  if (!exec('which gh')) {
    console.log(red('❌ GitHub CLI (gh) not found. Install: brew install gh'));
    process.exit(1);
  }

  // Check gh auth
  if (!exec('gh auth status')) {
    console.log(red('❌ Not logged in to GitHub. Run: gh auth login'));
    process.exit(1);
  }

  // 1. Project name
  const projectName = await question('📁 Project name: ');
  if (!projectName) {
    console.log(red('❌ Project name required'));
    process.exit(1);
  }
  if (!/^[a-zA-Z0-9_-]+$/.test(projectName)) {
    console.log(red('❌ Invalid name. Use only letters, numbers, hyphens, underscores'));
    process.exit(1);
  }

  // 2. Description
  const description = await question('📝 Description (optional): ');

  // 3. Visibility
  console.log('🔒 Repository visibility:');
  console.log('  1) private (default)');
  console.log('  2) public');
  const visChoice = await question('Choose [1/2]: ');
  const visibility = visChoice === '2' ? '--public' : '--private';

  // 4. Project path (always ~/Desktop or current dir if specified)
  const parentDir = path.join(os.homedir(), 'Desktop');
  const projectPath = path.join(parentDir, projectName);
  if (fs.existsSync(projectPath)) {
    console.log(red(`❌ Directory already exists: ${projectPath}`));
    process.exit(1);
  }

  // Confirm
  console.log();
  console.log(yellow('Will create:'));
  console.log(`  Name: ${projectName}`);
  console.log(`  Path: ${projectPath}`);
  console.log(`  Visibility: ${visibility.replace('--', '')}`);
  if (description) console.log(`  Description: ${description}`);
  console.log();

  const confirm = await question('Continue? [Y/n]: ');
  if (confirm.toLowerCase() === 'n') {
    process.exit(0);
  }

  rl.close();

  // 5. Clone
  console.log(`\n${green('[1/5]')} Cloning claude-starter from GitHub...`);
  execSync(
    `git clone -q --depth 1 https://github.com/lindwerg/claude-starter.git "${projectPath}"`,
    { stdio: 'inherit' }
  );

  // 6. Init git
  console.log(`${green('[2/5]')} Initializing fresh git repo...`);
  process.chdir(projectPath);
  fs.rmSync('.git', { recursive: true, force: true });
  execSync('git init -q', { stdio: 'pipe' });
  execSync('git add .', { stdio: 'pipe' });
  execSync('git commit -q -m "init: bootstrap from claude-starter"', { stdio: 'pipe' });

  // 7. Create GitHub repo
  console.log(`${green('[3/5]')} Creating GitHub repository...`);
  const ghCmd = description
    ? `gh repo create "${projectName}" ${visibility} --source=. --push --description "${description}"`
    : `gh repo create "${projectName}" ${visibility} --source=. --push`;
  execSync(ghCmd, { stdio: 'inherit' });

  // 8. Done
  const ghUser = exec('gh api user -q .login').trim();
  console.log(`\n${green('[4/5]')} ✅ Project created successfully!`);
  console.log(`  📁 ${projectPath}`);
  console.log(`  🔗 https://github.com/${ghUser}/${projectName}`);

  // 9. Launch Claude
  console.log(`\n${green('[5/5]')} Starting Claude Code (bypass permissions mode)...`);
  console.log(yellow('Tip: Run /bmad:product-brief to start BMAD workflow'));
  console.log();

  const claude = spawn('claude', ['--dangerously-skip-permissions'], {
    stdio: 'inherit',
    cwd: projectPath,
  });

  claude.on('error', (err) => {
    console.log(red(`❌ Failed to start Claude: ${err.message}`));
    console.log(`Run manually: cd "${projectPath}" && claude`);
  });
}

main().catch((err) => {
  console.error(red(`Error: ${err.message}`));
  process.exit(1);
});
