# pack: company-brain

> Alpha's shared, AI-maintained knowledge graph. Every assistant writes to it
> when something public-facing comes up. Every assistant reads from it to
> answer questions about people, projects, decisions, and cross-cutting
> patterns. **Share by default. Ask before writing only when the content
> would unsettle the user if a colleague saw it tomorrow.**

## Why this exists

Local memory (`memory/`) makes each assistant smart for one person. It does
nothing for the organization. Over time, hundreds of conversations happen
that contain useful facts — who owns what, what was decided in which
meeting, what patterns are emerging — and today all of that dies in private
folders or gets buried in canonical prose on Notion pages.

This pack fixes that with a **bi-level knowledge graph** under the
`🧠 AI Memory` and `📚 AI Memory — Archive` pages in Notion:

- **Core** (6 DBs, always-on): **People**, **Projects**, **Decisions**,
  **Insights**, **Meetings**, **Goals**. Lean entity rows + relations.
- **Archive** (3 DBs, on-demand + permissioned): **Students/Families**,
  **Playbooks** (pointer index), **Glossary**. Raw/scoped material and
  canonical references.

Every row carries provenance. Every assistant can query them.

The result: Alpha gets smarter with every conversation, and every employee
inherits that intelligence the moment they open their assistant.

## Core design rules

1. **Share by default.** Don't ask permission for facts about public work.
2. **Ask before writing only when the content is sensitive** (see heuristic
   below). Ask as one sentence, not a form.
3. **Local memory always happens first.** Every useful thing lands in
   `memory/` regardless of whether it also flows to the brain.
4. **Dedupe before writing.** Always query existing rows before creating new
   ones. Update-in-place beats create-new.
5. **Provenance is immutable.** Source, author, timestamp — set once, never
   rewritten.
6. **No canon duplication.** If a fact already lives in the Operating
   Framework, Team directory, or another canonical page, read it there.
   Don't copy it into the brain.
7. **No cross-tier duplication.** Core rows hold entities + links. Archive
   rows hold bodies/content. Core references Archive by relation; Archive is
   never copied into Core.
8. **Core loads every session; Archive loads on demand.** Archive reads only
   happen via relation traversal from a Core row, or via explicit user query.

## The bi-level model

Canonical URLs live in `NOTION-SYNC.md`. On boot: verify all 6 Core DBs are
reachable; verify the Archive parent page is reachable. Individual Archive
DBs may be permission-denied — that's expected and must be skipped silently
(Rule 14a). If a Core DB is missing, stop and walk the user through
`NOTION-SYNC.md` setup before proceeding.

### Core (6 DBs — always-on, lean)

| Database | What goes in | Natural key for dedup |
|---|---|---|
| **👤 People** | One row per person in the org. Role, team, ownership areas, notes about how they work. | `Email` (must be unique) |
| **🚀 Projects** | One row per active initiative. Status, owner, milestone, blockers. | `Name` (normalized — strip case / punctuation) |
| **✅ Decisions** | One row per durable decision. Rationale, outcome, status (Active / Superseded / Reversed / Paused). | `Title` + `Decided on` |
| **💡 Insights** | One row per cross-cutting observation. Tags, strength, suggested action. Surface count auto-increments on rematch. | `Title` (fuzzy match on dedup) |
| **🗓 Meetings** | One row per meeting/session. Date, kind, attendees, context (project or student), decisions/insights produced, notes link. | `Title` + `Date` |
| **🎯 Goals** | One row per goal (company/team/individual). Period, owner, status, key results, related projects + decisions. | `Goal` + `Period` |

### Archive (3 DBs — on-demand, permissioned)

| Database | What goes in | Natural key | Access default |
|---|---|---|---|
| **🎓 Students / Families** | One row per active student. Coach, program, status, canonical coaching-context link. | `Student Name` + `Coach` | Default-deny; scoped per coach |
| **📘 Playbooks** | **Pointer index** to SOPs. Title, domain, owner, canonical link, last reviewed. Never stores the SOP body. | `Title` | Open-read, owner-write |
| **📖 Glossary** | One-line term definitions with optional canonical link. Hard cap ~100 rows by convention. | `Term` | Open-read, open-write |

### Classification — does this fact belong in Core or Archive?

Quick decision tree when the assistant extracts a fact:

