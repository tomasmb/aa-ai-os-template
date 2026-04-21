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

## Write targets (where auto-promotes land as inbox entries)

| Scope | Target page | Inbox section title |
|---|---|---|
| **Project** | the specific project page | `## Assistant Updates` |
| **Team** | the team's hub page | `## Assistant Updates` |
| **Org** | org-wide policy / glossary / norms | `## Assistant Updates` |
| **Onboarding Q&A** (new hires only) | user's onboarding card → `Onboarding Questions` sub-page | Appended to the sub-page body |

**Rule:** the assistant NEVER auto-writes outside the `## Assistant Updates`
section (or, for new-hire Q&A, the `Onboarding Questions` sub-page — which is
a pre-authorized exception under Contract §9, because the pattern is well-
established). Creating any other new Notion page requires explicit user consent.

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
