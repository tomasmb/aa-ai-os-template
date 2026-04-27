# ADMIN-GUIDE.md — Alpha AI OS administration

> Maintainer-only runbook. Covers GitHub org setup, member invites, KB
> seeding, hard-forget via `git filter-repo`, the upgrade path to
> Enterprise SCIM auto-provisioning, and the Notion → KB migration.
>
> **You are the operator** — these procedures are not assistant-runnable
> and never executed by an end-user laptop. Prereqs: `gh` CLI authed
> against an account with org admin rights, write access to both repos.

## 1. One-time org + repo setup

1. **Create the org** at https://github.com/organizations/new — name it
   `alphaanywhere` (the assistant + bootstrap scripts hard-code this).
2. **Move both repos under the org.** From the old owner's account,
   transfer:
   - `aa-ai-os-template` → `alphaanywhere/aa-ai-os-template`
   - `alpha-anywhere-kb` → `alphaanywhere/alpha-anywhere-kb`

   `gh repo transfer <old-owner>/<repo> alphaanywhere`
3. **Set repo visibility:**
   - `gh repo edit alphaanywhere/aa-ai-os-template --visibility public --accept-visibility-change-consequences`
     — required so the one-line installer can clone before the user has
     auth set up.
   - `gh repo edit alphaanywhere/alpha-anywhere-kb --visibility private`
     — the company brain stays gated.
4. **Create the access team:**
   ```bash
   gh api orgs/alphaanywhere/teams \
       -f name="employees" \
       -f description="Read+write access to alpha-anywhere-kb" \
       -f privacy=closed
   ```
5. **Grant the team write access to the KB:**
   ```bash
   gh api orgs/alphaanywhere/teams/employees/repos/alphaanywhere/alpha-anywhere-kb \
       -X PUT -f permission=push
   ```
6. **Optionally grant the team triage on the assistant repo** (for opening
   issues / suggesting Contract changes) — leave write off so daily
   `git pull` updates flow only from maintainers.

After this section, the installer flow in `setup/macos.md` works
end-to-end.

## 2. Inviting a new employee (the daily admin task)

Bootstrap captures the new hire's GitHub username on first run and tells
them to send it to you. When you have the username:

```bash
USERNAME="<their-gh-username>"
gh api orgs/alphaanywhere/memberships/$USERNAME -X PUT -f role=member
gh api orgs/alphaanywhere/teams/employees/memberships/$USERNAME -X PUT \
    -f role=member
```

The user reruns `bash ~/Alpha\ AI\ OS/alpha-assistant/scripts/bootstrap.sh`
(or `.ps1`); the KB clone now succeeds, `memory/kb-status.md` flips off
`pending`, and onboarding Block 8 runs on the next session.

### Bulk invite

If you have a CSV of `username,email` pairs:

```bash
while IFS=, read -r username _; do
  gh api orgs/alphaanywhere/memberships/"$username" -X PUT -f role=member
  gh api orgs/alphaanywhere/teams/employees/memberships/"$username" \
       -X PUT -f role=member
done < new-hires.csv
```

### Removing access

```bash
gh api orgs/alphaanywhere/memberships/$USERNAME -X DELETE
```

This revokes the KB clone — the user's local clone keeps working until
their next `git pull --rebase`, at which point it 403s. They keep their
local state; nothing on disk is wiped. (See §5 for true destruction.)

## 3. Seeding the KB (one-time, before first user joins)

If the KB repo is still empty, follow `packs/company-brain-seed.md` from
your own assistant install. Summary:

```bash
mkdir -p ~/Alpha\ AI\ OS
cd ~/Alpha\ AI\ OS
gh repo clone alphaanywhere/alpha-anywhere-kb

cd alpha-anywhere-kb
# 1. README, KB-CONVENTIONS, COMMIT-CONVENTIONS, CONFLICT-PLAYBOOK
# 2. .github/workflows/lint.yml, .gitattributes, CODEOWNERS
# 3. core/{people,projects,meetings,goals,decisions,insights}/.gitkeep
# 4. archive/{meeting-notes,decision-rationale,playbooks,glossary,
#             students,projects,onboarding,onboarding/_templates,
#             roles,teams}/.gitkeep
# 5. inbox/.gitkeep
# 6. operating-framework/README.md (entry point)

git add -A
git commit -m "seed: initial KB scaffold"
git push origin main
git tag v1.0.0 && git push --tags
```

