# pack: company-brain — share-by-default writes to the KB

> Foundational. Ships by default. The assistant reads this every session.
> Implements Contract Rules 9 + 14 + 16 against the sibling KB git repo.

## What this pack does

Turns natural conversation into durable, structured entries in
`alpha-anywhere-kb/`. The assistant captures every fact about public work
share-by-default, dedupes against existing files, and pushes via
`scripts/promote`.

The brain has two tiers (full layout in `KB-SYNC.md`):

- **Core** — lean entity rows, always-on. One markdown file per entity.
  `core/{people,projects,decisions,insights,meetings,goals}/<slug>.md`.
- **Archive** — full bodies, raw material. Read on demand.
  `archive/{meeting-notes,decision-rationale,playbooks,glossary,students,projects}/`.

## When to invoke

Every session, on every conversational turn. Specifically when the user:

- States a fact about a person, project, decision, meeting, goal, or insight.
- Surfaces a pattern or a status change others would benefit from.
- Asks "where are we on X?" / "who owns Y?" — the assistant answers from `core/`
  via `rg`.

## Decision tree — Core or Archive?

| If the content is… | Goes to | Notes |
|---|---|---|
| One row of structured fields about an entity | `core/<entity>/<slug>.md` | Frontmatter + ≤30 lines |
| A meeting summary > 2 paragraphs | `archive/meeting-notes/YYYY-MM-DD_<slug>.md` | Linked from `core/meetings/<...>.md:notes_path` |
| Decision rationale or alternatives considered | `archive/decision-rationale/YYYY-MM-DD_<slug>.md` | Linked from `core/decisions/<...>.md:rationale_path` |
| Playbook body / SOP body | `archive/playbooks/<slug>.md` | Core has a pointer file in `core/playbooks/` if you want one (optional) |
| Glossary term (1–2 sentences) | `archive/glossary/<term>.md` | Soft cap ~100 entries |
| Student / family record | `archive/students/<slug>.md` | Org-wide read; sensitive content filtered by Rule 14 gate |

If a Core file grows past 30 lines of body content, **move the prose to
Archive** and link it via frontmatter (`notes_path:` / `body_path:` /
`rationale_path:`). Five lean invariants in `KB-SYNC.md`.

## Per-entity behavior

### `core/people/<slug>.md`

- Natural key: lowercase email user portion (`jane.doe@…` → `jane-doe.md`).
- Frontmatter fields: `name`, `email`, `team`, `role`, `manager`, `slack`,
  `github`, `started_at`.
- Body: 5–15 line summary covering role, current focus, comms preferences.
- Update on: every mention adding new info. Dedupe via `rg`.

### `core/projects/<slug>.md`

- Natural key: kebab-case from project name.
- Frontmatter: `name`, `status` (active/paused/done/cancelled), `owner`
  (relative path to `core/people/<slug>.md`), `contributors[]`, `goals[]`,
  `started_at`, `target_date`.
- Body: short brief (problem / approach / current status). Long-form goes to
  `archive/projects/<slug>.md` and is linked via `body_path:`.

### `core/decisions/YYYY-MM-DD_<slug>.md`

- Frontmatter: `title`, `decided_on`, `owner`, `participants[]`,
  `related_projects[]`, `related_goals[]`, `source_meeting`,
  `rationale_path`.
- Body: 1–3 sentence what + why. Full alternatives + rationale go to
  `archive/decision-rationale/`.
- **Operating Principles never live here** — they're canonical in
  `operating-framework/` (canon not mirrored).

### `core/insights/YYYY-MM-DD_<slug>.md`

- Frontmatter: `title`, `tags[]`, `related_people[]`, `related_projects[]`,
  `related_decisions[]`, `source_meeting`.
- Body: 1–3 sentences. Insights are observations, not decisions.

### `core/meetings/YYYY-MM-DD_<slug>.md`

- Natural key: `YYYY-MM-DD_<slug>`.
- Frontmatter: `title`, `date`, `attendees[]`, `related_project`,
  `related_student`, `decisions_produced[]`, `insights_produced[]`,
  `notes_path`.
- Body: ≤10 line summary. Full notes → `archive/meeting-notes/`.

