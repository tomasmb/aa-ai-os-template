# pack: company-brain-seed — one-time KB seed (maintainer-run)

> Foundational. Ships by default. **Maintainer runs this once at v2.0
> rollout.** Per-user sessions never invoke it. The seeding plan documents
> the canonical first content of `alpha-anywhere-kb/`.

## What this pack does

Lays down the initial structure and minimal canonical content of the KB so
every user session starts with a coherent, non-empty brain. After the seed,
all writes flow through `scripts/promote` per Contract §14.

## Pre-requisites

- Maintainer is in the `alphaanywhere` GitHub org with admin on the KB repo.
- Local clone of `alpha-anywhere-kb/` with `main` checked out and clean.
- Optional: a finished Notion → KB migration (`docs/MIGRATION-RUNBOOK.md`).
  If running, do that first; this seed only fills gaps the migration doesn't
  cover.

## What gets seeded

### 1. Top-level files (already shipped by `kb_seed` task)

`README.md`, `KB-CONVENTIONS.md`, `COMMIT-CONVENTIONS.md`,
`CONFLICT-PLAYBOOK.md`, `CODEOWNERS`, `.github/workflows/lint.yml`,
`.github/pull_request_template.md`, `.gitattributes`.

### 2. Directory tree

```text
core/people/      core/projects/    core/meetings/
core/goals/       core/decisions/   core/insights/
archive/meeting-notes/      archive/decision-rationale/
archive/playbooks/          archive/glossary/
archive/students/           archive/projects/
archive/onboarding/         inbox/
operating-framework/
```

Each directory has a `_README.md` describing what belongs there + retention.

### 3. People — full org seed

For each person on the team:

- Pull GitHub username + display name from `gh api repos/tomasmb/alpha-anywhere-kb/collaborators` (or the equivalent org/team API once the repo lives in an org).
- Create `core/people/<github-username>.md` with frontmatter + a 3-line stub.
- Stub body: *"Seeded from GitHub on YYYY-MM-DD. Update with role, team,
  manager when known."*

Maintainer fills team / role from the Notion Team directory snapshot in
the migration. After v2.0.0 launch, employees update their own People row
on first session via `onboarding/setup-questionnaire.md` Block 8.

### 4. Operating framework

Move (not copy) the Operating Principles from Notion's Operating Framework
sub-tree into `operating-framework/`:

```text
operating-framework/
  README.md                   ← table of contents
  principles/
    01_<name>.md
    02_<name>.md
    ...
  policies/
    <slug>.md
  glossary-pointers.md        ← optional cross-ref to archive/glossary/
```

Each principle file has frontmatter `principle:`, `version:`,
`last_reviewed:` and the canonical body.

### 5. Decisions and Insights — empty

Intentionally **not** seeded. They populate from real conversations and
meetings. Operating Principles live in `operating-framework/`, never as
"foundational" Decisions.

### 6. Meetings — recurring stubs only

For each recurring meeting (weekly leadership, weekly coach sync, etc.):

- Create `core/meetings/recurring/<slug>.md` with frontmatter `kind: recurring`,
  `cadence:`, `attendees[]`, `purpose:`.
- The pack `company-meetings.md` later spawns one-off
  `core/meetings/YYYY-MM-DD_<slug>.md` files per occurrence.

### 7. Goals — current period only

Seed goals only for the **current** quarter / month, copied from whatever the
team is tracking today. Older periods don't backfill.

### 8. Students / Playbooks / Glossary — Archive

- `archive/students/`: seeded from the Notion Students DB by the migration
  script. Org-wide read in v2 (no row-level perms).
- `archive/playbooks/`: import each canonical playbook body. Frontmatter
  `title`, `owner`, `last_reviewed`, `version`.
- `archive/glossary/`: import every glossary term with its body.

### 9. Inbox

Empty at seed time. The first inbox entries will arrive from real user
sessions post-launch.

## Run order

```bash
cd ~/Alpha\ AI\ OS/alpha-anywhere-kb

# 1. Verify clean main
git status
git checkout main && git pull --rebase

# 2. Run the migration script (if not already done)
cd ../alpha-assistant
node scripts/migrate-from-notion/run.mjs --inventory > docs/MIGRATION-INVENTORY.md
node scripts/migrate-from-notion/run.mjs --write
node scripts/migrate-from-notion/validate.mjs

# 3. Add this seed's residual content (people stubs, recurring meetings, current-period goals)
node scripts/migrate-from-notion/seed-residual.mjs

# 4. Commit
cd ../alpha-anywhere-kb
git add -A
git commit -m "seed(framework): v2.0.0 initial KB"
git tag v1.0.0
git push --tags
```

## After seeding

Tag the KB at `v1.0.0`. Tag the assistant repo at `v2.0.0`. Announce in the
new minimalist Notion hub. Users run the one-line installer and start
sessions immediately.

## What this pack is NOT

- Not invoked per-user — only the maintainer runs it at v2.0.0.
- Not idempotent — running it twice could clobber later writes. Always check
  `git status` and skip steps already done.
- Not a substitute for the migration script — the migration handles bulk
  Notion content; this pack handles the residual structural skeleton.