The exact contents per file are in `packs/company-brain-seed.md`.

## 4. Notion → KB migration (one-time, before cutting v2.0.0)

The migration is a maintainer-run Node script. End-to-end runbook lives
in `docs/MIGRATION-RUNBOOK.md`. Quick summary:

1. **Inventory pass** (read-only):
   `node scripts/migrate-from-notion/inventory.mjs` →
   produces `docs/MIGRATION-INVENTORY.md`. Review scope.
2. **Writer pass** (idempotent):
   `NOTION_TOKEN=secret_… node scripts/migrate-from-notion/write.mjs \
       --kb ~/Alpha\ AI\ OS/alpha-anywhere-kb` → emits Core + Archive +
   inbox files.
3. **Validate**:
   `node scripts/migrate-from-notion/validate.mjs --kb …` → must exit 0
   (all cross-refs resolve, frontmatter parses, no binaries, file
   counts match inventory).
4. **Commit + tag** the KB:
   ```bash
   git -C ~/Alpha\ AI\ OS/alpha-anywhere-kb add -A
   git -C ~/Alpha\ AI\ OS/alpha-anywhere-kb commit \
       -m "seed: full migration from notion (snapshot $(date +%F))"
   git -C ~/Alpha\ AI\ OS/alpha-anywhere-kb tag v1.0.0
   git -C ~/Alpha\ AI\ OS/alpha-anywhere-kb push origin main --tags
   ```
5. **Notion slimdown**: follow `docs/NOTION-SLIMDOWN-RUNBOOK.md`
   *only after* steps 1–4 succeed and you've sanity-checked the new KB
   from a clean clone.

## 5. Hard-forget — wipe data from KB history

The Contract's Rule 11 promises tombstones in current state. **History
retention is real** — anything ever pushed to `main` is recoverable
unless the maintainer rewrites history. This procedure is the escape
hatch and is **never** run by the assistant.

### When to use it

- Personally identifiable info promoted by mistake.
- A user explicitly invokes their right to be forgotten (legal /
  contractual).
- A secret leaked into a commit.

Anything else (someone changed their mind about a meeting note) → use
a normal forward edit, not history rewrite. History rewrites break
every cloned working copy on every laptop.

### Procedure

```bash
# 1. Coordinate. Tell every active user: "do not push for the next 30
#    minutes — KB history is being rewritten." Wait for ack.

# 2. Mirror-clone outside any working copy.
cd /tmp
git clone --mirror git@github.com:alphaanywhere/alpha-anywhere-kb.git
cd alpha-anywhere-kb.git

# 3. Run filter-repo. Either delete a path entirely:
git filter-repo --path archive/students/jane-doe.md --invert-paths

#    or scrub a string everywhere it appears:
git filter-repo --replace-text replacements.txt
#    where replacements.txt is one rule per line, e.g.:
#      jane.doe@example.com==>REDACTED

# 4. Force-push the rewritten history.
git push --force --mirror

# 5. On every active user's laptop, run:
cd "~/Alpha AI OS/alpha-anywhere-kb"
git fetch --all
git reset --hard origin/main

#    Or simpler: have them re-clone. The bootstrap script handles a
#    missing/dirty KB cleanly.

# 6. GitHub also retains old SHAs for ~30 days in the reflog. To purge:
gh api repos/alphaanywhere/alpha-anywhere-kb/dispatches \
    -f event_type=ghc-purge   # if you have an Action that calls
                              # the GH support API; otherwise contact
                              # GitHub support to purge.
```

### After hard-forget

Append to `archive/_history/forgets.md` in the KB:

```yaml
---
date: <YYYY-MM-DD>
performed_by: <maintainer-username>
target: <path or pattern that was rewritten>
reason: <one-line reason>
---
```

The tombstone is the audit trail; it's the only place a forget remains
visible after history rewrite.

