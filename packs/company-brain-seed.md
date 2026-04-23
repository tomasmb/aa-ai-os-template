# pack: company-brain-seed

> **One-time bulk seeding** of the AI Memory brain from existing canonical
> Notion content. Run once per org, by a maintainer, right after the brain
> databases are created. After that, the brain grows organically through
> conversations (see `packs/company-brain.md`).

## Why this exists

An empty brain delivers zero day-1 value. The first employee to open their
assistant asks *"who owns Coaching?"* and the brain can't answer — so the
assistant falls back to reading the Team directory every time. Slow, less
precise, no relational queries across People ↔ Projects ↔ Decisions.

This pack fixes that by **pre-loading the brain from high-confidence
canonical sources** on day zero. One run, one operator, everyone benefits.

## When to run

- **Once**, at rollout time, by a single maintainer (typically the person
  who set up the AI OS).
- **Never automatically** on individual user first-runs — that would cause
  every assistant to try to seed, producing duplicates and conflicts.
- **Optionally re-run** if the brain gets corrupted or after a major team
  restructure. Dedup rules in `company-brain.md` protect re-seeds.

## What gets seeded (and what doesn't)

The bi-level model (Core + Archive, `packs/company-brain.md`) intentionally
seeds only the Core DBs where canonical sources exist and add day-1 value.
**Archive DBs are never seeded** — they're populated by their owners as
part of normal work.

### Core tier

| DB | Source of truth | Auto-seed? | Why |
|---|---|---|---|
| **👤 People** | Team directory (canonical Notion DB) | **Yes — all rows** | High-confidence, every field maps cleanly, immediate day-1 value on every lookup. |
| **🚀 Projects** | Recent-activity project pages (last 2 weeks) | **Yes — curated 5-10** | Medium-confidence. Seed only projects with clear owner + recent activity; let the long tail grow organically. |
| **✅ Decisions** | — | **No, start empty** | Operating Principles live in the Operating Framework as doctrine; seeding them as Decisions inflates the DB and pollutes velocity/retention signals. Operational decisions grow from real meetings + conversations. |
| **💡 Insights** | — | **No, start empty** | Insights emerge from observed patterns across many conversations. Pre-seeding risks planting stale ones. |
| **🗓 Meetings** | Recurring-meeting list (last 2 weeks) | **Yes — lean curated** | Just the recurring-meeting stubs so Decisions and Insights have something to link back to on day 1. Bodies stay at canonical notes. |
| **🎯 Goals** | Current-period OKR doc (if one exists) | **Yes — current period only** | Seed only the active quarter's company + team goals. Closed periods are history, not seed material. |

### Archive tier — NOT seeded

- **🎓 Students / Families** — populated by coaches as they enroll students.
  Permission-gated; a maintainer seeding this would leak scope.
- **📘 Playbooks** — populated by SOP owners when they want their SOP
  indexed. The brain never scrapes SOP pages to build this; ownership
  matters.
- **📖 Glossary** — populated organically when someone corrects a
  definition or adds a new term. Seeding it pre-emptively grows a
  graveyard.

## The procedure (for the maintainer operator)

Every step assumes the operator is chatting with their assistant. The
assistant follows this pack like any other — read, execute, report.

### Step 0 — Preflight

1. Verify all **6 Core** AI Memory DBs are reachable (`NOTION-SYNC.md`
   URLs). Verify the **📚 AI Memory — Archive** parent page is reachable
   (individual Archive DBs are allowed to be permission-denied — that's by
   design and does not block seeding).
2. Query each Core DB's row count. If any is >0, **stop** and ask the
   operator: *"Brain already has N rows in <DB>. Re-seed (dedup protects),
   skip, or abort?"*
3. Confirm the operator's email goes into `Source users` / `Source User` on
   every seeded row. Provenance matters.

### Step 1 — Seed People (automated, high confidence)

1. Fetch the canonical Team directory data source.
2. For each row: extract `Name`, `Email`, `Role`, `Team`, `Location`.
3. Map `Location` → closest supported `Timezone` select value. When no
   exact match exists, use `Other` rather than guessing.
