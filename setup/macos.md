# Setup — macOS

You'll need a GitHub account that the admin can add as a collaborator
organization. Bring your username — that's all.

## The fast way (recommended)

Open **Terminal** and paste:

```bash
curl -fsSL https://raw.githubusercontent.com/tomasmb/aa-ai-os-template/main/scripts/install.sh | bash
```

What this does:

1. Installs **Homebrew** if missing (the script will prompt you).
2. Installs **git** and **gh** (GitHub CLI) via Homebrew.
3. Creates `~/Alpha AI OS/`.
4. Clones the assistant folder into `~/Alpha AI OS/alpha-assistant/`.
5. Hands off to `scripts/bootstrap.sh`, which:
   - Signs you into GitHub via your browser (`gh auth login --web`).
   - Sets your git name + email if unset.
   - Clones the company brain. If you're not yet in the org, it parks the
     assistant in **personal-only mode** until access lands.
   - Detects your AI tool (Claude Desktop / Cursor / Claude Code / Codex CLI /
     openclaw) and tells you exactly what to open next.

When the script finishes, follow the printed instruction to open the folder
in your AI tool. You're done.

## After install — open it in Claude Desktop (recommended)

1. Make sure you have Claude Desktop installed (https://claude.ai/download).
2. Open Claude Desktop → click "+ New Project" (or use the project dropdown).
3. Click "Add files" → choose **"Add folder"** → select `~/Alpha AI OS/alpha-assistant`.
4. Open a chat in that project and say "hi". The assistant will load its
   Contract and walk you through a short conversational setup.

## The manual way (only if you skipped the installer)

Open Terminal:

```bash
# 1. Install Homebrew if missing
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install git + gh CLI
brew install git gh

# 3. Make the workspace
mkdir -p "$HOME/Alpha AI OS"
cd "$HOME/Alpha AI OS"

# 4. Clone the assistant
git clone https://github.com/tomasmb/aa-ai-os-template.git alpha-assistant

# 5. Run the bootstrap
bash alpha-assistant/scripts/bootstrap.sh
```

## Re-running the installer

The installer is **idempotent** — re-running it pulls the latest assistant
code and re-runs bootstrap. Safe to use any time.

## Troubleshooting

### "command not found: gh"

Your shell's PATH didn't pick up the new Homebrew install. Restart Terminal
or run:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple Silicon
eval "$(/usr/local/bin/brew shellenv)"      # Intel
```

### "gh auth login" opens a code page but never completes

Copy the one-time code, paste it into the browser tab, and approve. If the
browser doesn't open automatically, the terminal also prints the URL — paste
it manually.

### "Could not resolve host: github.com"

Check your network. If you're on a corporate VPN, ensure GitHub is reachable.
The assistant queues writes to `logs/pending-writes.md` while offline and
replays them on the next morning ritual.

### "remote: Repository not found" when cloning the brain

You're authenticated but Tomas hasn't added you as a collaborator on the KB yet. The bootstrap
writes `memory/kb-status.md = pending` and tells you which GitHub username
to send to the admin. Personal-only mode is fine until access lands.

### "Permission denied (publickey)" when pushing

`gh auth login` should have set up HTTPS auth. Re-run:

```bash
gh auth refresh -h github.com -s repo
```

If the issue persists, run `gh auth status` to inspect.

### I want to move the folder

Move both `alpha-assistant/` and `alpha-anywhere-kb/` to a new parent dir
**together** (they must remain siblings). Then update
`alpha-assistant/memory/kb-location.md` to the new absolute path or just
re-run `scripts/bootstrap.sh`.
