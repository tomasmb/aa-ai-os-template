# PROMOTION-RULES.md — What flows from me to the KB

> These rules are read once at session start and enforced at every potential
> promotion. Defaults err toward keeping the brain lean. Contract §9 / §14 /
> §16 override anything here on conflict.

## What to promote (by scope)

### Project scope — promote when
- a **decision** changes execution (chosen approach, cancelled direction)
- a **blocker** affects multiple contributors
- a **status change** others need to know (shipped, blocked, delayed)
- a **meeting** created shared follow-ups

### Team scope — promote when
- a **workflow** is reusable across the team (a process, a template, a checklist)
- a **recurring issue** is identified across multiple people
- a **norm or ritual** changes (new standup format, new review cadence)
- a **template** becomes durable (the right way to write PR descriptions, etc.)

### Org scope — promote when
- a **policy or definition** changes (KPI definitions, role ladders)
- **multiple teams** need the same insight
- a **cross-cutting pattern** is confirmed from multiple data points

## Keep local (never promote)

- Private reflections, venting, personal context.
- Raw conversation transcripts.
- Anything the user explicitly marked private.
- Drafts before the user has confirmed them.
- Things only useful to this one person on this one day.

## How to promote — file-based, atomic, opt-in inbox

Promotions land as new files in the KB's `inbox/` folder, one per
observation. The assistant calls `scripts/promote inbox <entity-type> <slug>`
which:

1. `git pull --rebase` on the KB.
2. Writes `inbox/<YYYY-MM-DDTHH-MM-SS>_<entity-type>_<slug>.md`.
3. `git add` + `git commit` with a Conventional Commits message
   (`COMMIT-CONVENTIONS.md`).
4. `git push`.

### Inbox file shape

```markdown
---
promoted_by: <user-slug>
promoted_at: <ISO timestamp>
target_entity: people | projects | meetings | goals | decisions | insights
target_path: core/<entity>/<slug>.md   # optional — link to canonical entity
source: conversation | meeting | manual
confidence: high | medium | low
---

# <one-line title>

<1–3 sentence summary>.

Decision / Context / Who / Next step (inline if relevant).
```

### Hard rules

1. **Always summarize.** Never paste raw quotes longer than one sentence.
2. **Always dedupe.** Before writing, `rg` recent inbox files (last 7 days)
   and the candidate target entity for a semantic match. If found within 24h
   on the same entity, **update** the existing inbox file instead of creating
   a new one.
3. **Always tag** the entry via `promoted_by:` + `promoted_at:` frontmatter
   and the `Promoted-By:` commit trailer so owners can trace it.
4. **Never auto-create** a new Core or Archive entity from an inbox promote.
   If a promotion implies a brand-new entity (e.g. mentions a person not yet
   in `core/people/`), ask the user once: *"There's no entry for 'Casey Brown'
   in the brain yet — want me to add them?"*
5. **Inbox files are append-only.** Owners consolidate manually (their
   weekly digest reminds them). The assistant never bulk-edits or deletes
   inbox files except for *forget* operations Rule 11 directly authorizes.
6. **Rate limit** — no more than one promote per entity per hour. Batch the
   intent locally if the user fires off rapid-fire updates.
7. **Log everything** — every commit SHA + path goes to `logs/session-log.md`.

## What owners see (weekly consolidation rhythm)

Page owners receive a weekly email digest (see `digests/email-weekly.md` and
Contract §15) listing:

- Pending `inbox/` files where they're the entity owner.
- Direct edits to `core/` entities they own (with commit links to GitHub).

They decide when to consolidate inbox → canonical. The assistant helps on demand:

> *"The Q2-churn project has 6 pending inbox items from 3 assistants this
> month — want me to draft a consolidation into the canonical project file?"*

A consolidation is a separate atomic commit with type `consolidate(<scope>):`
that edits the canonical entity and (optionally) deletes the rolled-up inbox
files in the same commit.

## Forgetting cascades

When the user says "forget X":
- Local: delete from `memory/`, append to `memory/tombstones.md`.
- KB: find inbox files tagged with this user (`promoted_by: <user-slug>`)
  matching X, delete via `scripts/promote forget <path>` (atomic commit type
  `forget(inbox)`). Pushed history is **not** rewritten — the file is removed
  going forward; admins can run hard-forget via `git filter-repo` if needed.
- Canonical content: leave alone. That's the owner's to edit.
- Tombstone locally so we don't re-promote the same thing later.

## Failure mode

If `git push` fails (network, auth, conflict):

- Per Contract §12 + `CONFLICT-PLAYBOOK.md`, queue the write to
  `logs/pending-writes.md`. The morning ritual replays the queue.
- Tell the user once at the top of the next session: *"3 updates to the brain
  are queued — I'll push them when GitHub's reachable."*
- Never silently lose data.
