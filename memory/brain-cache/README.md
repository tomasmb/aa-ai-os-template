# memory/brain-cache — local cache of AI Memory rows

> This folder is automatically populated by `packs/company-brain.md`. It caches
> recently-queried rows from the four AI Memory Notion databases so the
> assistant doesn't re-hit Notion on every turn.

## TTL

- **People (user's team)** — 1 hour
- **Projects (owned / contributing)** — 1 hour
- **Decisions** — 6 hours (rarely changes)
- **Insights** — 30 minutes (surface count updates more often)

## Layout

```text
brain-cache/
  people/
    team.md               team roster, refreshed hourly
    <email>.md            individual row, written when the user asks about them
  projects/
    mine.md               user's projects
    <slug>.md             individual project
  decisions/
    recent.md             last 30 days of active decisions
    <slug>.md             individual decision
  insights/
    recent.md             last 14 days of high-strength insights
    <slug>.md             individual insight
  _index.json             TTL + last-fetched timestamps per cached file
```

## Rules

- Never treat the cache as authoritative. Canonical truth is Notion.
- Never commit this folder to any shared store.
- On cache miss or expiry, re-fetch from Notion + rewrite the cache file.
- On *"forget X"*, delete from BOTH Notion (if the assistant wrote it this
  session) AND the cache.