### `core/goals/<period>_<slug>.md`

- Natural key: `<period>_<slug>` (e.g. `2026Q2_reduce-churn.md`).
- Frontmatter: `goal`, `period`, `owner`, `status` (on-track / at-risk /
  off-track / done), `related_projects[]`, `related_decisions[]`.
- Body: 3–8 lines. The weekly digest highlights at-risk goals.

## Dedupe before write

Before writing **any** file:

```bash
rg -l --no-messages "<key fragment>" "$KB/core/<entity>/" 2>/dev/null
rg -l --no-messages "<key fragment>" "$KB/inbox/" 2>/dev/null
```

If a match exists for the same entity within 24h, **update** the existing
file instead of creating a new one. For inbox files, dedupe semantically:
similar title + same `target_entity` within 24h → update existing.

## How to write — always via `scripts/promote`

The assistant **never** edits KB files in place without going through
`scripts/promote`. Why: pull-rebase + atomic commit + push are bundled,
conflict handling lives in the script, identity trailers are guaranteed.

Examples:

```bash
# Inbox promote (Rule 9):
echo "<3-sentence summary>" \
    | scripts/promote inbox insights churn-signal-from-tuesday \
        --target-path core/projects/q2-churn.md \
        --source meeting --confidence medium \
        --message "churn signal from Tuesday team sync"

# Direct entity edit (Rule 14):
cat <<'EOF' | scripts/promote entity core/people/jane-doe.md \
    --message "add Slack handle to Jane Doe" --confidence high
---
name: Jane Doe
email: jane.doe@2hourlearning.com
team: coaching
slack: jane-doe
---

<5-line summary>
EOF
```

`scripts/promote` runs `git pull --rebase` first, writes the file, commits
with a Conventional Commits message + `Promoted-By:` trailer, and pushes.
On conflict it aborts cleanly and surfaces per `CONFLICT-PLAYBOOK.md`.

## Sensitivity gate (Contract §14)

Before any write that touches one of:

1. Negative feedback about named colleagues / leadership.
2. Personal frustration with a specific person or team.
3. Health / family / personal-life matters.
4. Compensation / career anxiety / interview plans.
5. Strategic doubt the user hasn't voiced publicly.
6. Incomplete drafts the user wouldn't want sampled.
7. Explicit markers: *"between us"*, *"privately"*, *"off the record"*.
8. Third parties who can't consent (customers, candidates, partner details).

→ Ask one sentence: *"That sounds personal — keep local only, or okay to
note in the brain?"* Default to local on silence or *"local"*.

## Per-folder retention

| Folder | Growth expectation | Retention |
|---|---|---|
| `core/people/` | Bounded by org headcount | Forever |
| `core/projects/` | ~100s | Active forever; archived projects move `archive/projects/` |
| `core/meetings/` | High (every meeting) | 18-month rolling; older auto-tombstone |
| `core/decisions/` | Moderate | Forever |
| `core/insights/` | Moderate | Forever |
| `core/goals/` | Bounded per period | Forever |
| `archive/meeting-notes/` | High | 18-month rolling, then prune |
| `archive/glossary/` | Bounded ~100 | Forever |
| `inbox/` | Append-only | 90 days; older auto-tombstone after consolidation |

The KB CI lint workflow flags folders trending past their stated bound.

## Reading from the brain

Reads are local file ops:

```bash
# Find Jane's people row
rg -l "jane-doe" "$KB/core/people/"

# All decisions on Q2 churn
rg -l "q2-churn" "$KB/core/decisions/"

# Last week's meetings with Jane
rg -l "jane-doe" "$KB/core/meetings/" | xargs ls -1tr | tail -20
```

Cache results in-session; re-fetch on next morning ritual via
`scripts/sync-kb`.

## Cross-referencing

Inside markdown bodies, link with **relative paths**:

```markdown
- Owner: [Jane Doe](../people/jane-doe.md)
- Notes: [archive/meeting-notes/2026-04-22_team-sync.md](../../archive/meeting-notes/2026-04-22_team-sync.md)
```

Never use wiki-style `[[…]]` links; CI lint rejects them.
