# rituals/ — Scheduled proactive behavior

> Per-host setup for the three rituals defined in `packs/company-rituals.md`:
> morning check-in, end-of-day wrap, weekly review. Each ritual is a tiny
> shell command that wakes the user's assistant at the scheduled time.
>
> **You don't need to read this file.** The assistant walks you through
> setup during onboarding (Block 7.5). This is the reference it uses.

## The goal

At the scheduled time, trigger the user's assistant with a ritual tag
(`morning`, `eod`, or `weekly`). The assistant opens, reads the tag, and
runs the corresponding ritual flow from `packs/company-rituals.md`.

## Host support matrix

| Host | Native scheduler | How it runs |
|---|---|---|
| **Claude Desktop** | ✅ yes (Scheduled Tasks) | Uses Claude's built-in scheduler; each ritual is a saved task. |
| **openclaw (CLI)** | 🔶 via OS | Triggered by OS scheduler (launchd / cron / Task Scheduler). |
| **Claude Code (CLI)** | 🔶 via OS | Same as openclaw. |
| **Codex CLI** | 🔶 via OS | Same. |
| **Cursor** | ❌ no native scheduler | **Graceful fallback only:** ritual fires on next session open past its scheduled time. |

For hosts without native scheduling, the OS does the work. For Cursor and
anything else in that bucket, the assistant checks `memory/rituals-log.md`
at session start — if a scheduled ritual didn't fire, it runs it now.

## Graceful fallback (works on every host, zero setup)

Even with no scheduling configured, rituals still fire:

- **Session opens between 07:00 and `morning_time + 4h`** → if no morning
  ritual fired today, run it now.
- **Session opens after `eod_time` but before midnight** → if no EOD ritual
  fired today, run it now.
- **First session of the week after Friday `weekly_time`** → if no weekly
  fired this week, run it now.

This is implemented in `packs/company-rituals.md` (the check happens as part
of the session-start context load, Contract §2). **Users who skip host
setup still get rituals; they just get them a little later.**

## Setup — macOS (launchd)

User-level launchd agents run in the user's login session. No sudo.

1. Copy `launchd/com.alpha.assistant.morning.plist.template` to
   `~/Library/LaunchAgents/com.alpha.assistant.morning.plist` and edit:
   - `<AI_OS_FOLDER>` → the absolute path to this folder on the user's machine.
   - `<HH>` / `<MM>` → user's configured `morning_time`.
2. Repeat for `eod` and `weekly` templates.
3. Load each with `launchctl load ~/Library/LaunchAgents/<file>.plist`.
4. Verify with `launchctl list | grep com.alpha.assistant`.

The assistant generates the correct plists + runs the `launchctl load`
commands on the user's behalf during onboarding. The user confirms with one
*"yes"*.

## Setup — Linux (cron)

1. Read `cron/crontab.template`.
2. Run `crontab -l` to get the current crontab, append the three ritual
   lines (one per ritual, with times substituted), pipe back to `crontab -`.
3. Verify with `crontab -l`.

Same pattern: assistant generates and installs automatically.

## Setup — Windows (Task Scheduler)

1. Use `windows/install-rituals.ps1.template` — PowerShell script that
   registers three scheduled tasks via `Register-ScheduledTask`.
2. User runs it once (right-click → Run with PowerShell).
3. Verify in Task Scheduler UI under `Task Scheduler Library → AlphaAssistant`.

## Setup — Claude Desktop (scheduled tasks)

Claude has its own task scheduling. The assistant creates three tasks:

1. *"Morning check-in"* — recurs weekdays at `morning_time`. Opens the AI OS
   folder with the `morning` ritual tag.
2. *"End-of-day wrap"* — recurs weekdays at `eod_time`.
3. *"Weekly review"* — recurs Fridays at `weekly_time`.

The assistant guides the user through creating them via Claude's settings
UI the first time. Once set, Claude's scheduler handles the rest.

## How the trigger command works

Every ritual trigger does the same thing: launches the user's default tool
with a message that starts with `/ritual morning` (or `/ritual eod`,
`/ritual weekly`). The assistant recognizes the tag at session start and
runs the corresponding ritual.

### Example trigger command (macOS / Linux shell)

```bash
# Opens Claude Desktop with the ritual message pre-filled
# Adapt per tool (openclaw, claude-code, codex, etc.)
open -a "Claude" --args --message "/ritual morning"
```

### Example (Claude Desktop Scheduled Task)

Task content: `/ritual morning — run the morning check-in for <AI_OS_FOLDER>`

### Example (windows PowerShell)

```powershell
Start-Process "claude.exe" -ArgumentList '--message "/ritual morning"'
```

The assistant writes the correct command per host during setup.

## What `/ritual <name>` does at session start

The assistant recognizes the tag and:

1. Skips the standard greeting (Rule 2 step 5).
2. Skips the interactive personalization loop.
3. Executes the named ritual flow from `packs/company-rituals.md`.
4. Logs the outcome to `memory/rituals-log.md`.
5. Returns control — either the user engages with the offer, or the session
   closes cleanly.

## Logs

Every fired ritual writes one line to `memory/rituals-log.md`:

```text
<YYYY-MM-DD HH:MM> morning fired | offer=<action> | accepted=<y/n>
<YYYY-MM-DD HH:MM> eod fired     | offer=<action> | accepted=<y/n>
<YYYY-MM-DD HH:MM> weekly fired  | offer=<action> | accepted=<y/n>
```

The assistant reads this log to:
- Detect missed rituals (graceful fallback).
- Measure engagement (success criterion tracking).
- Show the user their own engagement history if asked.

## Disabling rituals

Per-ritual: *"stop morning check-ins"* → sets
`rituals.morning_enabled = false` in `WORKSTYLE.md`; the scheduled job
still fires but exits silently.

All rituals: *"pause rituals"* → `rituals.enabled = false`; every ritual
exits at the first check.

Full removal: the assistant generates the corresponding uninstall commands
(`launchctl unload`, `crontab -e`, Task Scheduler delete, Claude task
delete) on request.

## Files in this folder

```text
rituals/
  README.md                                    this file
  launchd/
    com.alpha.assistant.morning.plist.template   macOS morning
    com.alpha.assistant.eod.plist.template       macOS EOD
    com.alpha.assistant.weekly.plist.template    macOS weekly
  cron/
    crontab.template                             Linux cron entries
  windows/
    install-rituals.ps1.template                 Windows Task Scheduler
```

Templates use placeholders: `<AI_OS_FOLDER>`, `<HH>`, `<MM>`, `<USER_EMAIL>`.
The assistant fills these in per-user before writing the final files.
