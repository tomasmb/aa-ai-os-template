# memory/brain-cache — local cache of AI Memory rows

> This folder is automatically populated by `packs/company-brain.md`. It
> caches recently-queried rows from the AI Memory Notion databases so the
> assistant doesn't re-hit Notion on every turn.

## Two namespaces (the bi-level model)

The cache mirrors the Notion model: lean Core rows get short TTLs and
eager warm-up; heavy/permissioned Archive rows get long TTLs and lazy
fetch. Some Archive DBs never cache at all.

```text
brain-cache/
  core/                      lean entity rows, refreshed eagerly
    people/
      team.md                team roster, refreshed hourly
      <email>.md             individual row, written on query
    projects/
      mine.md                user's projects
      <slug>.md              individual project
    decisions/
      recent.md              last 30 days of active decisions
      <slug>.md              individual decision
    insights/
      recent.md              last 14 days of high-strength insights
      <slug>.md              individual insight
    meetings/
      recent.md              last 7 days for the user's attendees
      <id>.md                individual meeting
    goals/
      current-period.md      active period's goals for user + team
      <id>.md                individual goal
  archive/                   reference material, refreshed lazily
    playbooks/
      <slug>.md              pointer-only; never contains SOP body
    glossary/
      all.md                 whole DB (hard-capped ~100 rows)
    # NOTE: no students/ namespace — Students rows are never cached.
  _index.json                TTL + last-fetched timestamps per cached file
```

## TTLs

### Core (short — refreshed often)

- **People (user's team)** — 1 hour
- **Projects (owned / contributing)** — 1 hour
- **Decisions** — 6 hours (rarely changes once made)
- **Insights** — 30 minutes (surface count updates more often)
- **Meetings** — 2 hours (recent meetings queried for prep and rituals)
- **Goals** — 6 hours (status transitions matter, but not by the minute)

### Archive (long — refreshed rarely)

- **Playbooks** — 24 hours (pointer index, low churn)
- **Glossary** — 24 hours
- **Students / Families** — **never cached locally.** Permission-gated
  content does not leave Notion's access-control boundary, and caching it
  in `memory/` would bypass the sensitivity model. Every read goes
  live to Notion.

## Rules

- Never treat the cache as authoritative. Canonical truth is Notion.
- Never commit this folder to any shared store.
- On cache miss or expiry, re-fetch from Notion + rewrite the cache file.
- On *"forget X"*, delete from BOTH Notion (if the assistant wrote it this
  session) AND the cache.
- **Archive rows are fetched only on demand** — either because a Core
  relation traversed into them, or because the user explicitly asked.
  Never eagerly warm Archive on boot (except Glossary, which is small
  enough to pull whole).
- **Students / Families is never written here.** If a write sneaks into
  `archive/students/`, treat it as a bug: delete the file and log to
  `logs/session-log.md`.
- Permission-denied Archive reads produce **no cache entry** and **no
  retry**. The absence of a cache file is the correct state.
