# Alpha AI OS — promote (Windows mirror of promote.sh)
# Usage: see scripts/promote.sh header.
#
# Body is read from stdin (e.g. cat body.md | powershell -File promote.ps1 inbox people jane-doe).

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('inbox','entity','forget')]
    [string]$Subcommand,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

$ErrorActionPreference = 'Stop'

$AssistantDir = Split-Path -Parent $PSScriptRoot
$KbLocFile    = Join-Path $AssistantDir 'memory\kb-location.md'
$KbStatusFile = Join-Path $AssistantDir 'memory\kb-status.md'
$PendingFile  = Join-Path $AssistantDir 'logs\pending-writes.md'
$GhUserFile   = Join-Path $AssistantDir 'memory\gh-username.md'

function Die($m) { Write-Error "[promote] $m"; exit 1 }

# Pending mode → queue + bail
if (Test-Path $KbStatusFile) {
    if ((Get-Content $KbStatusFile -Raw) -match '^status:\s*pending') {
        New-Item -ItemType Directory -Force -Path (Split-Path $PendingFile) | Out-Null
        $body = if ([Console]::IsInputRedirected) { [Console]::In.ReadToEnd() } else { '' }
        $now  = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        @"
---
queued_at: $now
argv: $Subcommand $($Rest -join ' ')
stdin:
$body
---
"@ | Add-Content -Path $PendingFile
        Write-Host "[promote] KB pending — queued."
        exit 0
    }
}

if (-not (Test-Path $KbLocFile)) { Die "KB not configured; run scripts\bootstrap.ps1" }
$KbDir = (Get-Content $KbLocFile -Raw).Trim()

$UserSlug = if (Test-Path $GhUserFile) { (Get-Content $GhUserFile -Raw).Trim() } else { 'unknown' }

# Parse remaining args
$Pos        = New-Object System.Collections.ArrayList
$TargetPath = ''
$Source     = 'conversation'
$Confidence = 'medium'
$Message    = ''
$Type       = 'promote'
$Push       = $true
$DryRun     = $false

for ($i = 0; $i -lt $Rest.Count; $i++) {
    switch ($Rest[$i]) {
        '--target-path' { $TargetPath = $Rest[++$i] }
        '--source'      { $Source     = $Rest[++$i] }
        '--confidence'  { $Confidence = $Rest[++$i] }
        '--message'     { $Message    = $Rest[++$i] }
        '--user'        { $UserSlug   = $Rest[++$i] }
        '--type'        { $Type       = $Rest[++$i] }
        '--no-push'     { $Push       = $false }
        '--dry-run'     { $DryRun     = $true }
        default         { [void]$Pos.Add($Rest[$i]) }
    }
}

function Run-Git {
    param([string[]]$Args)
    if ($DryRun) { Write-Host "+ git $($Args -join ' ')"; return 0 }
    & git -C $KbDir @Args
    return $LASTEXITCODE
}

function Pull-Rebase {
    $errFile = Join-Path $env:TEMP 'alpha-promote.err'
    git -C $KbDir pull --rebase --autostash 2>$errFile
    if ($LASTEXITCODE -ne 0) {
        git -C $KbDir rebase --abort 2>$null | Out-Null
        Write-Error "[promote] pull --rebase failed. See CONFLICT-PLAYBOOK.md."
        Get-Content $errFile | Write-Error
        return $false
    }
    return $true
}

function Push-OrQueue {
    if (-not $Push) { return $true }
    $errFile = Join-Path $env:TEMP 'alpha-promote-push.err'
    git -C $KbDir push 2>$errFile
    if ($LASTEXITCODE -eq 0) { return $true }
    Write-Error "[promote] push failed; queueing."
    New-Item -ItemType Directory -Force -Path (Split-Path $PendingFile) | Out-Null
    $now  = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $head = git -C $KbDir rev-parse HEAD
    $err  = (Get-Content $errFile -Raw) -replace "`r?`n",' '
    @"
---
queued_at: $now
reason: push_failed
kb_head: $head
stderr: $err
---
"@ | Add-Content -Path $PendingFile
    return $false
}