4. Map `Team` to the 👤 People `Team` select values (watch for
   singular/plural differences — e.g. team directory's *"Program Advisors"*
   vs. brain's *"Program Advisor"*).
5. Batch-create People rows with:
   - `Confidence = high`
   - `Source = ["team-directory"]`
   - `Source users = <operator email>`
   - `Notes = "Based in <location>. Brain-seed v<VERSION> — sourced from <team-directory-page-url>"`
6. Report: *"Seeded N people from Team directory."*

### Step 2 — Decisions: skip seeding

Operating Principles are **doctrine**, not decisions. They live in the
Operating Framework page and the assistant reads them canonically (see
`onboarding/company.md`). The Decisions DB starts empty and grows from
real operational decisions captured in conversations and meetings.

The assistant tells the operator:

> *"Decisions starts empty on purpose. Operating Principles stay in the
> Operating Framework — I'll read them there, not mirror them here.
> Real decisions will accrue from meetings and conversations starting
> today."*

### Step 3 — Seed active Projects (curated)

1. Search Notion for pages updated in the last **2 weeks** matching
   project-like queries (*"project"*, *"launch"*, *"roadmap"*,
   *"implementation"*). Filter out templates and team-member pages.
2. Present the shortlist to the operator for confirmation (5-10 projects
   max). **Do not seed unreviewed** — wrong projects pollute the brain.
3. For each approved project, fetch the page and extract:
   - `Name` (page title, cleaned)
   - `Description` (1-2 sentences from top of page body)
   - `Owner` (look for named owner; map to People row by name)
   - `Team` (infer from page parent or owner)
   - `Next milestone` (look for date-bearing line in the top half)
   - `Status = In progress` (implied by recent activity)
4. Batch-create Projects rows with:
   - `Confidence = high` (or `medium` when owner/milestone are inferred)
   - `Source = ["manual"]` (note: Projects schema doesn't accept
     `"document"` — use `"manual"`)
   - `Source users = <operator email>`
   - `Blockers = "Source: <source-page-url>"` (use the Blockers text to
     stash the source URL — the brain schema doesn't have a dedicated
     source-URL column on Projects, and keeping the link inline beats
     losing it)
5. Report: *"Seeded N projects. Owners linked for M, medium-confidence
   for K without clear owner."*

### Step 4 — Seed Meetings (lean, recurring-only)

1. Ask the operator to name recurring meetings that should exist as stubs:
   weekly leadership, team standups, the monthly all-hands, etc. **Do not
   scrape** Notion for meetings — this seed is intentionally small.
2. For each confirmed recurring meeting, create one placeholder row for
   the **most recent instance** with:
   - `Title = <meeting name>`
   - `Date = <last known occurrence>`
   - `Kind = <team / 1_on_1 / all_hands / …>`
   - `Attendees = <relevant People rows>`
   - `Notes Link = <canonical notes page if one exists, else empty>`
   - `Source User = <operator email>`
3. **Never seed coaching sessions** here — those are Archive-linked and
   get created by the coach's assistant during normal use.
4. Report: *"Seeded N recurring-meeting stubs so decisions and insights
   have something to link back to."*

### Step 5 — Seed Goals (current period only)

1. Ask the operator whether there's a canonical OKR doc (Notion page,
   sheet). If yes, extract **only the active period** (current quarter /
   current month).
2. For each goal, create a lean row:
   - `Goal = <goal statement>`
   - `Period = <current period code>`
   - `Scope = company / team / individual`
   - `Owner = <People row>`
   - `Status = committed` (default on seed)
   - `Key Results = <concise bullets, or link to canonical OKR doc>`
   - `Canonical Link = <OKR doc URL>`
3. Never seed historical periods. They stay at the canonical doc.
4. Report: *"Seeded N goals for the current period. Closed periods stay in
   the OKR doc — I'll read them there if you ask."*

### Step 6 — Insights: skip

Do not seed Insights. The assistant tells the operator:

> *"Insights grow from real observations across many conversations.
> Pre-seeding would create stale ones. Your brain's Insights DB starts
> empty on purpose — it'll fill up in the first 1-2 weeks of use."*

### Step 7 — Report to operator

Single summary message (no tables, no drama):

> *"Brain seeded from existing Notion: N people, M projects, K recurring
> meetings, L current-period goals. Decisions and Insights start empty on
> purpose — they grow from conversations. The Archive tier
> (Students/Playbooks/Glossary) is populated by its owners as they work,
> not by seeds. Every row carries provenance back to its source. Your team
> will feel this from their first session."*

## Re-run safety

If the operator runs this pack a second time (e.g. after adding new
employees to the Team directory):

1. Dedup rules from `company-brain.md` apply automatically:
   - People by `Email` → update in place
   - Projects by normalized `Name` → update in place
   - Meetings by `Title + Date` → update in place
   - Goals by `Goal + Period` → update in place
2. Add the re-run's operator to each touched row's `Source users` /
   `Source User`.
3. Report which rows were new vs. updated vs. unchanged.

## Schema quirks to know about

A handful of differences between the team-directory schema and the brain
schema require explicit mapping during seed:

- **Team directory `"Program Advisors"` (plural) → brain `"Program Advisor"` (singular).**
- **Team directory `Location` (place) → brain `Timezone` (select).** Use
  the closest IANA option; fall back to `"Other"` when none fits.
- **Projects `Source` options do NOT include `"document"`** (only
  `conversation`, `meeting`, `manual`, `decision`). Use `"manual"` when
  seeding from Notion pages.
- **Meetings and Goals `Source User` is a single rich-text string** (not a
  multi-select). Write the operator's email in directly.

If future brain-schema changes break this pack, update the mapping table
here and bump the core version in `.version`.

## Files this pack depends on

- `NOTION-SYNC.md` — canonical Notion URLs + AI Memory DB URLs
- `CONTRACT.md` — Rule 14 (brain writes, two tiers) and Rule 3 (provenance)
- `packs/company-brain.md` — dedup rules, write flow, conflict handling,
  Core-vs-Archive classification

## What this pack does NOT do

- **No Insights seeding.** Ever.
- **No Decisions seeding.** Operating Principles stay in the Operating
  Framework; operational decisions accrue from real use.
- **No Archive seeding.** Students, Playbooks, and Glossary are owner-
  populated, not seeded.
- **No blanket scraping** of every Notion page into the brain. The brain
  is structured (Core: 6 entity DBs; Archive: 3 reference DBs), not a
  mirror of canonical Notion. Canonical pages stay in Notion and the
  assistant reads them on demand — that's the point of having a canonical
  layer.
- **No per-user re-seeding.** One operator, one run. Individual users'
  own `People` rows get updated through `onboarding/new-hire-flow.md`
  Block 8, not through this pack.
