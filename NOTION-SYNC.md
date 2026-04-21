# NOTION-SYNC.md — Where I read from and write to in Notion

> Notion is the shared company brain. This file tells the assistant which pages
> to read (to feed itself) and which inbox sections to write to (to feed the
> company). The assistant fills in the specific page URLs during first-run setup
> by asking the user.

## Organization

- **Company hub page (root of shared brain):**
  <!-- e.g. "Alpha AI OS — V1" page URL. Filled during setup. -->

- **Onboarding modules page:**
- **Packs library page:**
- **Promotion Rules page:** <!-- Read-only reference for the AI Contract §9 -->

## Read sources (the AI pulls from these to seed its understanding)

| Source | What's there | Refresh cadence |
|---|---|---|
| Company primer | Mission, values, how we work, glossary | Monthly |
| Team primer | Who's on the team, projects, rituals | Monthly |
| Role primer | What this role does, success metrics | On role change |
| Relevant project pages | Active initiatives the user is on | Weekly |

## Write targets (where auto-promotes land as inbox entries)

| Scope | Target page | Inbox section title |
|---|---|---|
| **Project** | the specific project page | `## Assistant Updates` |
| **Team** | the team's hub page | `## Assistant Updates` |
| **Org** | org-wide policy / glossary / norms | `## Assistant Updates` |

**Rule:** the assistant NEVER auto-writes outside the `## Assistant Updates`
section. Creating a new Notion page requires explicit user consent (Contract §9).

## Update manifest (for self-updates)

- **Repository:** `https://github.com/tomasmb/aa-ai-os-template`
- **Release manifest URL:** `https://github.com/tomasmb/aa-ai-os-template/releases/latest`
- **Check cadence:** once per 24h
- **Channel:** `stable` (change to `beta` for early access)

## Owners of truth (for conflict resolution)

- If SOUL / CONTRACT / PROMOTION-RULES disagree with a Notion page, the **folder
  wins** (those are shipped as protected files).
- If company / team / role primers disagree with local memory, the **Notion page
  wins** (the org is the source of truth for org knowledge).
