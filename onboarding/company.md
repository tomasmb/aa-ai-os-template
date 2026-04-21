# onboarding/company.md — Alpha Anywhere context cache

> The assistant reads Alpha's canonical Notion pages and caches a summary here
> so it has company context in every session without re-fetching. Edit the
> Notion pages, not this file — the local copy refreshes automatically.

## Canonical sources in Notion

| Page | What it tells you | Notion URL |
|---|---|---|
| **Operating Framework** | How Alpha works — decision norms, rituals, operating cadence | https://www.notion.so/2892901d79088097b23ff06dbb41b4dc |
| **Team directory** | Who works at Alpha, their roles, what they own | https://www.notion.so/2892901d790880c0a0e9d5594c29861d |
| **👋 New Hire Onboarding** (database) | Per-employee onboarding cards. Used for new hires only. | https://www.notion.so/2922901d7908802ab4d6d0b79fb15722 |
| **Alpha AI OS — V1** (hub) | This assistant's user-facing documentation hub | https://www.notion.so/3492901d790881df80e3fbfefd7e7b70 |

## What gets cached here after first session

After the first real session, this file holds a compact summary the assistant
maintains itself:

### Mission (one paragraph, from Operating Framework)
*(filled automatically)*

### How Alpha decides (from Operating Framework)
*(filled automatically)*

### Rituals + cadences (from Operating Framework)
*(filled automatically)*

### Glossary — abbreviations & internal terms
*(filled automatically — growable as the user encounters new terms)*

### Who's who — leaders + scope (from Team directory)
*(filled automatically — top-of-funnel only, full list in Notion)*

## Refresh cadence

- **On every session start:** check if the Operating Framework page's last
  edited time is newer than this file's cache timestamp. If yes, re-sync.
- **On demand:** user says *"refresh Alpha context"* → re-sync all four
  sources above.
- **Monthly:** full re-sync regardless.

## Last synced

*(auto — timestamp written after each successful sync)*
