# scripts/migrate-from-notion

Maintainer-run, one-time migration from Notion to the
`alpha-anywhere-kb` git repo. **Not** part of user bootstrap.

The script is idempotent — running it twice writes the same files.
Re-runs during the migration period are explicitly allowed (and
expected, while you tune the mapping).

## Prereqs

- Node 20+
- A Notion **internal integration token** with read access to every
  page that needs migrating. Get one at
  https://www.notion.so/profile/integrations → "+ New integration"
  → grant access to the Alpha workspace, then **manually add the
  integration to each top-level Notion page** (Notion's permission
  model: integrations are page-scoped, not workspace-scoped).
- A local clone of `alpha-anywhere-kb/` to write into.

## Files

```text
scripts/migrate-from-notion/
  README.md            this file
  package.json         deps (only @notionhq/client and js-yaml)
  config.mjs           database IDs → KB target paths + entity types
  inventory.mjs        read-only audit; updates docs/MIGRATION-INVENTORY.md
  write.mjs            two-pass writer (placeholder slugs, then link rewrite)
  validate.mjs         post-write sanity (frontmatter, links, sizes, counts)
  lib/
    notion.mjs         thin wrapper around @notionhq/client
    blocks-to-md.mjs   Notion block tree → GitHub-flavored markdown
    frontmatter.mjs    YAML frontmatter helpers
    slug.mjs           kebab-case slug generation
    paths.mjs          KB path resolution
```

## Quick start

```bash
cd ~/Repos/tomasmb/aa-ai-os-template/scripts/migrate-from-notion
npm install

export NOTION_TOKEN=secret_…
export KB_ROOT=~/Alpha\ AI\ OS/alpha-anywhere-kb

# 1. Inventory pass — read-only. Updates docs/MIGRATION-INVENTORY.md
#    with row counts and skipped-binary report.
node inventory.mjs

# 2. Writer pass — emits markdown files into $KB_ROOT/. Idempotent.
#    Two passes: first emits files with placeholder slugs for cross-
#    references, then rewrites links once every target slug is known.
node write.mjs

# 3. Validate — fails non-zero if anything is malformed. Print
#    git diff --stat at the end for the maintainer's eyeball pass.
node validate.mjs

# 4. Commit + tag (maintainer):
cd "$KB_ROOT"
git add -A
git commit -m "seed: full migration from notion (snapshot $(date +%F))"
git tag v1.0.0
git push origin main --tags
```

## Skips

- Files > 200 KB are skipped with a row in `docs/MIGRATION-SKIPPED.md`.
- Non-text MIME (images, PDFs, attachments) — same.
- The maintainer reviews the skip report and uploads any genuinely
  important attachments to Drive / S3, then patches the relevant KB
  entry to link the new external URL.

## Idempotency

- Slug derivation is deterministic — re-running the writer produces
  the same filenames.
- The writer only rewrites the body when the Notion `last_edited_at`
  is newer than the local file's `updated_at` frontmatter.
- The inventory step is read-only.

## What this script does NOT do

- It does not push to git. Maintainer reviews + commits manually.
- It does not delete files in the KB. If a Notion page is moved or
  removed, the corresponding KB file lingers until the maintainer
  removes it. The validator surfaces these as "orphans".
- It does not migrate Notion's permissions model — the locked
  decision is single-repo, no row-level perms.
