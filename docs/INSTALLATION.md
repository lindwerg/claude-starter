# Installation Guide

Detailed instructions for installing Claude Starter Kit.

---

## Prerequisites

### Required Software

| Software | Version | Check Command | Install |
|----------|---------|---------------|---------|
| Node.js | >= 18.x | `node --version` | [nodejs.org](https://nodejs.org/) |
| Git | >= 2.x | `git --version` | [git-scm.com](https://git-scm.com/) |
| Claude Code | latest | `claude --version` | [claude.ai](https://claude.ai/claude-code) |

### Optional Software

| Software | Version | Purpose |
|----------|---------|---------|
| Docker | >= 24.x | Local development environment |
| jq | >= 1.6 | Smart settings merging |
| pnpm | >= 8.x | Package manager (installed if missing) |

### Install Prerequisites

**macOS (Homebrew):**

```bash
# Node.js
brew install node@18

# Git (usually pre-installed)
brew install git

# Docker Desktop
brew install --cask docker

# jq (optional, for smart merging)
brew install jq

# pnpm
npm install -g pnpm
```

**Ubuntu/Debian:**

```bash
# Node.js (via NodeSource)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Git
sudo apt-get install -y git

# Docker
sudo apt-get install -y docker.io docker-compose-plugin

# jq
sudo apt-get install -y jq

# pnpm
npm install -g pnpm
```

**Windows:**

```powershell
# Using Chocolatey
choco install nodejs-lts git docker-desktop jq

# Or using winget
winget install OpenJS.NodeJS.LTS Git.Git Docker.DockerDesktop jqlang.jq
```

---

## Step-by-Step Installation

### Step 1: Download and Run Installer

**One-line install (recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/kirill/claude-starter/main/install.sh | bash
```

**Or clone and run manually:**

```bash
git clone https://github.com/kirill/claude-starter.git
cd claude-starter
./install.sh
```

### Step 2: Installer Actions

The installer performs these actions:

1. **Checks prerequisites** - Verifies Node.js and Git are installed
2. **Backs up existing config** - Creates `~/.claude-backup-<timestamp>/`
3. **Clones repository** - Downloads latest version to temp directory
4. **Installs components** - Copies skills, rules, hooks, agents to `~/.claude/`
5. **Merges settings** - Preserves your existing settings (requires jq)
6. **Merges MCP config** - Preserves your existing MCP servers
7. **Installs templates** - Copies project templates
8. **Cleans up** - Removes temporary files

### Step 3: Restart Claude Code

After installation, restart Claude Code to load new settings:

```bash
# If running in terminal
# Press Ctrl+C to stop, then restart
claude
```

---

## Post-Installation Verification

### Verify Installation

```bash
# Check skills directory
ls -la ~/.claude/skills/

# Expected output:
# bmad/
# ralph-loop/
# vsa-fsd/
# testing-modern/

# Check agents directory
ls -la ~/.claude/agents/

# Expected output:
# api-agent.md
# backend-agent.md
# frontend-agent.md
# test-agent.md
# devops-agent.md
# validation-agent.md

# Check hooks are executable
ls -la ~/.claude/hooks/*.sh
```

### Test Skills

In Claude Code, try running:

```
/init-project --help
```

If skills are loaded correctly, you should see help output.

### Check Settings

```bash
cat ~/.claude/settings.json | jq '.hooks'
```

Should show registered hooks for auto-format, type-check, etc.

---

## Troubleshooting

### Installation Fails: "Node.js not found"

```bash
# Check if Node.js is installed
which node
node --version

# If not found, install via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc  # or ~/.zshrc
nvm install 18
nvm use 18
```

### Installation Fails: "Git not found"

```bash
# macOS
xcode-select --install

# Or install via Homebrew
brew install git
```

### Settings Not Merged (jq missing)

If jq is not installed, the installer preserves your existing settings instead of merging:

```bash
# Install jq
# macOS
brew install jq

# Ubuntu
sudo apt-get install jq

# Then re-run installer
./install.sh
```

### Skills Not Loading After Install

1. **Restart Claude Code** - Required for new settings

2. **Check settings.json syntax:**
   ```bash
   cat ~/.claude/settings.json | jq .
   # If error, fix JSON syntax
   ```

3. **Verify skill files exist:**
   ```bash
   ls ~/.claude/skills/*/SKILL.md
   ```

### Hooks Not Running

1. **Make hooks executable:**
   ```bash
   chmod +x ~/.claude/hooks/*.sh
   ```

2. **Test hook manually:**
   ```bash
   echo '{}' | ~/.claude/hooks/auto-format.sh
   ```

3. **Check hook registration:**
   ```bash
   cat ~/.claude/settings.json | jq '.hooks'
   ```

### Restore from Backup

If something goes wrong:

```bash
# Find backup
ls -la ~/.claude-backup-*

# Restore
rm -rf ~/.claude
cp -r ~/.claude-backup-<timestamp> ~/.claude
```

---

## Upgrading

### Upgrade to Latest Version

```bash
# If you cloned the repo
cd claude-starter
git pull origin main
./install.sh
```

**Or re-run one-liner:**

```bash
curl -fsSL https://raw.githubusercontent.com/kirill/claude-starter/main/install.sh | bash
```

### What Gets Updated

- New skills added (existing preserved)
- New rules added (existing preserved)
- New hooks added (existing preserved)
- Settings merged (your settings take precedence)
- MCP config merged (your servers preserved)

### Force Full Reinstall

To completely replace your config:

```bash
# Backup current config
cp -r ~/.claude ~/.claude-manual-backup

# Remove existing
rm -rf ~/.claude

# Fresh install
curl -fsSL https://raw.githubusercontent.com/kirill/claude-starter/main/install.sh | bash
```

---

## Uninstalling

### Run Uninstaller

```bash
cd claude-starter
./uninstall.sh
```

### Manual Uninstall

```bash
# Remove installed components
rm -rf ~/.claude/skills/bmad
rm -rf ~/.claude/skills/ralph-loop
rm -rf ~/.claude/skills/vsa-fsd
rm -rf ~/.claude/skills/testing-modern
rm -rf ~/.claude/agents
rm ~/.claude/hooks/auto-format.sh
rm ~/.claude/hooks/typescript-preflight.sh
rm ~/.claude/hooks/check-tests-pass.sh
rm ~/.claude/hooks/vsa-validate.sh

# Or remove everything (caution!)
rm -rf ~/.claude
```

### Restore Original Config

```bash
# List backups
ls ~/.claude-backup-*

# Restore
cp -r ~/.claude-backup-<timestamp>/* ~/.claude/
```

---

## Platform-Specific Notes

### macOS

- Docker Desktop required for local development
- Rosetta 2 may be needed on Apple Silicon for some packages

### Linux

- Ensure Docker daemon is running: `sudo systemctl start docker`
- Add user to docker group: `sudo usermod -aG docker $USER`

### Windows

- Use WSL2 for best compatibility
- Docker Desktop with WSL2 backend recommended
- PowerShell installer available: `install.ps1`

### WSL (Windows Subsystem for Linux)

```bash
# Install in WSL, not Windows
curl -fsSL https://raw.githubusercontent.com/kirill/claude-starter/main/install.sh | bash

# Claude Code should be run from WSL
```

---

## Next Steps

After installation:

1. **Create your first project:**
   ```bash
   mkdir my-app && cd my-app
   /init-project
   ```

2. **Read the workflow guide:** [WORKFLOW.md](./WORKFLOW.md)

3. **Learn about agents:** [AGENTS.md](./AGENTS.md)
