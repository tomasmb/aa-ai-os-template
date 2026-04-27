# MIGRATION-INVENTORY.md — Notion → KB migration inventory

> Snapshot of every Notion source the v2.0.0 migration writer pass
> needs to consume. Built from a `notion-search` audit on
> 2026-04-27. Row counts marked `?` are filled in by
> `scripts/migrate-from-notion/inventory.mjs` when the maintainer runs
> it (the script paginates each database and writes the count back
> here in place).
>
> The maintainer reviews this file and approves scope **before** the
> writer pass runs.

## 1. Core databases (→ `core/<entity>/<slug>.md` + optional Archive sibling)

| Source | Notion ID | Target folder | Rows | Archive sibling |
|---|---|---|---|---|
| `👤 People` | `6b06c441-1b94-48be-b21e-14f4df69fa8b` | `core/people/` | ? | `archive/people/` only when bio body > 15 lines |
| `🚀 Projects` | `b23db324-3d41-46bf-85e6-0ede57dca759` | `core/projects/` | ? | `archive/projects/<slug>.md` for any row with body content |
| `🗓 Meetings` | `a31bc7be-1011-4aeb-861e-73fc83293f67` | `core/meetings/` | ? | `archive/meeting-notes/<slug>.md` always |
| `🎯 Goals` | `b059e5f7-c5fd-4b7e-8ddd-eea8b8de255f` | `core/goals/` | ? | none (Core summary holds the goal + KRs) |
| `✅ Decisions` | `c1978663-1d3d-4144-8dac-8dc56b195604` | `core/decisions/` | ? | `archive/decision-rationale/<slug>.md` when long rationale exists |
| `💡 Insights` | `73815567-aaa9-4aea-90fb-1d9678f80f14` | `core/insights/` | ? | none — insights stay terse |

## 2. Archive databases (→ `archive/<entity>/<slug>.md` only)

| Source | Notion ID | Target folder | Rows |
|---|---|---|---|
| `🎓 Students / Families` | `149cab67-67dd-4878-b316-2cf862f65adc` | `archive/students/` | ? |
| `📘 Playbooks` | `fb856e03-efca-4def-af37-59cb63296f67` | `archive/playbooks/` | ? |
| `📖 Glossary` | `83c00d27-9167-4c8b-a859-68cca6f66727` | `archive/glossary/` | ? |

## 3. Onboarding database (→ `archive/onboarding/<email-slug>.md`)

| Source | Notion ID | Target folder | Rows | Notes |
|---|---|---|---|---|
| `👋 New Hire Onboarding` | `2922901d-7908-802a-b4d6-d0b79fb15722` | `archive/onboarding/` | ? | Migrate open + completed within last 12 months. Older = skip with note in `docs/MIGRATION-SKIPPED.md`. |

Per-department templates are extracted to
`archive/onboarding/_templates/<department>.md` if the maintainer
flags any of the 8 Notion templates worth preserving:

- Global, Coaching, Marketing, Product & Engineering, Program
  Advisor, Parent Experience, Academics, Life Skills.

(The script accepts a `--templates` flag with the list to extract.)

## 4. Operating Framework subtree (→ `operating-framework/<slug>.md`)

Hub: `Alpha AI OS — V1` (`3492901d-7908-81df-80e3-fbfefd7e7b70`)
links to a doctrine subtree. The migration extracts every page in
that subtree, one file per page in `operating-framework/`. Manifest
filled by the inventory script (not yet expanded — the subtree may
live under `Operating Framework` in Notion, ID
`2892901d-7908-8097-b23f-f06dbb41b4dc` per the legacy
`onboarding/company.md`).

| Source | Notion ID | Target file | Notes |
|---|---|---|---|
| Operating Framework root | `2892901d-7908-8097-b23f-f06dbb41b4dc` | `operating-framework/README.md` | + walk children recursively |

## 5. Pages with `## Assistant Updates` sections (→ `inbox/`)

Every canonical page in Notion that has accumulated AI promotions
under a `## Assistant Updates` heading gets each bullet emitted as
one `inbox/<YYYY-MM-DDTHH-MM-SS>_<entity>_<slug>.md` file. Source
timestamp = the Notion edit time of that bullet (best available
proxy).

The inventory script scans every page reachable from the AI Memory
hub + Archive hub + Operating Framework subtree for `## Assistant
Updates` headings and lists the count here:

| Page | Notion ID | Bullet count |
|---|---|---|
| `🧠 AI Memory` | `3492901d-7908-81ad-b05d-f812f2aa4131` | ? |
| `📚 AI Memory — Archive` | `34b2901d-7908-816e-aa04-cd681e796e61` | ? |
| `AI Memory — Privacy & Sensitivity` | `3492901d-7908-81ec-8db9-fd7a27254af2` | ? |
| `Alpha AI OS — V1` | `3492901d-7908-81df-80e3-fbfefd7e7b70` | ? |
| `Alpha Turbo Squad — Launch Tracker` | `34b2901d-7908-81ec-9d4e-f396de3372e4` | ? |
| (others — populated by inventory script) | | ? |

## 6. Maintainer-flagged additions

> Add any extra pages here that the maintainer wants migrated but
> aren't reachable from the standard hubs. Each row gets its own
> migration target.

| Source | Notion ID | Target | Notes |
|---|---|---|---|
| _(none yet — fill during inventory review)_ | | | |

## 7. Out of scope (intentionally not migrated)

- Pages older than 18 months that haven't been edited in 12 months —
  treated as stale; migration writes a skip line to
  `docs/MIGRATION-SKIPPED.md` so the maintainer can audit.
- Coaching session transcripts — handled separately (live in Granola
  / Drive, not the AI Memory layer).
- Notion-internal automations / synced blocks — replaced by KB
  conventions; nothing to carry over.

## 8. Estimated migration volume

Run `node scripts/migrate-from-notion/inventory.mjs --print-totals`
to populate. Expected output shape:

```text
Core DBs:        ~? rows  → ? Core files (+ ? Archive siblings)
Archive DBs:     ~? rows  → ? Archive files
Onboarding DB:   ~? rows  → ? archive/onboarding files
Op Framework:    ~? pages → ? operating-framework files
Inbox bullets:   ~? items → ? inbox files
Skipped binaries: ~?      (recorded in docs/MIGRATION-SKIPPED.md)
Total markdown:  ~? files
```

Sanity check: total markdown should be in the low thousands
(<10 000) — well within `rg`'s comfort zone.

## 9. Approval

| Item | Owner | Approved on |
|---|---|---|
| Scope of Core DB migration | maintainer | _pending_ |
| Scope of Archive DB migration | maintainer | _pending_ |
| Onboarding DB migration window (last 12 months) | maintainer | _pending_ |
| Operating Framework subtree extraction | maintainer | _pending_ |
| Inbox extraction from `## Assistant Updates` sections | maintainer | _pending_ |
| Maintainer-flagged additions (§6) | maintainer | _pending_ |

When all six rows are approved, run the writer pass per
`docs/MIGRATION-RUNBOOK.md`.
