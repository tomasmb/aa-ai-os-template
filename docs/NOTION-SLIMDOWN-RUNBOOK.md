# Notion slimdown runbook

Maintainer-only. **Run only after** the KB migration has been validated
and `alpha-anywhere-kb@v1.0.0` is tagged and pushed
(see `docs/MIGRATION-RUNBOOK.md`). This is the procedure that turns
the Notion workspace into a thin pointer at the GitHub installer.

The work is reversible — pages are moved under an `Archived (pre-v2)`
parent rather than deleted — so a botched run is recoverable.

## 0. Why we do this

After the migration, anyone who lands on Notion should read **one
screen** and immediately move to GitHub. Today's hub still advertises
the AI Memory DBs, the zip download, the MCP setup — all of which are
either misleading or outright wrong post-v2.0.0. Slimming the hub
prevents new employees from following the old path by accident.

## 1. Snapshot before changes

Before you move or rewrite anything, export the current Notion hub
as PDF/HTML and store it under `docs/notion-snapshots/<YYYY-MM-DD>/`
in the assistant repo. This is the audit trail. Notion's revision
history is fine for short-term recovery but is bounded.

## 2. Create the `Archived (pre-v2)` parent page

Title: `🗄 Archived (pre-v2 — migrated to GitHub on YYYY-MM-DD)`.
Place it as a top-level page in the AlphaAnywhere workspace.

Body: a single Notion **callout block** (warning style) with this
text:

> **Frozen on YYYY-MM-DD.** Live source of truth is now
> [`tomasmb/alpha-anywhere-kb`](https://github.com/tomasmb/alpha-anywhere-kb).
> Do not edit — changes here are not synced. To update an entry,
> open the matching file in the GitHub repo or ask your assistant.

Take note of the Notion page ID; you will move pages under it next.

## 3. Move pages under the archive parent

Move every page that was migrated to the KB. Listed canonical IDs as
of v2.0.0 (cross-check against `docs/MIGRATION-INVENTORY.md` before
running):

| Page | Notion ID |
| --- | --- |
| `🧠 AI Memory` | `3492901d-7908-81ad-b05d-f812f2aa4131` |
| `📚 AI Memory — Archive` | `34b2901d-7908-816e-aa04-cd681e796e61` |
| `AI Memory — Privacy & Sensitivity` | `3492901d-7908-81ec-8db9-fd7a27254af2` |
| `👋 New Hire Onboarding` (DB) | `2922901d-7908-802a-b4d6-d0b79fb15722` |
| Each Core DB inside `🧠 AI Memory` | listed in `MIGRATION-INVENTORY.md` |
| Each Archive DB inside `📚 AI Memory — Archive` | listed in `MIGRATION-INVENTORY.md` |
| `Operating Framework` (root) | `2892901d-7908-8097-b23f-f06dbb41b4dc` — **only if mirrored** to `operating-framework/` already |

Move method: use the Notion MCP tool `notion-move-pages` with the
target as the archive parent ID from step 2. Alternatively, in the
Notion UI, drag each page onto the archive parent.

After every move, paste the URL into the chat with the assistant; the
assistant will spot any orphan that was missed because it knows the
inventory.

## 4. Rewrite the hub body

Page: [Alpha AI OS — V1](https://www.notion.so/3492901d790881df80e3fbfefd7e7b70)
(`3492901d-7908-81df-80e3-fbfefd7e7b70`).

Tool: `notion-update-page`.

Replace the entire body with the content below. This is the **whole
page** — no sub-bullets, no MCP setup, no zip download, no AI Memory
links. Target read time is 30 seconds.

```markdown
# Alpha AI OS

An AI assistant that knows you and Alpha. Five minutes to set up.
Updates itself after that.

## Set up — paste one line

**macOS / Linux** — open **Terminal**:

`curl -fsSL https://raw.githubusercontent.com/tomasmb/aa-ai-os-template/main/scripts/install.sh | bash`

**Windows** — open **PowerShell**:

`iwr -useb https://raw.githubusercontent.com/tomasmb/aa-ai-os-template/main/scripts/install.ps1 | iex`

The installer guides you the whole way: installs git + GitHub CLI,
signs you in to GitHub (creates an account if you don't have one),
creates an `Alpha AI OS` folder in your home directory, clones the
assistant + the company brain, and tells you how to open it in your
AI tool. If you don't have an AI tool yet, it recommends one and
links the download.

## After setup

Open `~/Alpha AI OS/alpha-assistant` in Claude Desktop / Cursor /
Claude Code / Codex CLI. Say hi. The assistant takes it from there.

## Stuck?

Ping `#ai-os` on Slack, or DM your manager.

---

*For admins:* setup, member invites, and migration history live in
[`docs/ADMIN-GUIDE.md`](https://github.com/tomasmb/aa-ai-os-template/blob/main/docs/ADMIN-GUIDE.md)
inside the assistant repo.
```

## 5. Strip residual `## Assistant Updates` sections

The migration script already imported every existing
`## Assistant Updates` bullet into `inbox/` files in the KB. Remove
the section from any page that **stays live** (i.e., any page that is
not getting moved under the archive parent). The MCP tool to use:

- `notion-fetch` to confirm the section still exists.
- `notion-update-page` with `command: replace_content` to drop the
  heading and its bullet list.

Don't bother with archived pages — they're frozen, leaving stale
sections is fine.

## 6. Spot-check live pages

After moves and edits, walk every page that **stayed live** outside
the archive (typically: hub, anything under Operating Framework if
not mirrored yet, ad-hoc team pages). For each one:

- Verify it doesn't link to a moved page without the `(archived)`
  qualifier.
- Verify it doesn't reference the old MCP setup or the zip download.
- Verify any `## Assistant Updates` section was removed in step 5.

## 7. Announce

Drop a short note in `#ai-os`:

> Notion is now read-only for AI memory. New brain entries live in
> the GitHub KB. Run the new installer (one line, link in the hub)
> if you haven't yet.

## 8. Verification checklist

- [ ] Hub page body matches the slim template above.
- [ ] No live page outside the archive subtree references AI Memory
      or the zip flow.
- [ ] All migrated DBs and pages live under the `Archived (pre-v2)`
      parent.
- [ ] Archive parent has the freeze callout at the top.
- [ ] `#ai-os` announcement posted.

## 9. Reversal procedure

If something goes wrong:

1. Restore the original hub body from the snapshot in step 1.
2. Move the affected pages back out of the archive parent.
3. Do **not** un-tag KB `v1.0.0` — the GitHub repo stays the source
   of truth even during a partial rollback.
