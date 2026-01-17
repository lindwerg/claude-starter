# Claude Starter Kit Installer for Windows
# Installs skills, rules, hooks, commands, and agents to ~/.claude/

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

$REPO_URL = "https://github.com/kirill/claude-starter"
$CLAUDE_DIR = Join-Path $env:USERPROFILE ".claude"
$BACKUP_DIR = Join-Path $env:USERPROFILE ".claude-backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
$TEMP_DIR = $null

# Helper functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

# 1. Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."

    # Check Node.js
    try {
        $nodeVersion = node --version 2>$null
        Write-Info "Node.js $nodeVersion found"
    }
    catch {
        Write-Error "Node.js is required but not installed."
        Write-Host "Install from: https://nodejs.org/"
        exit 1
    }

    # Check Git
    try {
        $gitVersion = git --version 2>$null
        Write-Info "Git $($gitVersion -replace 'git version ', '') found"
    }
    catch {
        Write-Error "Git is required but not installed."
        Write-Host "Install from: https://git-scm.com/"
        exit 1
    }
}

# 2. Backup existing config
function Backup-Existing {
    if (Test-Path $CLAUDE_DIR) {
        Write-Info "Backing up existing ~/.claude to $BACKUP_DIR"
        Copy-Item -Path $CLAUDE_DIR -Destination $BACKUP_DIR -Recurse -Force

        $backupFile = Join-Path $env:USERPROFILE ".claude-starter-last-backup"
        Set-Content -Path $backupFile -Value $BACKUP_DIR

        Write-Info "Backup created: $BACKUP_DIR"
    }
    else {
        Write-Info "No existing ~/.claude directory found"
    }
}

# 3. Clone repo
function Clone-Repo {
    Write-Info "Cloning claude-starter repository..."

    $script:TEMP_DIR = Join-Path $env:TEMP "claude-starter-$(Get-Random)"
    New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

    try {
        git clone --depth 1 --recurse-submodules $REPO_URL "$TEMP_DIR\claude-starter" 2>$null
        Write-Info "Repository cloned successfully"
    }
    catch {
        Write-Error "Failed to clone repository from $REPO_URL"
        exit 1
    }
}

# 4. Install components
function Install-Components {
    Write-Info "Installing components..."

    # Create directories
    $directories = @("skills", "rules", "hooks", "commands", "agents", "templates", "scripts")
    foreach ($dir in $directories) {
        $path = Join-Path $CLAUDE_DIR $dir
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }

    # Copy components (don't overwrite existing files)
    $components = @("skills", "rules", "hooks", "commands", "agents")

    foreach ($component in $components) {
        $srcDir = Join-Path "$TEMP_DIR\claude-starter\.claude" $component
        $dstDir = Join-Path $CLAUDE_DIR $component

        if (Test-Path $srcDir) {
            $files = Get-ChildItem -Path $srcDir -ErrorAction SilentlyContinue
            $count = 0

            foreach ($file in $files) {
                $dstPath = Join-Path $dstDir $file.Name
                if (-not (Test-Path $dstPath)) {
                    Copy-Item -Path $file.FullName -Destination $dstDir -Recurse -Force
                    $count++
                }
            }

            Write-Info "Installed $count new $component"
        }
    }
}

# 5. Merge settings.json
function Merge-Settings {
    $srcSettings = Join-Path "$TEMP_DIR\claude-starter\.claude" "settings.json"
    $dstSettings = Join-Path $CLAUDE_DIR "settings.json"

    if (-not (Test-Path $srcSettings)) {
        Write-Warn "No settings.json in starter kit"
        return
    }

    if (Test-Path $dstSettings) {
        Write-Info "Merging settings.json..."

        try {
            $srcJson = Get-Content $srcSettings -Raw | ConvertFrom-Json
            $dstJson = Get-Content $dstSettings -Raw | ConvertFrom-Json

            # Simple merge: add missing keys from source
            $srcJson.PSObject.Properties | ForEach-Object {
                if (-not ($dstJson.PSObject.Properties.Name -contains $_.Name)) {
                    $dstJson | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value
                }
            }

            $dstJson | ConvertTo-Json -Depth 10 | Set-Content $dstSettings -Encoding UTF8
            Write-Info "Settings merged successfully"
        }
        catch {
            Write-Warn "Could not merge settings.json - existing file preserved"
        }
    }
    else {
        Copy-Item $srcSettings $dstSettings
        Write-Info "Settings installed"
    }
}

