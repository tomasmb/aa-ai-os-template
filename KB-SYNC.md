# KB-SYNC.md — Where I read from and write to in the company KB

> The company brain lives in a sibling git repo: **`alphaanywhere/alpha-anywhere-kb`**.
> No Notion. No MCP. Reads are local file ops. Writes are atomic git operations.
> This file is the single source of truth for KB layout, paths, and sync rules.

## Where the KB lives on disk

The KB is cloned as a **sibling** of this assistant folder. Default layout:

```text
~/Alpha AI OS/
├── alpha-assistant/        ← this folder (alphaanywhere/aa-ai-os-template, public)
└── alpha-anywhere-kb/      ← the KB    (alphaanywhere/alpha-anywhere-kb, private)
```

The absolute KB path is resolved at every session boot from
`memory/kb-location.md` (gitignored, written by `scripts/bootstrap`). If that
file is missing or its path doesn't resolve to a clean git repo, run
`scripts/bootstrap` to repair.

If `memory/kb-status.md` is `pending` (user not yet in the GitHub org), the
assistant runs in **partial mode**: identity / tone / workstyle still work,
but the brain is unreachable until access lands. Reattempt every session.

## The bi-level AI Memory model (v2.0+)

AI Memory has two tiers, each with its own job:

- **Core** — lean entity rows, always-on. One file per entity. Frontmatter +
  a 5–15 line summary. Loaded every session.
- **Archive** — full bodies and source material (meeting notes, playbooks,
  long-form rationale, glossary, students). Read on demand. Linked from Core
  via `notes_path:` / `body_path:` / `rationale_path:`.

**Five lean invariants** (mirrored in Contract Rule 14):

1. **No duplication across tiers.** Archive holds bodies; Core holds entities
   + links. A Core file > 30 lines is a smell — move the prose to Archive.
2. **Stated growth + retention per DB.** Documented in `KB-CONVENTIONS.md`.
3. **One canonical query per DB.** No two folders answer the same question.
4. **Canon is not mirrored.** Operating Principles live in `operating-framework/`,
   read directly, never copied into Decisions.
5. **Core eager, Archive lazy.** Core is read at boot; Archive only when a
   Core relation traverses into it or the user asks.

## KB layout (folders the assistant cares about)

```text
alpha-anywhere-kb/
├── README.md
├── KB-CONVENTIONS.md          ← frontmatter schema + naming rules
├── COMMIT-CONVENTIONS.md
├── CONFLICT-PLAYBOOK.md
├── core/
│   ├── people/                ← <slug>.md per person
│   ├── projects/              ← <slug>.md per project
│   ├── meetings/              ← YYYY-MM-DD_<slug>.md per meeting
│   ├── goals/                 ← <period>_<slug>.md per goal
│   ├── decisions/             ← YYYY-MM-DD_<slug>.md per decision
│   └── insights/              ← YYYY-MM-DD_<slug>.md per insight
├── archive/
│   ├── meeting-notes/         ← full notes; linked from core/meetings
│   ├── decision-rationale/    ← long-form rationale; linked from core/decisions
│   ├── playbooks/             ← full playbook bodies
│   ├── glossary/              ← <term>.md
│   ├── students/              ← <slug>.md per student
│   └── projects/              ← optional long-form briefs
├── inbox/                     ← append-only AI promotions
└── operating-framework/       ← canonical doctrine
```

Cross-references use **relative markdown links** only (no wiki-style `[[…]]`):

```markdown
- Owner: [Jane Doe](../people/jane-doe.md)
- Notes: see [archive/meeting-notes/2026-04-22_team-sync.md](../../archive/meeting-notes/2026-04-22_team-sync.md)
```

Frontmatter is YAML. Full schema lives in the KB's `KB-CONVENTIONS.md` —
the assistant reads it on boot.

## Boot-check sequence (every session)

The assistant runs `scripts/preflight` then `scripts/sync-kb` at every boot.
Preflight verifies:

1. `memory/kb-location.md` exists and resolves to a directory.
2. That directory is a git working tree (`.git/` present).
3. `git status` is clean (no uncommitted local changes from a previous crash).
4. Current branch is `main`.
5. Origin matches `https://github.com/alphaanywhere/alpha-anywhere-kb.git`
   (or the org's actual canonical URL).
6. `git config user.name` and `user.email` are set (assistant needs them
   for commits).

`sync-kb` runs `git pull --rebase` and surfaces a "since last session"
briefing from `git log --since="<last_session_ts>" -- core/`.

If any preflight check fails, the assistant runs `scripts/bootstrap` and
explains plainly what's being repaired. Never silent.

## Read sources (the assistant pulls from these automatically)

| Source | What the AI does with it | Refresh |
|---|---|---|
| `core/**` | Loaded on first relevant query in a session; cached for the session | On-boot pull |
| `operating-framework/**` | Read directly; never copied into Decisions | On-boot pull |
| `archive/**` | Read only when a Core link traverses into it or user asks | On-demand |
| `inbox/**` | Read when checking for duplicates before promoting | On-write |

## Write targets (where promotions land)

**Single surface:** every assistant write is a git commit on the KB repo.
There are two categories, both atomic via `scripts/promote`:

### Inbox writes (Rule 9 — auto-promotes)

When the user says something promotable (per `PROMOTION-RULES.md`), the
assistant writes one new file:

```text
inbox/<YYYY-MM-DDTHH-MM-SS>_<entity-type>_<slug>.md
```

Frontmatter:

```yaml
---
promoted_by: <user-slug>
promoted_at: <ISO timestamp>
target_entity: people | projects | meetings | goals | decisions | insights
target_path: core/<entity>/<slug>.md   # optional — if a specific Core file is the target
source: conversation | meeting | manual
confidence: high | medium | low
---
```

Body: 1–3 sentence summary of the promotion.

Owners consolidate inbox items into canonical Core/Archive files on their
own cadence (weekly digest reminds them).

### Direct entity writes (Rule 14 — AI Memory)

For structured updates that fit cleanly into a Core or Archive entity, the
assistant edits the entity file directly via `scripts/promote`. The script
runs `git pull --rebase` → write file → `git add` → `git commit` → `git push`
atomically. Conflicts surface to the user per `CONFLICT-PLAYBOOK.md` —
never silent merge.

## Dedupe before write

Before creating an inbox file or editing an entity, `rg` recent inbox files
and the target entity for semantic matches. If found within 24h on the same
entity, **update** the existing file instead of creating a duplicate.

## Update manifest (for self-updates of the assistant repo)

- **Repository:** https://github.com/alphaanywhere/aa-ai-os-template (public)
- **Update mechanism:** daily `git pull` on this folder by the morning ritual.
  The old zip-based update flow is gone.
- **Version tracking:** `.version` and `manifest.json` are kept for human
  reference; they are not behavioral.

## Owners of truth (for conflict resolution)

- **Folder wins** over the KB for behavioral files (`SOUL.md`, `CONTRACT.md`,
  `PROMOTION-RULES.md`, `TOOLS.md`, `KB-SYNC.md`). These are shipped here.
- **KB wins** for everything in `core/`, `archive/`, `operating-framework/`.
  Local cache must be re-pulled if it disagrees.
- **User wins** on every conflict the assistant surfaces in conversation.
  Never silent merge.
