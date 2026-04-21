# NOTION-SYNC.md — Where I read from and write to in Notion

> Notion is the shared company brain. This file tells the assistant which pages
> to read (to feed itself) and which inbox sections to write to (to feed the
> company). URLs marked with 🔒 are **hardcoded** — they're part of the shipped
> template and should not be edited by the user.

## 🔒 Canonical Alpha pages (hardcoded — same for every employee)

| Purpose | Notion URL |
|---|---|
| **Alpha AI OS — V1** (this assistant's hub + docs) | https://www.notion.so/3492901d790881df80e3fbfefd7e7b70 |
| **Operating Framework** (how Alpha works) | https://www.notion.so/2892901d79088097b23ff06dbb41b4dc |
| **Team directory** (who works here) | https://www.notion.so/2892901d790880c0a0e9d5594c29861d |
| **👋 New Hire Onboarding** (database) | https://www.notion.so/2922901d7908802ab4d6d0b79fb15722 |
| **Onboarding Modules** (primer index) | https://www.notion.so/3492901d7908811d9d49db4f8f6e1dd7 |
| **Packs Library** (optional pack catalogue) | https://www.notion.so/3492901d790881beb88fc5681b3ceb4a |
| **Promotion Rules** (reference for Contract §9) | https://www.notion.so/3492901d790881b4bc7ffe7c08891da3 |
| **Governance & Versioning** | https://www.notion.so/3492901d79088150aab3ebf136bb046e |

## 🔒 AI Memory databases (Contract §14 — shared brain)

Read + write under `packs/company-brain.md`. Natural keys per DB are enforced
to prevent duplicates. Provenance is mandatory on every write.

| Database | URL | Natural key | Primary relations |
|---|---|---|---|
| **👤 People** | https://www.notion.so/6b06c4411b9448beb21e14f4df69fa8b | `Email` | — (target of Projects.Owner, Decisions.Owner, Insights.Related people) |
| **🚀 Projects** | https://www.notion.so/b23db3243d4146bf85e60ede57dca759 | normalized `Name` | `Owner` → People, `Contributors` → People |
| **✅ Decisions** | https://www.notion.so/c19786631d3d41448dac8dc56b195604 | `Title` + `Decided on` | `Owner` / `Participants` → People, `Related projects` → Projects |
| **💡 Insights** | https://www.notion.so/73815567aaa94aea90fb1d9678f80f14 | fuzzy `Title` + ≥2 tag overlap | `Related people` → People, `Related projects` → Projects, `Related decisions` → Decisions |

**Parent page** (hub within the AI OS Notion): https://www.notion.so/3492901d790881adb05df812f2aa4131

**Boot check:** verify all 4 DBs are reachable at session start. If any is
missing, stop and walk the user through permissions (their Notion integration
must have access to the `🧠 AI Memory` page). See `packs/company-brain.md`.

## Per-user pages (discovered at first run)

These are resolved by looking the user up in Notion during setup.

- **User's onboarding card** (only if new hire): looked up in the `👋 New Hire
  Onboarding` database by `Email Address` or `Name`. URL cached to `USER.md`.
- **User's team page**: looked up in the Team directory by the team name the
  user gives. URL cached to `onboarding/team.md`.
- **User's profile page** (if one exists): looked up in the Team directory by
  name. URL cached to `USER.md`.

## Read sources (the AI pulls from these automatically)

| Source | What the AI does with it | Refresh cadence |
|---|---|---|
| Operating Framework | Summarizes into `onboarding/company.md` | Monthly + on-change |
| Team directory (the user's team) | Populates `onboarding/team.md` | Monthly + on-change |
| New Hire Onboarding card (if new hire) | Orchestrates the onboarding walk-through per `onboarding/new-hire-flow.md` | Every session until Status = Complete |
| Packs Library | Fetches pack content when the user asks to install one | On demand |
| Active project pages | Reads for context; never writes canonically | Weekly (when user mentions a project) |

## Write targets (where auto-promotes land)

**Two different write surfaces, two different rules.** See Contract §9 (canon
inboxes) and §14 (AI Memory). Both can fire on a single observation.

### Rule 9 — canonical pages (inbox-only)

| Scope | Target page | Inbox section title |
|---|---|---|
| **Project** | the specific project page | `## Assistant Updates` |
| **Team** | the team's hub page | `## Assistant Updates` |
| **Org** | org-wide policy / glossary / norms | `## Assistant Updates` |
| **Onboarding Q&A** (new hires only) | user's onboarding card → `Onboarding Questions` sub-page | Appended to the sub-page body |

**Rule 9 rule:** NEVER auto-write outside `## Assistant Updates` or the
`Onboarding Questions` sub-page (a pre-authorized exception). Creating any
other new Notion page outside the AI Memory DBs requires explicit consent.

### Rule 14 — AI Memory databases (structured, direct writes)

See the "AI Memory databases" table above. The assistant writes rows
directly (share-by-default) after the sensitivity gate passes. Rows in the
AI Memory DBs are the one class of "new Notion content" that the assistant
may create without per-item consent, because the user consented to the
entire brain model at setup time.

## Update manifest (for self-updates)

- **Repository:** https://github.com/tomasmb/aa-ai-os-template
- **Manifest URL** (JSON, stable across releases): https://github.com/tomasmb/aa-ai-os-template/releases/latest/download/manifest.json
- **Release list:** https://github.com/tomasmb/aa-ai-os-template/releases/latest
- **Check cadence:** once per 24h (Contract §3)
- **Channel:** `stable` (change to `beta` for early access)

## Owners of truth (for conflict resolution)

- If `SOUL.md` / `CONTRACT.md` / `PROMOTION-RULES.md` disagree with a Notion
  page, the **folder wins** (those are shipped as protected files).
- If `onboarding/company.md` / `team.md` / `role.md` disagree with local
  memory, the **Notion page wins** (Notion is the source of truth for org
  knowledge).
- If a new hire's onboarding card has different content than what's cached
  locally, **Notion wins** — re-sync immediately.
