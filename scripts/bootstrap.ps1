# Alpha AI OS — bootstrap (Windows)
# Mirror of scripts/bootstrap.sh. Idempotent.

$ErrorActionPreference = 'Stop'

$AssistantDir = Split-Path -Parent $PSScriptRoot
$Root         = Split-Path -Parent $AssistantDir
$KbRepo       = if ($env:ALPHA_KB_REPO) { $env:ALPHA_KB_REPO } else { 'alphaanywhere/alpha-anywhere-kb' }
$KbDir        = Join-Path $Root 'alpha-anywhere-kb'

New-Item -ItemType Directory -Force -Path (Join-Path $AssistantDir 'memory') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $AssistantDir 'logs')   | Out-Null

function Say($msg)  { Write-Host "`n[alpha] $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Host "`n[alpha] $msg" -ForegroundColor Yellow }
function Die($msg)  { Write-Host "`n[alpha] $msg" -ForegroundColor Red; exit 1 }

# Windows-friendly git defaults: keep CRLF on checkout, LF on commit
git config --global core.autocrlf input | Out-Null

# 1. GitHub auth
function Ensure-Auth {
    $status = & gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        $login = (gh api user --jq '.login')
        Say "GitHub auth: ok ($login)."
        return
    }
    Say "Signing you into GitHub. A browser window will open."
    gh auth login --web -h github.com -p https
}

# 2. Git identity
function Ensure-GitIdentity {
    $name  = (gh api user --jq '.name // .login')
    $email = (gh api user/emails --jq 'map(select(.primary==true))[0].email // empty' 2>$null)
    if (-not $email) { $email = (gh api user --jq '.email // empty') }
    if (-not (git config --global user.name)) {
        Say "Setting git user.name = $name"
        git config --global user.name $name
    }
    if (-not (git config --global user.email) -and $email) {
        Say "Setting git user.email = $email"
        git config --global user.email $email
    }
    $ghUser = (gh api user --jq '.login')
    Set-Content -Path (Join-Path $AssistantDir 'memory\gh-username.md') -Value $ghUser -NoNewline
}

# 3. KB clone
function Clone-Kb {
    $kbLoc    = Join-Path $AssistantDir 'memory\kb-location.md'
    $kbStatus = Join-Path $AssistantDir 'memory\kb-status.md'

    if (Test-Path (Join-Path $KbDir '.git')) {
        Say "KB already cloned at $KbDir."
        Set-Content -Path $kbLoc -Value $KbDir -NoNewline
        if (Test-Path $kbStatus) { Remove-Item $kbStatus -Force }
        return
    }

    Say "Cloning the company brain ($KbRepo)."
    $errFile = Join-Path $env:TEMP 'alpha-kb-clone.err'
    & gh repo clone $KbRepo $KbDir 2>$errFile
    if ($LASTEXITCODE -eq 0) {
        Set-Content -Path $kbLoc -Value $KbDir -NoNewline
        if (Test-Path $kbStatus) { Remove-Item $kbStatus -Force }
        Say "Brain ready at $KbDir."
        return
    }

    $errText = Get-Content $errFile -Raw -ErrorAction SilentlyContinue
    if ($errText -match '(404|not found|403|forbidden|permission denied)') {
        $ghUser = (gh api user --jq '.login')
        $now    = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        @"
status: pending
github_username: $ghUser
checked_at: $now
admin_contact: see docs/ADMIN-GUIDE.md
note: |
  GitHub doesn't let me read $KbRepo yet. Send your GH username ($ghUser) to
  the admin so they can add you to the org. The assistant will keep working in
  personal-only mode until access lands and will recheck on every session boot.
"@ | Set-Content -Path $kbStatus
        Warn "Brain access pending. Continuing in personal-only mode."
        return
    }
    Warn "KB clone failed: $errText"
    Warn "You can re-run bootstrap later: scripts\bootstrap.ps1"
}

# 4. Editable templates
function Copy-Templates {
    Say "Initializing editable files from templates (first run only)."
    $count = 0
    Get-ChildItem -Path $AssistantDir -Recurse -Filter '*.template' -File `
        | Where-Object { $_.FullName -notmatch '\\(\.git|node_modules)\\' } `
        | ForEach-Object {
            $live = $_.FullName -replace '\.template$',''
            if (-not (Test-Path $live)) {
                Copy-Item -Path $_.FullName -Destination $live
                $count++
            }
        }
    Say "Copied $count template(s) to live editable files."
}

# 5. AI tool detection
function Detect-AiTool {
    Say "Detecting which AI tool you have installed."
    $found = $null

    $claudeDesktop = Test-Path "$env:LOCALAPPDATA\AnthropicClaude\Claude.exe"
    if (-not $claudeDesktop) {
        $claudeDesktop = Test-Path "$env:PROGRAMFILES\Claude\Claude.exe"
    }
    if ($claudeDesktop) { $found = 'claude-desktop' }
    elseif (Get-Command claude -ErrorAction SilentlyContinue) { $found = 'claude-code' }
    elseif (Test-Path "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe" -or `
            (Get-Command cursor -ErrorAction SilentlyContinue)) { $found = 'cursor' }
    elseif (Get-Command codex -ErrorAction SilentlyContinue) { $found = 'codex' }
    elseif (Get-Command openclaw -ErrorAction SilentlyContinue) { $found = 'openclaw' }

    switch ($found) {
        'claude-desktop' {
            Say "Found: Claude Desktop (recommended)."
            Write-Host @"

Open Claude Desktop and add a new project pointing at:

  $AssistantDir

Then say "hi" — your assistant will load the Contract and walk you through setup.
"@
        }
        'claude-code' { Say "Found: Claude Code."; Write-Host "  cd '$AssistantDir' ; claude" }
        'cursor'      {
            Say "Found: Cursor."
            Write-Host @"

Open Cursor → File → Open Folder → select:

  $AssistantDir

Then say "hi" — your assistant will load the Contract and walk you through setup.
"@
        }
        'codex'    { Say "Found: Codex CLI.";  Write-Host "  cd '$AssistantDir' ; codex" }
        'openclaw' { Say "Found: openclaw.";  Write-Host "  Point openclaw at $AssistantDir" }
        default {
            Warn "No supported AI tool detected. Install one (Claude Desktop recommended):"
            Write-Host @"

  1. Claude Desktop (recommended): https://claude.ai/download
  2. Cursor:                       https://cursor.com
  3. Claude Code (CLI):            npm install -g @anthropic-ai/claude-code
  4. Codex CLI:                    npm install -g @openai/codex
  5. openclaw:                     ask your admin

After installing, open the folder above and say "hi" to your assistant.
"@
        }
    }
}

Say "Bootstrap starting."
Ensure-Auth
Ensure-GitIdentity
Clone-Kb
Copy-Templates
Detect-AiTool
Say "Bootstrap complete."
if (Test-Path (Join-Path $AssistantDir 'memory\kb-status.md')) {
    Warn "Brain access is pending. The assistant will run in personal-only mode."
}
