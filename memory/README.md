# memory/ — What the assistant remembers

> Private, local, editable only by the user and the assistant. Never
> transmitted outside the machine except through explicit user action or
> Notion auto-promotes that match Contract §9.

## File layout

| File | What's in it | Owner |
|---|---|---|
| `YYYY-MM-DD.md` | Daily note — what happened, what was said, what was decided | Assistant (appended live) |
| `current-status.md` | 1-page always-current snapshot of user's state | Assistant (kept in sync with CURRENT.md) |
| `decisions.md` | Durable decisions with context, date, who, why | Assistant |
| `relationships.md` | People the user works with + role + recurring context | Assistant |
| `recurring-work.md` | Patterns the assistant noticed (weekly reports, recurring blockers) | Assistant |
| `learnings.md` | Post-mortems, things learned from outcomes | Assistant |
| `tombstones.md` | Things the user asked to forget + date | Assistant |
| `templates/` | Templates the assistant reuses for its own writing | Alpha / team |

## How the assistant uses this folder

- On session start → reads `current-status.md` + today's daily note.
- During session → silently appends captures per Contract §4.
- On recall questions → searches across relevant files and cites origin.
- On `/forget X` → deletes + tombstones per Contract §11.

## Backups

Full backup written to `.backups/pre-update-<date>.tar.gz` before any `/update`.
