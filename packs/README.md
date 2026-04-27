# packs/ — Optional capability packs

> Packs add focused skills to the assistant. Drop one in, the next session
> recognizes it automatically. Remove it, the assistant forgets that skill.

## How packs work

- Each pack is a single markdown file.
- The assistant reads every `*.md` file in this directory at session start.
- Each pack declares: what it does, when to use it, and any specific prompts /
  checklists the assistant should follow.

## Pack types

| Type | Owner | Filename pattern |
|---|---|---|
| **Company-wide** | Alpha central | `company-*.md` — protected; daily git pull updates them |
| **Team** | team lead | `team-<team-name>.md` — gitignored; user-editable |
| **Personal** | the user | `personal-*.md` — gitignored; user-editable |

## Getting more packs

New packs ship with each release of `aa-ai-os-template`. The morning ritual
runs `git pull --rebase` daily, so `company-*.md` packs stay current
automatically. Team and personal packs are gitignored, so updates never touch
them.

## Recommended first packs

- `company-brain.md` — **the shared knowledge graph** (Contract §14). Share-
  by-default writes to the KB's `core/` and `archive/` folders via
  `scripts/promote`. Every other pack that surfaces facts routes through
  here. **Ships by default. Foundational.**
- `company-brain-seed.md` — **one-time bulk seed** of the brain (maintainer
  run; not invoked per-user). Ships by default. Foundational.
- `company-rituals.md` — **the proactive rhythm** (Contract §15). Morning
  check-in (runs `scripts/sync-kb`), end-of-day wrap, weekly review + email
  owner digest. **Ships by default. Foundational.**
- `company-writing.md` — Alpha's writing voice + structure. **Ships by default.**
- `company-meetings.md` — meeting prep + post-meeting ingest. Writes
  Decisions + Insights to the brain. **Ships by default.**
- `company-scheduling.md` — 1-1 and meeting scheduling via Google Calendar
  MCP. Updates `core/people/<slug>.md` rows on scheduled 1-1s. **Ships by
  default.** Unlocks once the user connects Google Calendar MCP.
- `team-<your-team>.md` — team-specific rituals and workflows. Build your
  own or ask the maintainer to ship a shared one in the next release.
- `personal-custom.md` — anything you want the assistant to always do your way.

## Which packs need extra MCPs

| Pack | Extra MCP needed | Behavior if MCP missing |
|---|---|---|
| `company-brain.md` | None — uses `git` + `scripts/promote` directly | Pending KB access → personal-only mode (per Rule 17) |
| `company-brain-seed.md` | None | Maintainer-run only; not invoked by per-user sessions |
| `company-rituals.md` | None — scheduling via OS schedulers; email via `mailto:` | Graceful fallback: rituals fire on next session open past schedule |
| `company-writing.md` | None | Works out of the box |
| `company-meetings.md` | None (paste-based) | Works on pasted notes; queues KB writes if KB unreachable |
| `company-scheduling.md` | **Google Calendar MCP** | Assistant offers setup on first trigger |

## Removing a pack

Say "drop the <pack> pack" and the assistant moves the file to
`.backups/packs-removed/<date>/` so it can be restored later.
