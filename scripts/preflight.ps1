# Alpha AI OS — preflight (Contract Rule 17, Windows)

$ErrorActionPreference = 'Continue'

$AssistantDir   = Split-Path -Parent $PSScriptRoot
$KbLocFile      = Join-Path $AssistantDir 'memory\kb-location.md'
$KbStatusFile   = Join-Path $AssistantDir 'memory\kb-status.md'
$KbExpectedRepo = if ($env:ALPHA_KB_REPO) { $env:ALPHA_KB_REPO } else { 'alphaanywhere/alpha-anywhere-kb' }

function Red($m)   { Write-Host $m -ForegroundColor Red }
function Yel($m)   { Write-Host $m -ForegroundColor Yellow }
function Grn($m)   { Write-Host $m -ForegroundColor Green }
function Fail($m)  { Red "preflight: FAIL — $m"; exit 1 }

if (Test-Path $KbStatusFile) {
    if ((Get-Content $KbStatusFile -Raw) -match '^status:\s*pending') {
        Yel "preflight: KB access pending — running partial mode."
        exit 0
    }
}

if (-not (Test-Path $KbLocFile)) { Fail "memory\kb-location.md missing — run scripts\bootstrap.ps1" }
$KbDir = (Get-Content $KbLocFile -Raw).Trim()
if (-not (Test-Path $KbDir))               { Fail "KB path '$KbDir' does not exist — run scripts\bootstrap.ps1" }
if (-not (Test-Path (Join-Path $KbDir '.git'))) { Fail "KB path '$KbDir' is not a git repo" }

$diff       = git -C $KbDir diff --quiet; $exit1 = $LASTEXITCODE
$diffCached = git -C $KbDir diff --cached --quiet; $exit2 = $LASTEXITCODE
if ($exit1 -ne 0 -or $exit2 -ne 0) { Fail "KB working tree is dirty — see CONFLICT-PLAYBOOK.md Scenario 8" }

$branch = git -C $KbDir rev-parse --abbrev-ref HEAD
if ($branch -ne 'main') { Fail "KB on branch '$branch', expected main" }

$origin = git -C $KbDir config --get remote.origin.url
if ($origin -notlike "*$KbExpectedRepo*") { Fail "KB origin '$origin' does not match expected '$KbExpectedRepo'" }

if (-not (git config --global user.name))  { Fail "git config user.name not set — run scripts\bootstrap.ps1" }
if (-not (git config --global user.email)) { Fail "git config user.email not set — run scripts\bootstrap.ps1" }

Grn "preflight: OK ($KbDir on main, identity set)."
exit 0