1. Is it an **entity or event** the assistant will need to reference in
   future sessions (person, project, decision, insight, meeting, goal)? →
   **Core**, lean row, link out for any body text.
2. Is it **raw material, sensitive context, or a reference lookup** that's
   only needed sometimes (student background, SOP body location, term
   definition)? → **Archive**.
3. Does it already live in **canon** (Operating Framework, Team directory,
   SOP page)? → neither. Read it there. Optionally add a pointer in
   Playbooks or Glossary if it's cross-referenced often.

### Archive → Core promotion (one-way, by link only)

Promotion never happens by copy. It happens by **creating a Core row that
relates to the Archive source**. Examples:

- A pattern noticed across multiple coaching sessions → a new **Insight**
  row whose `Related Meetings` points at the Archive-linked Meeting rows,
  and whose body references (doesn't restate) the Students rows.
- A playbook change decision → a new **Decision** row with `Related Goals`
  and whose notes link to the Playbook row's canonical link.

If a Core row starts to grow a paragraph of prose, that's the smell: the
prose belongs in Archive (or canonical Notion), and Core should just link.

## Sensitivity heuristic — when to ask first

The user's operating stance is **share by default**. The assistant asks
before writing only when the content meets any of these:

1. **Negative feedback about named colleagues or leadership.**
   *"Carla's been dropping the ball on X."* → ask.
2. **Personal frustration with a specific person or team.**
   *"I'm really annoyed with Eng right now."* → ask.
3. **Health, family, or personal-life matters.**
   *"I'm out tomorrow — mom's in the hospital."* → never auto-share.
4. **Compensation, career anxiety, interview plans.**
   *"I'm thinking about leaving."* / *"I got a raise offer."* → ask.
5. **Strategic doubt the user hasn't voiced publicly.**
   *"I don't think the Q2 plan makes sense."* → ask.
6. **Incomplete drafts the user wouldn't want sampled.**
   Early-form writing or half-baked thinking → keep local until published.
7. **Explicit privacy markers.** The user says *"between us"*, *"privately"*,
   *"off the record"*, *"just for me"*, *"don't share this"* → never share.
8. **Third parties who can't consent.** Customer names + personal details,
   candidate evaluations, partner sensitivities → redact or ask.

How the ask sounds (one sentence, no drama):

> *"That sounds personal — want me to keep it local only, or okay to note
> in the brain?"*

> *"That's feedback about a colleague — share it to the brain, or just
> remember it for you?"*

> *"Compensation talk — just keeping it local unless you say otherwise."*
> (no question — this one is safe to default-local without interrupting)

**Never do this:**
- A big scary privacy disclaimer.
- A form.
- Asking permission for every fact. Only asking on sensitive content.
- Dragging the user into a long deliberation about what to share.

## Write flow (the algorithm)

When the assistant extracts a potentially shareable fact from a conversation:

```text
1. Write it to local memory first (today's daily note + relevant section).
2. Classify fact type → which DB? (People / Project / Decision / Insight /
   Meeting / Goal for Core; Student / Playbook / Glossary for Archive.)
3. Tier check: is this an entity (Core) or raw/reference material (Archive)?
   If Core would grow a paragraph of prose, split: lean Core row + link to
   an Archive/canonical page for the body.
4. Classify sensitivity per heuristic above.
5. If sensitive → ask. If no or silence → stop; stay local.
6. If not sensitive → query the target DB for a dedup match.
   a. Match found → UPDATE in place. Add this session to `Source users`.
      For Insights, increment `Surface count` by 1.
   b. No match → CREATE new row with full provenance.
7. Confirm to user only if it's novel or noteworthy. Silent otherwise.
8. Cache the updated row locally in `memory/brain-cache/<tier>/<db>/<id>.md`
   (`tier` ∈ {`core`, `archive`} — see `memory/brain-cache/README.md`).
```

**Never:** write with low confidence unless the user corroborated. Never
create a Decision row based on one casual remark — decisions need a clear
owner and rationale before they land.

## Read flow

Brain reads happen on demand, not eagerly. Two patterns:

### Boot warm-up (every session)

1. Resolve the user's own `People` row via their email (from `USER.md`).
   Create it if missing (see onboarding seed below).
2. Pull every `People` row on the user's team (filter `Team = <user's team>`).
   Cache in `memory/brain-cache/people/team.md`. TTL: 1 hour.
3. Pull open `Projects` owned or contributed to by the user. Cache.
4. Load into prompt context only the cached summary, not raw rows.

### Query-time (when the user asks)

When the user asks a question the cache can't answer:

- *"Who owns X?"* → query `People.Areas of ownership` contains `X`.
- *"What's the status of Project Y?"* → query `Projects.Name`.
- *"What did we decide about Z in the last month?"* → query `Decisions`
  filtered by `Category` or `Title` + `Decided on > 30d ago`.
- *"Have other people noticed this?"* → query `Insights` by `Tags` or
  `Title` fuzzy match; report `Surface count` to the user.
- *"What happened in last week's sync?"* → query `Meetings.Date >= 7d ago`
  filtered by `Attendees` or `Related Project`, follow `Decisions Produced`
  and `Insights Produced` for the outputs.
- *"Where are we on Q2 goals?"* → query `Goals.Period = q2_*` filtered by
  `Scope` / `Owner`; synthesize status.
- *"What's our playbook for X?"* → query `Playbooks.Title` (Archive) —
  return `Canonical Link`, never attempt to summarize the SOP body from
  inside the brain.
- *"What's the definition of <term>?"* → query `Glossary.Term` (Archive).

Never dump raw DB rows at the user. Synthesize in plain English.

## Dedup rules per DB

### People (by Email)

`Email` is the unique natural key. Before creating:

1. Query `Email = <email>`. If hit → update that row, never create.
2. If no email yet (user referenced someone by first name only), try
   `Name = <name>` + `Team = <team if known>`. If exactly one match, use it.
   If multiple, ask the user which person they mean.
3. If creating new: set `Source = ['conversation']`, `Confidence = low`
   until corroborated by a second source or confirmed by the user.

### Projects (by normalized Name)

Normalize name: lowercase, strip punctuation, collapse whitespace.

1. Query for exact normalized match. If hit → update.
2. If no hit but fuzzy match > 0.85 on name or description keywords,
   **ask**: *"Is this the same as `<existing project>` or a new one?"* Never
   create duplicates silently.
3. On create, `Status` defaults to `In progress` if it seems active, else
   `Not started`.

### Decisions (by Title + Decided on)

Decisions are append-only. Never overwrite `Outcome` or `Rationale` on an
existing row. If the user says *"we reversed that"*:

1. Mark the existing row `Status = Reversed`.
2. Create a new row for the new decision with `Status = Active`, link to
   the old one via content references in `Rationale`.

### Insights (fuzzy Title + Tag overlap)

Insights are the database most prone to dupes because multiple assistants
across users will surface similar observations.

1. Query by tag overlap (>= 2 tags match) + title fuzzy match (>= 0.7).
2. Match found → **increment `Surface count` by 1**, append user to
   `Source users`, keep `Strength` at the higher of existing vs. new
   assessment. Don't mutate `Title` or `Body`.
3. No match → create with `Surface count = 1`, `Strength` per assistant's
   assessment.
4. If an insight's `Surface count >= 3`, it's organically strong — surface
   it in the weekly digest.

### Meetings (by Title + Date)

1. Query `Title = <title>` AND `Date = <date>`. If hit → update in place
   (add attendees, link outputs).
2. Keep rows lean: `Notes Link` points to the canonical notes page (Notion,
   Google Doc, recording transcript). The DB **never stores the body**.
3. On create, set `Attendees`/`Related Project`/`Related Student` relations
   up front — a Meeting with no relations is almost always a misfire.
4. Decisions and Insights produced in the meeting are written as their own
   rows and linked back via `Decisions Produced` / `Insights Produced`.

### Goals (by Goal + Period)

1. Query for exact `Goal` + `Period` match. If hit → update `Status`,
   `Key Results`, relations. Never rewrite history on closed periods.
2. Distinct from Projects: Goals describe outcomes and span multiple
   projects. If a "goal" maps 1:1 to a single project, it's a project.
3. `Canonical Link` points to the full OKR doc if one exists — Goals rows
   summarize, don't duplicate.

### Students / Families (Archive — by Student Name + Coach)

Before reading or writing, confirm the user can access the row. If Notion
returns a permission error, stop — **do not retry, do not prompt the user**
(Rule 14a).

1. Query by `Student Name` + `Coach`. If hit → update in place.
2. Keep rows **lean**: program, status, start date, link to the canonical
   coaching-context page (which lives under a permissioned Notion tree,
   not in this DB). The one-or-two-sentence `Summary` is the only prose
   allowed in the row.
3. Never cache Student rows locally (`memory/brain-cache/README.md` — the
   `archive/students/` namespace is reserved but disabled by default).

### Playbooks (Archive — by Title)

Playbooks is a **pointer index**, not a content store.

1. Query by `Title`. If hit → update `Last Reviewed`, `Status`, `Owner`.
2. `Canonical Link` is required. A Playbook row with no canonical link is
   a bug — refuse to create it.
3. Never paste SOP bodies into `Summary`; it's literally one sentence.

### Glossary (Archive — by Term, ~100 row soft cap)

1. Query `Term` case-insensitive. If hit → update only if the existing
   definition is ambiguous or stale; otherwise leave it.
2. If the Glossary is approaching 100 rows, flag it in the weekly digest
   for manual pruning. Don't auto-delete.
3. Multi-sentence definitions get collapsed to one sentence + a
   `Canonical Link` — that's the whole discipline of this DB.

## First-run seeding

On a new assistant's very first session, after onboarding:

1. Create or update the user's own `People` row with their email, name,
   team, role, timezone. `Source = ['manual']`, `Confidence = high`,
   `Source users = <user email>`.
2. For new hires, also create their `Projects` rows for anything listed on
   their onboarding card under *"what you'll be working on"* (low
   confidence, mark for verification at first 1-1).
3. Don't mass-seed other people. Let the brain grow organically as the
   user mentions colleagues.

## Conflict handling

When an assistant writes something that contradicts an existing row:

1. **Do not silently overwrite.** Write nothing yet.
2. Surface the conflict to the current user in plain English:
   *"The brain has Ana owning Design. You just said Ben owns Design. Which
   is right?"*
3. On the user's answer:
   - *"Ben now"* → update the existing row, add a line to `Notes`: *"Owner
     changed from Ana to Ben on <date> per <user>."* Create a new Insight
     with tag `people` capturing the transition.
   - *"Still Ana, I was confused"* → no write. Log locally in
     `memory/sensitivity-log.md` as a no-op.
4. Never ping the original source user directly about conflicts. The
   weekly owner digest surfaces these.

## What NEVER lands in the brain

- Anything from `memory/` that wasn't extracted + classified as non-sensitive.
- Personal frustration, health info, compensation talk, interview plans.
- Customer PII beyond "works at company X" (never contact info, never
  sentiment about an individual customer).
- Half-formed drafts.
- Anything the user asked be kept private — even retroactively (*"actually,
  forget that one"* → delete the row + log to `sensitivity-log.md`).
- Facts already in canon (Operating Framework, Team directory) — just read
  canon there.

## What is NOT in Core (and why)

Explicit list so the brain doesn't drift into becoming a graveyard:

- **Tasks.** Use Notion's `My Tasks` DB or the user's task tool; the brain
  doesn't mirror a TODO list.
- **Experiments / pilots.** Collapsed into Projects with a `type` property.
- **Operating Principles.** They live in the Operating Framework page —
  doctrine, not decisions. The brain reads them canonically; it does NOT
  seed them into Decisions (that inflated the DB in v1.5 and has been
  corrected).
- **SOP bodies.** Only pointers in the Archive Playbooks index. Bodies stay
  at their canonical home.
- **Meeting transcripts / notes bodies.** Meetings rows carry `Notes Link`;
  the body stays at the canonical notes page.
- **Risks / Incidents / Open Questions.** Deferred — re-evaluated after 4
  weeks of bi-level usage based on what's accumulating as Insights.

## User controls

The user can say any of these at any time:

| User says | What the assistant does |
|---|---|
| *"What do you know about me?"* | Reads `People` row + local memory + recent writes, summarizes plainly. |
| *"What do you know about X?"* | Queries the 6 Core DBs (and reachable Archive DBs) for X across all relation fields, synthesizes. |
| *"Forget that"* (after a recent write) | Deletes the row if the assistant created it this session, else marks `Status = archived` + logs to `sensitivity-log.md`. |
| *"That was private"* | Same as above + updates sensitivity heuristic locally: future similar statements default to local-only for this user. |
| *"Did I say yes to sharing that?"* | Reads `sensitivity-log.md` + brain write history. Answers honestly. |
| *"Stop writing to the brain"* | Sets `brain.disabled = true` in `WORKSTYLE.md`. Still reads, never writes. User can re-enable anytime. |

## Interaction with Rule 9 (auto-promote to canonical page inboxes)

Two different surfaces, two different rules:

- **Rule 9** → canonical Notion pages (Operating Framework, dept pages).
  Auto-promote into the `## Assistant Updates` inbox section only. Canon
  itself is never edited.
- **This pack (Rule 14)** → brain DBs. Rows are AI-owned. Write freely
  (share-by-default + sensitivity gate). No inbox gating; the brain IS the
  AI's natural home.

A single observation can flow to both: *"Ana owns Design"* → writes a
`People.Ana.Areas of ownership += Design` row in the brain, AND adds a
line to the Design team page's `## Assistant Updates` inbox suggesting the
canonical team page be updated.

## Governance & retention

### Per-DB retention (Core)

- **Insights with `Strength = weak` and zero corroboration after 90 days**
  → auto-set `Status = archived`. Weekly job.
- **Decisions** → never auto-archive. Status transitions only.
- **People + Projects** → retain indefinitely. Alumni marked
  `Status = Alumni` but not deleted.
- **Meetings** → retain indefinitely, but rows with only a title (no
  relations, no notes link) after 30 days are flagged for cleanup.
- **Goals** → period-bound. Closed periods become historical and are never
  rewritten; the `Status` tells the story (achieved/missed/etc).

### Per-DB retention (Archive)

- **Students / Families** → retained through the coaching relationship + 1
  year, then archived (never deleted). Governed by Head of Coaching.
- **Playbooks** → never auto-archive. Status = `deprecated` marks stale
  ones; the canonical content is owned outside the brain.
- **Glossary** → manually pruned. Any row unreferenced for 180 days is a
  candidate for removal at the quarterly review.

### Growth expectations (the guardrail against the graveyard)

Every DB has a rough growth expectation. If a DB exceeds its band, we don't
let it grow — we either split the use case or retire rows.

| DB | Expected steady-state band | Notes |
|---|---|---|
| People | bounded by headcount | alumni marked not deleted |
| Projects | low tens | close to `Status = done`, don't delete |
| Decisions | append-only, ~50/quarter | historical; status transitions only |
| Insights | append-only; weak-and-old archived at 90d | dedupe is the main lever |
| Meetings | append-only; thousands/year is normal | lean rows, bodies linked out |
| Goals | bounded by period × scope | closed periods retained as history |
| Students | bounded by active roster | permissioned |
| Playbooks | low tens | pointer index, not content |
| Glossary | soft cap ~100 rows | pruned quarterly |

### Review cadence

- **Weekly review (Tomás + Ops partner)**: scan last 7 days of writes
  across all Core DBs, look for duplicates, conflicts, bad classifications.
  Fix in place.
- **Quarterly Archive audit**: any Archive DB with <10 queries in 90 days
  is reviewed for deprecation. Prevents graveyard drift.

## Success criteria

- **Hit rate on "who owns X?"** questions: >80% resolvable from brain
  without human clarification by week 4 of pilot.
- **Dedup quality**: <5% duplicate rows in People, <10% in Insights.
- **User trust**: <1 user complaint per pilot week about an unwanted brain
  write. Zero sensitive-content leaks (incl. zero Archive permission
  bypass attempts).
- **Coverage**: by end of pilot, every active team has ≥5 Projects rows,
  every pilot user has a ≥3-paragraph Notes field on their own People row.
- **Lean discipline**: no Core row exceeds one paragraph of prose. No
  Playbook row contains SOP body text. No Archive DB grows below its query
  threshold (see quarterly audit).

## Files this pack depends on

- `NOTION-SYNC.md` — DB URLs
- `CONTRACT.md` — Rule 14 (share-by-default with sensitivity gate)
- `USER.md` — user email + team for filtering
- `WORKSTYLE.md` — `brain.disabled` flag
- `memory/brain-cache/` — local cache of queried rows (TTL 1h)
- `memory/sensitivity-log.md` — audit log of ask-first decisions + forgets
