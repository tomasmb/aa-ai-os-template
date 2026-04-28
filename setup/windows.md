# Setup — Windows

You'll need a GitHub account that the admin can add as a collaborator
organization. Bring your username — that's all.

## The fast way (recommended)

Open **PowerShell** (Start Menu → search "PowerShell") and paste:

```powershell
iwr https://raw.githubusercontent.com/tomasmb/aa-ai-os-template/main/scripts/install.ps1 -useb | iex
```

What this does:

1. Uses **winget** to install **Git for Windows** and **GitHub CLI** if missing.
2. Creates `%USERPROFILE%\Alpha AI OS\`.
3. Clones the assistant folder there.
4. Hands off to `scripts/bootstrap.ps1`, which:
   - Sets `core.autocrlf=input` (avoids Windows line-ending churn in the KB).
   - Signs you into GitHub via your browser (`gh auth login --web`).
   - Sets your git name + email if unset.
   - Clones the company brain. If you're not yet in the org, it parks the
     assistant in **personal-only mode** until access lands.
   - Detects your AI tool and tells you what to open next.

## After install — open it in Claude Desktop (recommended)

1. Install Claude Desktop (https://claude.ai/download).
2. Open Claude Desktop → New Project → Add folder → choose
   `%USERPROFILE%\Alpha AI OS\alpha-assistant` (you can also paste the path).
3. Say "hi" in a chat. The assistant takes it from there.

## The manual way (only if you skipped the installer)

```powershell
# 1. Install winget if missing — search "App Installer" in Microsoft Store.

# 2. Install git + gh CLI
winget install --id Git.Git       --silent --accept-package-agreements --accept-source-agreements
winget install --id GitHub.cli    --silent --accept-package-agreements --accept-source-agreements

# 3. Restart PowerShell so PATH picks up the new tools, then:
$root = Join-Path $HOME 'Alpha AI OS'
New-Item -ItemType Directory -Force -Path $root | Out-Null
Set-Location $root
git clone https://github.com/tomasmb/aa-ai-os-template.git alpha-assistant
& powershell -ExecutionPolicy Bypass -File alpha-assistant\scripts\bootstrap.ps1
```

## Re-running the installer

Idempotent. Safe to re-run any time.

## Troubleshooting

### "running scripts is disabled on this system"

Run PowerShell with execution policy bypass for the install line:

```powershell
powershell -ExecutionPolicy Bypass -Command "iwr https://raw.githubusercontent.com/tomasmb/aa-ai-os-template/main/scripts/install.ps1 -useb | iex"
```

### "winget is not recognized"

Install **App Installer** from the Microsoft Store. Restart PowerShell. Try again.

### "gh: command not found" right after install

Close and re-open PowerShell so PATH refreshes, or run:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('Path','User')
```

### "gh auth login" never completes

Copy the one-time code, paste it into the browser tab that opens, and approve.

### "remote: Repository not found" when cloning the brain

You're not in the org yet. Bootstrap creates `memory\kb-status.md = pending`
with your GitHub username — send it to the admin. Personal-only mode works
fine until access lands; the assistant rechecks every session boot.

### Line-ending warnings when committing to the KB

`bootstrap.ps1` sets `core.autocrlf=input` which avoids these. If you see
them anyway, run:

```powershell
git config --global core.autocrlf input
```

### I want to move the folder

Move both `alpha-assistant\` and `alpha-anywhere-kb\` to a new parent dir
**together**. Re-run `scripts\bootstrap.ps1` to update
`memory\kb-location.md`.
