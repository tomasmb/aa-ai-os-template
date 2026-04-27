# Alpha AI OS — sync-assistant (Windows)
# Mirror of scripts/sync-assistant.sh.

$ErrorActionPreference = 'Continue'

$AssistantDir = Split-Path -Parent $PSScriptRoot
$LogFile      = Join-Path $AssistantDir 'logs\session-log.md'

if (-not (Test-Path (Join-Path $AssistantDir '.git'))) {
    Write-Host "[sync-assistant] $AssistantDir is not a git repo; skipping."
    exit 0
}

$OldHead = (git -C $AssistantDir rev-parse HEAD 2>$null)

$errFile = Join-Path $env:TEMP 'alpha-sync-assistant.err'
& git -C $AssistantDir pull --rebase --autostash 2>$errFile
if ($LASTEXITCODE -ne 0) {
    Write-Host "[sync-assistant] pull failed. See CONFLICT-PLAYBOOK.md." -ForegroundColor Yellow
    Get-Content $errFile -ErrorAction SilentlyContinue | Write-Host
    & git -C $AssistantDir rebase --abort 2>$null | Out-Null
    exit 2
}

$NewHead = (git -C $AssistantDir rev-parse HEAD)
New-Item -ItemType Directory -Force -Path (Join-Path $AssistantDir 'logs') | Out-Null

if ($OldHead -ne $NewHead) {
    $nCommits = (git -C $AssistantDir rev-list --count "$OldHead..$NewHead")
    Write-Host "[sync-assistant] $nCommits new commit(s) on the assistant repo."
    git -C $AssistantDir log --oneline --no-decorate "$OldHead..$NewHead" | Select-Object -First 10
    $now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    Add-Content -Path $LogFile -Value "$now sync-assistant pulled $nCommits commits ($OldHead..$NewHead)"
}

exit 0