function Read-Body {
    if ([Console]::IsInputRedirected) { return [Console]::In.ReadToEnd() }
    return ''
}

switch ($Subcommand) {
    'inbox' {
        if ($Pos.Count -lt 2) { Die "inbox: missing <entity-type> <slug>" }
        $entity = $Pos[0]; $slug = $Pos[1]
        if ($entity -notin @('people','projects','meetings','goals','decisions','insights')) {
            Die "inbox: invalid entity-type '$entity'"
        }
        if (-not $Message) { $Message = "surface $($entity.TrimEnd('s')) update from $Source" }
        $body = Read-Body
        if (-not $body) { Die "inbox: empty body on stdin" }

        $ts   = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH-mm-ss')
        $iso  = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        $rel  = "inbox/${ts}_${entity}_${slug}.md"
        $abs  = Join-Path $KbDir $rel

        if (-not (Pull-Rebase)) { exit 1 }
        $front = "---`npromoted_by: $UserSlug`npromoted_at: $iso`ntarget_entity: $entity`n"
        if ($TargetPath) { $front += "target_path: $TargetPath`n" }
        $front += "source: $Source`nconfidence: $Confidence`n---`n`n"
        New-Item -ItemType Directory -Force -Path (Split-Path $abs) | Out-Null
        Set-Content -Path $abs -Value ($front + $body) -NoNewline

        Run-Git @('add', $rel) | Out-Null
        $msg = "promote($entity): $Message`n`nPromoted-By: $UserSlug`nSource: $Source`nConfidence: $Confidence"
        Run-Git @('commit', '-m', $msg) | Out-Null
        if (-not (Push-OrQueue)) { exit 2 }
        Write-Host $rel
    }

    'entity' {
        if ($Pos.Count -lt 1) { Die "entity: missing <relative-path>" }
        $rel = $Pos[0]
        if (-not $Message) { Die "entity: --message required" }
        $body = Read-Body
        if (-not $body) { Die "entity: empty body on stdin" }
        $scope = ($rel -split '/')[0]
        if ($scope -notin @('core','archive','inbox','operating-framework')) {
            Die "entity: top-level dir '$scope' not allowed"
        }
        $abs = Join-Path $KbDir $rel
        if (-not (Pull-Rebase)) { exit 1 }
        New-Item -ItemType Directory -Force -Path (Split-Path $abs) | Out-Null
        Set-Content -Path $abs -Value $body -NoNewline
        Run-Git @('add', $rel) | Out-Null
        $entityScope = ($rel -split '/')[1]
        if (-not $entityScope) { $entityScope = $scope }
        $msg = "$Type($entityScope): $Message`n`nPromoted-By: $UserSlug`nSource: $Source`nConfidence: $Confidence"
        Run-Git @('commit', '-m', $msg) | Out-Null
        if (-not (Push-OrQueue)) { exit 2 }
        Write-Host $rel
    }

    'forget' {
        if ($Pos.Count -lt 1) { Die "forget: missing <relative-path>" }
        $rel = $Pos[0]
        if (-not $Message) { $Message = "remove entry per user request" }
        if (-not (Pull-Rebase)) { exit 1 }
        $abs = Join-Path $KbDir $rel
        if (-not (Test-Path $abs)) { Die "forget: '$rel' not found in KB" }
        Run-Git @('rm', $rel) | Out-Null
        $entityScope = ($rel -split '/')[1]; if (-not $entityScope) { $entityScope = 'inbox' }
        $msg = "forget($entityScope): $Message`n`nPromoted-By: $UserSlug`nSource: manual`nConfidence: high"
        Run-Git @('commit', '-m', $msg) | Out-Null
        if (-not (Push-OrQueue)) { exit 2 }
        Write-Host $rel
    }
}
