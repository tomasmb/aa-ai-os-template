# Migration runbook — Notion → `alpha-anywhere-kb`

Maintainer-only. One-time procedure. Follow once, tag the KB at
`v1.0.0`, then archive `scripts/migrate-from-notion/` from active use.

The migration script is **idempotent**: re-runs are not only allowed
but expected during the dial-in phase. Every step below is safe to
repeat.

## 0. Prerequisites

- You have admin access to both `github.com/alphaanywhere/aa-ai-os-template`
  and `github.com/alphaanywhere/alpha-anywhere-kb`.
- You have a local clone of both repos as siblings under
  `~/Alpha AI OS/` (run `scripts/install.sh` first if not).
- Node 20+ is on the PATH (`node --version`).
- You can authenticate against the Notion workspace.

## 1. Create a Notion internal integration

1. Open <https://www.notion.so/profile/integrations>.
2. Click **+ New integration** → name it `Alpha AI OS migration`.
3. Workspace: select the AlphaAnywhere workspace.
4. Capabilities: **Read content** is enough. Leave write off.
5. Copy the **Internal Integration Token** (starts with `secret_`) — you
   only see it once.
6. **Grant page access.** Open every top-level Notion page that is in
   scope (see `docs/MIGRATION-INVENTORY.md`) → click `…` → **Add
   connections** → pick the new integration. Notion's permission model
   is page-scoped, not workspace-scoped, so this step is mandatory.

## 2. Set environment variables

```bash
cd ~/Alpha\ AI\ OS/alpha-assistant/scripts/migrate-from-notion
npm install

export NOTION_TOKEN=secret_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
export KB_ROOT=~/Alpha\ AI\ OS/alpha-anywhere-kb
```

`KB_ROOT` must point at the local KB clone, not the assistant clone.

## 3. Inventory pass (read-only)

Updates `docs/MIGRATION-INVENTORY.md` with current row counts.

```bash
node inventory.mjs
```

Open `docs/MIGRATION-INVENTORY.md` and verify totals look sane. If a
DB shows `0`, it usually means the integration was not added to that
page — go back to step 1.6 and grant access, then rerun.

## 4. Writer pass (creates files)

Two-pass writer: emits files with placeholders, then resolves
cross-links.

```bash
node write.mjs
```

Watch the output:

- `+ core/people/jane-doe.md (created)` — new file.
- `+ core/people/jane-doe.md (updated)` — Notion `last_edited_at` was
  newer than the existing frontmatter; file was rewritten.
- `! oversized, skipped: …` — file would exceed 200 KB. The skip is
  recorded in `docs/MIGRATION-SKIPPED.md`; investigate before proceeding.

Skipped binaries are appended to `docs/MIGRATION-SKIPPED.md` as a
table. Review that file at the end of the run.

## 5. Validate

Sanity checks: frontmatter schema, cross-link resolution, size limits.

```bash
node validate.mjs
```

Exit code `0` = clean. Exit code `2` = errors printed above. Fix
upstream Notion data, rerun the writer, then revalidate.

The script ends with `git diff --stat` against the KB clone — your
eyeball pass before commit.

## 6. Eyeball + commit

Skim a handful of generated files in each entity type to confirm the
layout matches `KB-CONVENTIONS.md`. Then:

```bash
cd "$KB_ROOT"
git add -A
git status                                # one last look
git commit -m "seed: full migration from notion (snapshot $(date -u +%F))"
git tag v1.0.0
git push origin main --tags
```

Confirm the GitHub Actions lint workflow goes green
(<https://github.com/alphaanywhere/alpha-anywhere-kb/actions>). If it
fails, the writer emitted something the linter doesn't accept — fix
the script, rerun, and amend the commit.

## 7. Re-run loop (during dial-in)

You will probably run the writer 3–10 times before the output is
exactly right. The pattern is:

```bash
# Adjust scripts/migrate-from-notion/lib/migrators.mjs (or config.mjs)
node write.mjs
node validate.mjs
git -C "$KB_ROOT" diff --stat        # see what moved
```

When you accidentally write garbage:

```bash
git -C "$KB_ROOT" reset --hard HEAD
node write.mjs
```

The writer never deletes existing files (that's a maintainer
decision); the validator surfaces orphans you should clean up by
hand.

## 8. After v1.0.0 is tagged

1. Run the Notion slimdown per `docs/NOTION-SLIMDOWN-RUNBOOK.md`.
2. Cut `aa-ai-os-template` v2.0.0.
3. Move `scripts/migrate-from-notion/` out of the default install
   path or mark it archived in the README — the script is single-use
   and shouldn't tempt onboarding employees to run it.

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `NOTION_TOKEN environment variable not set` | env not exported in this shell | rerun `export NOTION_TOKEN=secret_…` |
| All DBs show 0 rows in inventory | integration not granted page access | revisit step 1.6 |
| `KB_ROOT environment variable not set` | env not exported | `export KB_ROOT=~/Alpha\ AI\ OS/alpha-anywhere-kb` |
| `Skipping assistant-updates source <id>: …` | integration lacks access to that specific page | grant access, rerun |
| Validate reports "broken markdown link" | a relation pointed at a Notion page outside the migration scope | add the page to `config.mjs` or remove the link upstream |
| Writer is very slow | Notion 3 req/s rate limit; the script retries with backoff | let it finish; expect ~20 min for ~1k rows |
