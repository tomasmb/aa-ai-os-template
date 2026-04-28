# Alpha AI OS — one-line installer (Windows)
# Usage:
#   iwr https://raw.githubusercontent.com/tomasmb/aa-ai-os-template/main/scripts/install.ps1 -useb | iex
#
# Idempotent: safe to re-run. Hands off to scripts/bootstrap.ps1 once cloned.

$ErrorActionPreference = 'Stop'

$RepoUrl       = if ($env:ALPHA_REPO_URL) { $env:ALPHA_REPO_URL } else { 'https://github.com/tomasmb/aa-ai-os-template.git' }
$Root          = if ($env:ALPHA_ROOT)     { $env:ALPHA_ROOT }     else { Join-Path $HOME 'Alpha AI OS' }
$AssistantDir  = Join-Path $Root 'alpha-assistant'

function Say($msg)  { Write-Host "`n[alpha] $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Host "`n[alpha] $msg" -ForegroundColor Yellow }
function Die($msg)  { Write-Host "`n[alpha] $msg" -ForegroundColor Red; exit 1 }

function Confirm-Yes($prompt) {
    $a = Read-Host "$prompt [Y/n]"
    if ([string]::IsNullOrWhiteSpace($a)) { return $true }
    return $a -match '^[Yy]'
}

function Ensure-Tool {
    param([string]$Name, [string]$WingetId)
    if (Get-Command $Name -ErrorAction SilentlyContinue) { return }
    Say "Missing: $Name. Will install via winget ($WingetId)."
    if (-not (Confirm-Yes "Install $Name now?")) { Die "Cannot proceed without $Name." }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Die "winget not found. Install App Installer from the Microsoft Store, then re-run."
    }
    winget install --id $WingetId --silent --accept-package-agreements --accept-source-agreements
}

Say "Welcome to Alpha AI OS. This installer will:"
Say "  1. Install git + gh CLI if missing."
Say "  2. Create $Root\."
Say "  3. Clone the assistant folder."
Say "  4. Hand off to bootstrap (auth + brain clone + AI tool detection)."
if (-not (Confirm-Yes "Continue?")) { Die "Aborted." }

Ensure-Tool -Name 'git' -WingetId 'Git.Git'
Ensure-Tool -Name 'gh'  -WingetId 'GitHub.cli'

# Refresh PATH so newly installed tools are found in this session
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('Path','User')

if (-not (Test-Path $Root)) { New-Item -ItemType Directory -Path $Root | Out-Null }

if (Test-Path (Join-Path $AssistantDir '.git')) {
    Say "Assistant folder already exists at $AssistantDir — pulling latest."
    git -C $AssistantDir pull --rebase --autostash | Out-Host
} else {
    Say "Cloning assistant into $AssistantDir."
    git clone $RepoUrl $AssistantDir | Out-Host
}

Say "Handing off to bootstrap."
$bootstrap = Join-Path $AssistantDir 'scripts\bootstrap.ps1'
if (-not (Test-Path $bootstrap)) { Die "bootstrap.ps1 missing — repo state is bad." }
& powershell -NoProfile -ExecutionPolicy Bypass -File $bootstrap
