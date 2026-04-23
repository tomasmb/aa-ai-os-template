# NOTION-SYNC.md — Where I read from and write to in Notion

> Notion is the shared company brain. This file tells the assistant which pages
> to read (to feed itself) and which inbox sections to write to (to feed the
> company). URLs marked with 🔒 are **hardcoded** — they're part of the shipped
> template and should not be edited by the user.

## The bi-level AI Memory model (v1.6+)

AI Memory has two tiers, each with its own job:

- **🧠 AI Memory — Core** (6 databases): lean, always-on. Entities + relations.
  Loaded every session. Rows are short (name, a few fields, links). If a row
  grows past one paragraph of prose, it belongs in Archive, not Core.
- **📚 AI Memory — Archive** (3 databases): raw material + canonical pointers.
  Read on demand. Sensitive DBs (Students/Families) are permission-gated at
  the Notion row level — the assistant never attempts to bypass denied reads.

Core holds entities. Archive holds bodies. Core rows reference Archive rows
via relations, **never by copying content across tiers**. See `CONTRACT.md`
Rule 14 for the invariants.

## 🔒 Canonical Alpha pages (hardcoded — same for every employee)

The AI OS Notion hub is deliberately lean (v1.5+): it hosts only the download
link and the AI Memory pages. All AI OS documentation (Contract, Promotion
Rules, onboarding modules, packs catalogue, governance, roadmap) lives inside
the folder, single canonical copy, no duplication.

| Purpose | Notion URL |
|---|---|
| **Alpha AI OS — V1** (download hub + AI Memory parent) | https://www.notion.so/3492901d790881df80e3fbfefd7e7b70 |
| **🧠 AI Memory** (Core parent page) | https://www.notion.so/3492901d790881adb05df812f2aa4131 |
| **📚 AI Memory — Archive** (Archive parent page) | https://www.notion.so/34b2901d7908816eaa04cd681e796e61 |
| **Operating Framework** (how Alpha works — Principles live here) | https://www.notion.so/2892901d79088097b23ff06dbb41b4dc |
| **Team directory** (who works here) | https://www.notion.so/2892901d790880c0a0e9d5594c29861d |
| **👋 New Hire Onboarding** (database) | https://www.notion.so/2922901d7908802ab4d6d0b79fb15722 |

## 🔒 Core AI Memory databases (Contract §14 — shared brain, always-on)

Read + write under `packs/company-brain.md`. Natural keys per DB are enforced
to prevent duplicates. Provenance is mandatory on every write.

| Database | URL | Natural key | Primary relations |
|---|---|---|---|
| **👤 People** | https://www.notion.so/6b06c4411b9448beb21e14f4df69fa8b | `Email` | target of Projects.Owner, Decisions.Owner, Meetings.Attendees, Goals.Owner |
| **🚀 Projects** | https://www.notion.so/b23db3243d4146bf85e60ede57dca759 | normalized `Name` | `Owner`/`Contributors` → People; `Goals served` → Goals |
| **✅ Decisions** | https://www.notion.so/c19786631d3d41448dac8dc56b195604 | `Title` + `Decided on` | `Owner`/`Participants` → People; `Related projects` → Projects; `Source Meeting` → Meetings; `Related Goals` → Goals |
| **💡 Insights** | https://www.notion.so/73815567aaa94aea90fb1d9678f80f14 | fuzzy `Title` + ≥2 tag overlap | `Related people/projects/decisions`; `Source Meeting` → Meetings |
| **🗓 Meetings** | https://www.notion.so/a31bc7be10114aeb861e73fc83293f67 | `Title` + `Date` | `Attendees` → People; `Related Project` → Projects; `Related Student` → Students (Archive); produces `Decisions` + `Insights` |
| **🎯 Goals** | https://www.notion.so/b059e5f7c5fd4b7e8dddeea8b8de255f | `Goal` + `Period` | `Owner` → People; `Related Projects` → Projects; `Related Decisions` → Decisions |

## 🔒 Archive AI Memory databases (Contract §14a — read on demand, permissioned)

Archive rows are never loaded eagerly. They're read when a Core relation
traverses into them, or when the user explicitly asks for that material. Row
access is permission-gated by Notion — the assistant silently skips what it
can't see and does not prompt the user to grant broader access.

| Database | URL | Natural key | Access default |
|---|---|---|---|
| **🎓 Students / Families** | https://www.notion.so/149cab6767dd4878b3162cf862f65adc | `Student Name` + `Coach` | **Default-deny** — assigned coach + Head of Coaching only |
| **📘 Playbooks** (SOP index) | https://www.notion.so/fb856e03efca4defaf3759cb63296f67 | `Title` | Open-read, owner-write |
| **📖 Glossary** | https://www.notion.so/83c00d2791674c8ba85968cca6f66727 | `Term` | Open-read, open-write |

The Playbooks DB is a **pointer index** — it never stores SOP bodies, only
title/owner/canonical-link/last-reviewed. The Glossary is a one-line-per-term
reference capped at ~100 rows by convention; full concepts link out.

**Boot check:**
1. Verify all 6 **Core** DBs are reachable. If any is missing, stop and walk
   the user through granting the Notion integration access to the `🧠 AI Memory`
   page. See `packs/company-brain.md`.
2. Verify the **📚 AI Memory — Archive** parent page is reachable. Individual
   Archive DBs may be permission-denied for this user — that's **expected**
   (e.g. a non-coach doesn't see Students). Do not prompt; just skip.

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
| Operating Framework | Summarizes into `onboarding/company.md`. Principles live here — the brain reads them, never copies them into Decisions. | Monthly + on-change |
| Team directory (the user's team) | Populates `onboarding/team.md` | Monthly + on-change |
| New Hire Onboarding card (if new hire) | Orchestrates the onboarding walk-through per `onboarding/new-hire-flow.md` | Every session until Status = Complete |
| Active project pages | Reads for context; never writes canonically | Weekly (when user mentions a project) |

## Write targets (where auto-promotes land)

**Two different write surfaces, two different rules.** See Contract §9 (canon
inboxes) and §14 (AI Memory). Both can fire on a single observation.

### Rule 9 — canonical pages (opt-in inbox)

Inbox writes only happen when the target page has an existing
`## Assistant Updates` section. **Owners opt in by adding that heading to
their page.** No section → no write (silent skip, not a prompt).

| Scope | Target page | Inbox section title |
|---|---|---|
| **Project** | the specific project page | `## Assistant Updates` (if present) |
| **Team** | the team's hub page | `## Assistant Updates` (if present) |
| **Org** | org-wide policy / glossary / norms | `## Assistant Updates` (if present) |
| **Onboarding Q&A** (new hires only) | user's onboarding card → `Onboarding Questions` sub-page | Appended to the sub-page body |

**Rule 9 rule:** NEVER auto-write outside `## Assistant Updates` or the
`Onboarding Questions` sub-page (a pre-authorized exception). Creating any
other new Notion page outside the AI Memory DBs requires explicit consent.

The brain (Rule 14) is the primary durable surface. Rule 9 inboxes are a
**nice-to-have** for page owners who want assistant-surfaced updates
visible inside their canonical page.

### Rule 14 — AI Memory databases (structured, direct writes)

See the "Core" and "Archive" tables above. The assistant writes rows
directly (share-by-default) after the sensitivity gate passes. Rows in the
AI Memory DBs — both tiers — are the one class of "new Notion content" that
the assistant may create without per-item consent, because the user consented
to the brain model at setup time.

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
