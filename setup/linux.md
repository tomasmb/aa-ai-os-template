# Setup — Linux

You'll need a GitHub account that the admin can add as a collaborator
organization. Bring your username — that's all.

## The fast way (recommended)

Open a terminal and paste:

```bash
curl -fsSL https://raw.githubusercontent.com/tomasmb/aa-ai-os-template/main/scripts/install.sh | bash
```

What this does:

1. Detects your package manager (`apt`, `dnf`, or `pacman`).
2. Installs **git** and **gh** (GitHub CLI). On Debian/Ubuntu it adds the
   official GitHub apt repo first.
3. Creates `~/Alpha AI OS/`.
4. Clones the assistant folder there.
5. Hands off to `scripts/bootstrap.sh` (auth + brain clone + AI tool
   detection — see `macos.md` for the same flow detail).

## After install — open it in Claude Desktop (recommended)

1. Install Claude Desktop (https://claude.ai/download).
2. Add a new project → add folder → select `~/Alpha AI OS/alpha-assistant`.
3. Say "hi" in a chat. The assistant takes it from there.

## Manual install — Debian / Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y git curl

# GitHub CLI repo (one-time)
type -p curl >/dev/null || sudo apt-get install -y curl
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
sudo apt-get update
sudo apt-get install -y gh

# Workspace
mkdir -p "$HOME/Alpha AI OS"
cd "$HOME/Alpha AI OS"
git clone https://github.com/tomasmb/aa-ai-os-template.git alpha-assistant
bash alpha-assistant/scripts/bootstrap.sh
```

## Manual install — Fedora / RHEL

```bash
sudo dnf install -y git gh
mkdir -p "$HOME/Alpha AI OS"
cd "$HOME/Alpha AI OS"
git clone https://github.com/tomasmb/aa-ai-os-template.git alpha-assistant
bash alpha-assistant/scripts/bootstrap.sh
```

## Manual install — Arch / Manjaro

```bash
sudo pacman -S --needed git github-cli
mkdir -p "$HOME/Alpha AI OS"
cd "$HOME/Alpha AI OS"
git clone https://github.com/tomasmb/aa-ai-os-template.git alpha-assistant
bash alpha-assistant/scripts/bootstrap.sh
```

## Re-running the installer

Idempotent. Safe to re-run any time. Pulls latest assistant code and re-runs
bootstrap.

## Troubleshooting

### "no supported package manager found"

The installer supports `brew`, `apt`, `dnf`, `pacman`. Other distros need a
manual install (above). Once `git` and `gh` are on PATH, run
`bash scripts/bootstrap.sh` directly.

### "gh: command not found" right after install

Open a new terminal so PATH is refreshed, then `which gh` should show it.

### "gh auth login" hangs

Copy the one-time code from the terminal, paste it into the browser tab, and
approve. The assistant doesn't need a different auth flow.

### "remote: Repository not found" cloning the brain

You're not in the org yet. Bootstrap writes `memory/kb-status.md = pending`
and tells you which GitHub username to send to the admin. The assistant runs
in personal-only mode until access lands.

### Browser doesn't open during `gh auth login --web`

Some headless or remote sessions can't pop a browser. Use device-flow mode
manually:

```bash
gh auth login --hostname github.com --git-protocol https
```

Pick "Login with a web browser" and copy/paste the code into a browser on a
machine that has one.

### Moving the folder

Move both `alpha-assistant/` and `alpha-anywhere-kb/` to a new parent dir
**together**. Re-run `scripts/bootstrap.sh` afterwards to update
`memory/kb-location.md`.