## 6. Auto-invite (v2.x optional)

A small webhook that takes a GitHub username and runs the invite
one-liner removes the human handoff. Spec:

- Tiny serverless endpoint (Cloudflare Worker / Lambda) at
  `https://invite.alpha-os.alphaanywhere.com`.
- Authenticated via shared secret baked into the bootstrap script.
- Body: `{"username": "<gh-handle>", "email": "<work-email>"}`.
- Server runs the `gh api ...` invite calls server-side using a fine-
  grained PAT scoped to org+team admin only.
- Bootstrap POSTs after `gh api user`. Success → "you've been added,
  rerun me." 4xx → fall back to the manual flow.

Out of scope for v2.0.0; document and budget for v2.1.

## 7. Domain-based auto-provision (Enterprise upgrade path)

Native domain auto-grant requires **GitHub Enterprise Cloud** + SAML
SSO + SCIM. Path:

1. Upgrade the org to GitHub Enterprise Cloud.
2. In the org settings → Authentication security, enable SAML SSO with
   the IdP (Google Workspace, Okta, Azure AD).
3. Enable SCIM provisioning. The IdP becomes the source of truth for
   org membership.
4. Create an IdP group `alpha-employees` and tie it to the
   `alphaanywhere/employees` GitHub team. SCIM auto-syncs group
   members.
5. Anyone added to the IdP group → auto-invited to the GitHub org +
   team within minutes. No manual invite step.

This eliminates §2 (the daily invite task) once configured. Cost:
Enterprise Cloud per-seat fees + IdP integration time. Worth it once
~20+ employees use the system.

## 8. Updating the assistant repo (publishing changes to all employees)

Daily ritual already runs `git -C ~/Alpha\ AI\ OS/alpha-assistant pull
--rebase --autostash` for every user (see `rituals/README.md`). To ship
a change:

```bash
cd ~/Alpha\ AI\ OS/alpha-assistant     # your maintainer clone
# edit files
git checkout -b feat/<short-name>
git add -A
git commit -m "feat: <conventional-commit-message>"
git push origin feat/<short-name>
gh pr create --fill --base main
# self-review + merge to main
gh pr merge --squash --delete-branch
```

Within 24h every active employee's morning ritual pulls the change. For
breaking changes (new required scripts, Contract additions affecting
boot), bump `manifest.json` `version` and `.version`, add an entry to
the `changelog` array — the morning ritual notices a version bump and
surfaces a one-line "what's new" message to the user.

## 9. KB linting / CI

`alpha-anywhere-kb/.github/workflows/lint.yml` runs on every push and
PR. It checks:

- Frontmatter parses as YAML and matches the schema in
  `KB-CONVENTIONS.md`.
- Filenames are kebab-case ASCII.
- No binary files >200 KB and no non-text MIME.
- `notes_path:` / `body_path:` / `rationale_path:` link to files that
  exist.

If lint fails on `main`, fix forward — never disable the check. The
lint config itself lives in the KB repo, not here.

## 10. Useful gh queries

```bash
# Who's in the org
gh api orgs/alphaanywhere/members --paginate --jq '.[].login'

# Who has KB access via the team
gh api orgs/alphaanywhere/teams/employees/members --paginate \
    --jq '.[].login'

# Who's pending an invite
gh api orgs/alphaanywhere/invitations --paginate \
    --jq '.[] | {login, email, created_at}'

# Last commit on the KB
gh api repos/alphaanywhere/alpha-anywhere-kb/commits/main \
    --jq '{sha: .sha, when: .commit.author.date, msg: .commit.message}'

# Total KB file count by entity type (run from a local clone)
for d in core/people core/projects core/meetings core/decisions \
         core/insights core/goals; do
  printf '%-20s %d\n' "$d" "$(find "$d" -name '*.md' | wc -l)"
done
```

## 11. When to escalate to GitHub support

- A force-mirror push fails reflog purge: open a support ticket
  referencing the SHA you need expunged. Plan ~48h.
- SCIM sync stuck: ticket via Enterprise channel.
- Suspected security incident on the KB: rotate any leaked secrets
  *first*, then run §5, *then* file the ticket. Order matters.
