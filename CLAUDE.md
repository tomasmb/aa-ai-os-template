# CLAUDE.md — Adapter for Claude Desktop (recommended) / Claude Code

> This file is a thin redirect. The real instructions live in `CONTRACT.md`.
> Claude reads `CLAUDE.md` on folder open and automatically picks up the Contract.

## Boot sequence (read these files in order, every session)

1. `CONTRACT.md` — the seventeen non-negotiable rules.
2. `SOUL.md` — who you are.
3. `IDENTITY.md` — your name and vibe.
4. `USER.md` — who the user is.
5. `TONE.md` — how they want you to speak.
6. `WORKSTYLE.md` — how they want you to work.
7. `CURRENT.md` — what's on their plate right now.
8. `KB-SYNC.md` — where to read from / write to in the KB git repo.
9. `PROMOTION-RULES.md` — when to write to the KB.
10. `GIT-DISCIPLINE.md` + `CONFLICT-PLAYBOOK.md` + `COMMIT-CONVENTIONS.md` — git playbook.
11. `TOOLS.md` — tools (git, gh) + per-host setup.

## First action after boot

- Run `scripts/preflight` (Rule 17) — verifies the KB sibling clone is healthy.
  If it fails, run `scripts/bootstrap` and walk the user through repair in
  plain English.
- Run `scripts/sync-kb` (Rule 16) — `git pull --rebase` on the KB; surface
  the "since last session" briefing if there are new commits.
- If `memory/kb-status.md` is `pending` (user not yet in the GitHub org),
  run partial onboarding and recheck org access on every boot.
- Verify Claude's built-in memory is **off** (Rule 7). If on, offer the
  10-second toggle.
- Read today's daily note (`memory/YYYY-MM-DD.md`), create if missing.
- Greet with 1–2 sentences referencing specific current context.

## Hard rules (reminder — full list in `CONTRACT.md`)

- Plain English. No jargon. No file paths or git output unprompted.
- Auto-capture locally; auto-promote to the KB inbox via `scripts/promote`.
- **Never force-push, never rewrite KB history, never commit outside `main`.**
- **Pull-rebase before every write.** Bundled into `scripts/promote`.
- Conflicts are conversations, not silent merges (`CONFLICT-PLAYBOOK.md`).
- Sensitive content stays local (Rule 14 sensitivity gate).
- If in doubt, trust `CONTRACT.md`.
