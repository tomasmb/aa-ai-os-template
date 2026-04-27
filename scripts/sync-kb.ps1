# Alpha AI OS — sync-kb (Contract Rules 16 + 2, Windows)

$ErrorActionPreference = 'Continue'

$AssistantDir     = Split-Path -Parent $PSScriptRoot
$KbLocFile        = Join-Path $AssistantDir 'memory\kb-location.md'
$KbStatusFile     = Join-Path $AssistantDir 'memory\kb-status.md'
$LastSessionFile  = Join-Path $AssistantDir 'memory\last-session.md'
$LogFile          = Join-Path $AssistantDir 'logs\session-log.md'

if (Test-Path $KbStatusFile) {
    if ((Get-Content $KbStatusFile -Raw) -match '^status:\s*pending') {
        Write-Host "[sync-kb] KB pending; skipping."
        exit 0
    }
}

if (-not (Test-Path $KbLocFile)) {
    Write-Error "[sync-kb] KB not configured. Run scripts\bootstrap.ps1."; exit 1
}
$KbDir = (Get-Content $KbLocFile -Raw).Trim()
if (-not (Test-Path (Join-Path $KbDir '.git'))) {
    Write-Error "[sync-kb] KB at '$KbDir' is not a repo."; exit 1
}

$oldHead = git -C $KbDir rev-parse HEAD 2>$null

$pullErr = Join-Path $env:TEMP 'alpha-sync.err'
git -C $KbDir pull --rebase --autostash 2>$pullErr
if ($LASTEXITCODE -ne 0) {
    Write-Host "[sync-kb] pull failed. See CONFLICT-PLAYBOOK.md."
    Get-Content $pullErr | Write-Error
    git -C $KbDir rebase --abort 2>$null | Out-Null
    exit 2
}

$newHead = git -C $KbDir rev-parse HEAD
New-Item -ItemType Directory -Force -Path (Join-Path $AssistantDir 'memory') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $AssistantDir 'logs')   | Out-Null

if ($oldHead -ne $newHead) {
    $count = git -C $KbDir rev-list --count "$oldHead..$newHead"
    Write-Host "[sync-kb] $count new commit(s) since last sync."
    Write-Host ""
    Write-Host "## Recent KB changes"
    git -C $KbDir log --oneline --no-decorate "$oldHead..$newHead" -- core/ archive/ inbox/ `
        | Select-Object -First 20 | Out-Host
    $now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    Add-Content -Path $LogFile -Value "$now sync-kb pulled $count commits ($oldHead..$newHead)"
}

(Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') | Set-Content -Path $LastSessionFile -NoNewline
exit 0
