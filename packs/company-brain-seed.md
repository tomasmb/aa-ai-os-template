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

| DB | Source of truth | Auto-seed? | Why |
|---|---|---|---|
| **👤 People** | Team directory (canonical Notion DB) | **Yes — all rows** | High-confidence, every field maps cleanly, immediate day-1 value on every lookup. |
| **🚀 Projects** | Recent-activity project pages (last 2 weeks) | **Yes — curated 5-10** | Medium-confidence. Seed only projects with clear owner + recent activity; let the long tail grow organically. |
| **✅ Decisions** | Operating Framework / leadership pages | **Yes — foundational only** | Seed 5-15 top-level "why-we-do-X" decisions. Leave operational decisions to grow from meetings + conversations. |
| **💡 Insights** | — | **No, start empty** | Insights emerge from observed patterns across many conversations. Pre-seeding risks planting stale ones. |

## The procedure (for the maintainer operator)

Every step assumes the operator is chatting with their assistant. The
assistant follows this pack like any other — read, execute, report.

### Step 0 — Preflight

1. Verify all 4 AI Memory DBs are reachable (`NOTION-SYNC.md` URLs).
2. Query each DB row count. If any is >0, **stop** and ask the operator:
   *"Brain already has N rows. Re-seed (dedup protects), skip, or abort?"*
3. Confirm the operator's email goes into `Source users` on every seeded
   row. Provenance matters.

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

### Step 2 — Seed foundational Decisions (curated)

1. Read the Operating Framework / Operating Principles page.
2. Extract each top-level principle as one Decision row:
   - `Title = "Operating Principle #N — <principle name>"`
   - `Outcome = <the principle's core statement, 2-3 sentences>`
   - `Rationale = <1-2 sentences on why this principle exists>`
   - `Category = ["strategy", ...]` (infer from principle content)
   - `Status = Active`
   - `Confidence = high`
   - `Source = ["document"]`
   - `Owner = CEO's People row`
   - `Participants = Leadership team People rows`
   - `Decided on = <org founding date, or first-written date if known>`
3. Do **not** auto-extract operational decisions from prose pages. Those
   live in the Decisions DB only once someone formally captures them.
4. Report: *"Seeded N foundational decisions from Operating Framework."*

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

### Step 4 — Insights: skip

Do not seed Insights. The assistant tells the operator:

> *"Insights grow from real observations across many conversations.
> Pre-seeding would create stale ones. Your brain's Insights DB starts
> empty on purpose — it'll fill up in the first 1-2 weeks of use."*

### Step 5 — Report to operator

Single summary message (no tables, no drama):

> *"Brain seeded from existing Notion: N people, M projects, K decisions.
> Insights starts empty on purpose — it grows from conversations. Every
> row carries provenance back to the source page. Your team will feel
> this from their first session."*

## Re-run safety

If the operator runs this pack a second time (e.g. after adding new
employees to the Team directory):

1. Dedup rules from `company-brain.md` apply automatically:
   - People by `Email` → update in place
   - Projects by normalized `Name` → update in place
   - Decisions by `Title + Decided on` → update in place
2. Add the re-run's operator to each touched row's `Source users`.
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
- **Decisions `Source` options DO include `"document"`.**

If future brain-schema changes break this pack, update the mapping table
here and bump the core version in `.version`.

## Files this pack depends on

- `NOTION-SYNC.md` — canonical Notion URLs + AI Memory DB URLs
- `CONTRACT.md` — Rule 14 (brain writes) and Rule 3 (provenance)
- `packs/company-brain.md` — dedup rules, write flow, conflict handling

## What this pack does NOT do

- **No insights seeding.** Ever.
- **No blanket scraping** of every Notion page into the brain. The brain
  is structured (People, Projects, Decisions, Insights), not a mirror of
  canonical Notion. Canonical pages stay in Notion and the assistant
  reads them on demand — that's the point of having a canonical layer.
- **No per-user re-seeding.** One operator, one run. Individual users'
  own `People` rows get updated through `onboarding/new-hire-flow.md`
  Block 8, not through this pack.
