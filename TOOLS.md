# TOOLS.md — Tools the assistant relies on, plus per-host setup

> The assistant reads this file at every session start to verify tool availability.
> If a required tool is missing, walk the user through setup in plain English.
> Never show this file to the user directly.

## Required tools

- **git** — read + write the KB repo and this assistant repo. Mandatory.
- **gh CLI** — GitHub authentication + repo access. Mandatory for first-run
  bootstrap; the daily flow can use cached credentials after that.

Both are installed by `scripts/install` per OS (Homebrew, apt/dnf/pacman,
winget). Detail in `setup/macos.md`, `setup/linux.md`, `setup/windows.md`.

The KB read path is purely local (`rg` over the sibling clone). The KB write
path is `scripts/promote`, which wraps `git pull --rebase → write → commit
→ push` atomically.

## Recommended (optional) MCPs — unlock specific packs

These are **not required**. The brain works without them. They unlock
specific packs:

- **Google Calendar MCP** — unlocks `packs/company-scheduling.md`. Strongly
  recommended for new hires (day-1 scheduling is the highest-leverage use).
- **Google Mail MCP** (optional) — enables richer invite bodies and follow-up
  detection.
- **GitHub MCP** (optional) — useful for engineers linking PRs into Insights.
  The assistant does NOT need this MCP for KB git operations — it uses the
  `git` CLI directly.

## Not required — email digest uses the user's default mail client

The weekly owner digest (Contract §15 / `packs/company-rituals.md`) is
**email-only** and requires **no MCP**. The assistant composes the digest
locally, opens a pre-filled `mailto:` link, the user hits send. Power users
can opt into SMTP via `digests.smtp_enabled` in `WORKSTYLE.md` — still no MCP.

**Slack MCP, Teams MCP, Google Chat MCP are not used by v2.0.0.** The folder
stays lean. If Alpha later builds a Slack digest path, it ships as an opt-in
pack — never a requirement.

## Git + gh CLI setup by host

Setup is run once by `scripts/install` and `scripts/bootstrap`. The assistant
verifies on every boot via `scripts/preflight`. Manual steps below are only
for users who skipped the installer.

### Claude Desktop (recommended)

Claude Desktop doesn't run shell commands itself. The user runs the one-line
installer in their Terminal/PowerShell **once**:

- macOS / Linux: `curl -fsSL https://raw.githubusercontent.com/tomasmb/aa-ai-os-template/main/scripts/install.sh | bash`
- Windows: `iwr https://raw.githubusercontent.com/tomasmb/aa-ai-os-template/main/scripts/install.ps1 -useb | iex`

Then they open `~/Alpha AI OS/alpha-assistant` as a Claude Desktop project.
The assistant invokes `scripts/preflight` and `scripts/sync-kb` as part of
its boot sequence (Rules 17 + 16) by reading the script outputs through the
filesystem tool. If `scripts/preflight` reports missing tools or auth, the
assistant tells the user the one-line command to run in their shell.

### Cursor

Same one-line installer as Claude Desktop. Cursor opens the
`~/Alpha AI OS/alpha-assistant` folder. The assistant runs scripts via
Cursor's built-in shell when the user asks (Cursor exposes shell exec).

### Claude Code (CLI)

`cd ~/Alpha\ AI\ OS/alpha-assistant && claude` after the one-line installer.
Claude Code runs the scripts directly via its shell tool.

### Codex CLI

`cd ~/Alpha\ AI\ OS/alpha-assistant && codex` after the one-line installer.
Same shell-exec story.

### openclaw

The one-line installer is run in a regular Terminal. openclaw then opens
the assistant folder. Scripts run via openclaw's shell tool.

## GitHub authentication

`scripts/bootstrap` runs `gh auth login --web` once. After auth:

- `gh api user` captures the user's GitHub username + primary email.
- `git config --global user.name` / `user.email` are set if unset.
- `gh repo clone tomasmb/alpha-anywhere-kb` lands the KB sibling.
- On 403/404 (not in org yet), `memory/kb-status.md` = `pending` and the
  assistant runs partial onboarding until access lands.

## Google Calendar MCP setup by host (optional)

Only triggered when `packs/company-scheduling.md` activates (e.g. *"schedule
a 1-1 with X"*). Never nag otherwise.

### Claude Desktop

1. Settings → Connectors. Search "Google Calendar". Install.
2. Approve OAuth in browser with the user's `@2hourlearning.com` account.
3. Grant **read free/busy** + **create events** scopes only.
4. Restart Claude Desktop once.

### Cursor / Claude Code / Codex CLI

Standard MCP server config. Use a community Google Calendar MCP. Approve OAuth.
Reload host.

### openclaw

Configured via the workspace plugin manager. Confirm availability.

### Required OAuth scopes

- `https://www.googleapis.com/auth/calendar.freebusy` — read free/busy.
- `https://www.googleapis.com/auth/calendar.events` — create / update events
  the assistant authors.

**Not requested:** reading event contents (titles, descriptions, attendees of
other people's events).

## Ritual scheduling by host (Contract §15)

See `rituals/README.md` for full setup.

| Host | Native scheduling | Fallback |
|---|---|---|
| Claude Desktop | Scheduled Tasks (native) | Session-open trigger |
| Cursor | — | Session-open trigger only |
| Claude Code | OS (launchd / cron / Task Scheduler) | Session-open trigger |
| Codex CLI | OS (launchd / cron / Task Scheduler) | Session-open trigger |
| openclaw | OS (launchd / cron / Task Scheduler) | Session-open trigger |

Setup runs once during onboarding Block 7.5. Generated from
`rituals/launchd/*.template`, `rituals/cron/*.template`, or
`rituals/windows/*.template`. No admin rights required.

**Graceful fallback:** rituals fire on the next session open past their
configured time even without a scheduler.

## Host memory — turn it OFF

The assistant runs on this folder's memory + the KB. A second memory system
(Claude's built-in, Cursor's memory, etc.) creates conflicts.

### Claude Desktop
Settings → Memory → toggle **off**. ~10 seconds.

### Claude Code / Claude.ai
Same Memory toggle in account settings.

### Cursor
Settings → Features → Memory → toggle **off**.

### Codex CLI / openclaw
No built-in memory. Nothing to disable.

## Failure policy

- **git missing or `scripts/preflight` red** → stop and walk the user through
  `scripts/install` (or the manual fallback for their OS) before proceeding.
- **gh auth missing** → walk the user through `gh auth login --web`.
- **KB clone missing or 403/404** → write `memory/kb-status.md` = `pending`,
  run partial onboarding, recheck on every boot.
- **Recommended MCP missing** (Google Calendar) → proceed silently. Mention
  only when a triggering pack activates. Never nag.
- Never fabricate a response when a required tool is unreachable. Say so plainly.