# 6. Merge mcp_config.json
function Merge-McpConfig {
    $srcMcp = Join-Path "$TEMP_DIR\claude-starter\.claude" "mcp_config.json"
    $dstMcp = Join-Path $CLAUDE_DIR "mcp_config.json"

    if (-not (Test-Path $srcMcp)) {
        Write-Warn "No mcp_config.json in starter kit"
        return
    }

    if (Test-Path $dstMcp) {
        Write-Info "Merging mcp_config.json..."

        try {
            $srcJson = Get-Content $srcMcp -Raw | ConvertFrom-Json
            $dstJson = Get-Content $dstMcp -Raw | ConvertFrom-Json

            # Merge mcpServers
            if ($srcJson.mcpServers -and $dstJson.mcpServers) {
                $srcJson.mcpServers.PSObject.Properties | ForEach-Object {
                    if (-not ($dstJson.mcpServers.PSObject.Properties.Name -contains $_.Name)) {
                        $dstJson.mcpServers | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value
                    }
                }
            }
            elseif ($srcJson.mcpServers -and -not $dstJson.mcpServers) {
                $dstJson | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value $srcJson.mcpServers
            }

            $dstJson | ConvertTo-Json -Depth 10 | Set-Content $dstMcp -Encoding UTF8
            Write-Info "MCP config merged successfully"
        }
        catch {
            Write-Warn "Could not merge mcp_config.json - existing file preserved"
        }
    }
    else {
        Copy-Item $srcMcp $dstMcp
        Write-Info "MCP config installed"
    }
}

# 7. Install templates and scripts
function Install-Templates {
    $srcTemplates = Join-Path "$TEMP_DIR\claude-starter" "templates"
    $srcScripts = Join-Path "$TEMP_DIR\claude-starter" "scripts"

    if (Test-Path $srcTemplates) {
        $files = Get-ChildItem -Path $srcTemplates -ErrorAction SilentlyContinue
        if ($files) {
            foreach ($file in $files) {
                $dstPath = Join-Path "$CLAUDE_DIR\templates" $file.Name
                if (-not (Test-Path $dstPath)) {
                    Copy-Item -Path $file.FullName -Destination "$CLAUDE_DIR\templates" -Recurse -Force
                }
            }
            Write-Info "Templates installed"
        }
    }

    if (Test-Path $srcScripts) {
        $files = Get-ChildItem -Path $srcScripts -ErrorAction SilentlyContinue
        if ($files) {
            foreach ($file in $files) {
                $dstPath = Join-Path "$CLAUDE_DIR\scripts" $file.Name
                if (-not (Test-Path $dstPath)) {
                    Copy-Item -Path $file.FullName -Destination "$CLAUDE_DIR\scripts" -Recurse -Force
                }
            }
            Write-Info "Scripts installed"
        }
    }
}

# 8. Install CLAUDE.md template
function Install-ClaudeMd {
    $srcClaudeMd = Join-Path "$TEMP_DIR\claude-starter" "CLAUDE.md"
    $dstClaudeMd = Join-Path $CLAUDE_DIR "CLAUDE.md"

    if ((Test-Path $srcClaudeMd) -and (-not (Test-Path $dstClaudeMd))) {
        Copy-Item $srcClaudeMd $dstClaudeMd
        Write-Info "CLAUDE.md template installed"
    }
    elseif (Test-Path $dstClaudeMd) {
        Write-Info "Existing CLAUDE.md preserved"
    }
}

# 9. Cleanup
function Remove-TempFiles {
    if ($script:TEMP_DIR -and (Test-Path $script:TEMP_DIR)) {
        Remove-Item -Path $script:TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
        Write-Info "Cleaned up temporary files"
    }
}

# Print banner
function Write-Banner {
    Write-Host ""
    Write-Host "  +---------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |     Claude Starter Kit Installer      |" -ForegroundColor Cyan
    Write-Host "  +---------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
}

# Print success message
function Write-Success {
    Write-Host ""
    Write-Host "  =========================================" -ForegroundColor Green
    Write-Host "    Installation complete!" -ForegroundColor Green
    Write-Host "  =========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Restart Claude Code to apply changes."
    Write-Host ""
    Write-Host "  Quick Start:"
    Write-Host "    mkdir my-app; cd my-app"
    Write-Host "    /init-project"
    Write-Host "    /workflow-init"
    Write-Host "    /ralph-loop"
    Write-Host ""
    Write-Host "  Installed to: $CLAUDE_DIR"

    $backupFile = Join-Path $env:USERPROFILE ".claude-starter-last-backup"
    if (Test-Path $backupFile) {
        Write-Host "  Backup at:    $(Get-Content $backupFile)"
    }
    Write-Host ""
}

# Main
function Main {
    try {
        Write-Banner
        Test-Prerequisites
        Backup-Existing
        Clone-Repo
        Install-Components
        Merge-Settings
        Merge-McpConfig
        Install-Templates
        Install-ClaudeMd
        Write-Success
    }
    finally {
        Remove-TempFiles
    }
}

Main
