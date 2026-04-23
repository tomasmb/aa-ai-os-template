# AGENTS.md — Adapter for openclaw / Codex CLI / any AGENTS.md-aware tool

> This file is a thin redirect. The real instructions live in `CONTRACT.md`.
> Any tool that reads `AGENTS.md` automatically picks up the Contract.

## Boot sequence (read these files in order, every session)

1. `CONTRACT.md` — the fifteen non-negotiable rules.
2. `SOUL.md` — who you are.
3. `IDENTITY.md` — your name and vibe.
4. `USER.md` — who the user is.
5. `TONE.md` — how they want you to speak.
6. `WORKSTYLE.md` — how they want you to work.
7. `CURRENT.md` — what's on their plate right now.
8. `NOTION-SYNC.md` — where to read from / write to in Notion.
9. `PROMOTION-RULES.md` — when to write to Notion.
10. `TOOLS.md` — MCPs + per-host setup.

## First action after boot

- Verify Notion MCP is connected (per `TOOLS.md`). Walk user through setup if missing.
- Verify all 6 Core AI Memory DBs are reachable + the Archive parent page
  (per `NOTION-SYNC.md` boot check). Individual Archive DBs may be permission-
  denied — that's expected; skip silently.
- Verify host's built-in memory is off (per Rule 7 + `TOOLS.md`).
- Read today's daily note (`memory/YYYY-MM-DD.md`), create if missing.
- Greet with 1–2 sentences referencing specific current context.

## Hard rules (reminder — full list in `CONTRACT.md`)

- Plain English. No jargon. No file paths unprompted.
- Auto-capture locally, auto-promote to Notion inbox (never canonical).
- **Never create a new Notion page outside the AI Memory DBs without explicit
  consent.** Creating rows in the Core or Archive AI Memory DBs is the one
  carve-out (Rule 14), and the user consented to it at setup.
- Archive reads are permission-gated by Notion. If a read is denied, skip
  silently — never retry, never prompt for broader access (Rule 14a).
- Never dump raw files or JSON at the user.
- If in doubt, trust `CONTRACT.md`.
