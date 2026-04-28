# ADMIN-GUIDE.md — Alpha AI OS administration

> Maintainer-only runbook. Covers current repo layout, inviting and
> removing employees, KB seeding history, hard-forget via
> `git filter-repo`, and the eventual upgrade path to a GitHub org +
> SCIM auto-provisioning.
>
> **You are the operator** — these procedures are not assistant-runnable
> and never executed by an end-user laptop. Prereqs: `gh` CLI authed
> as `tomasmb` (admin on both repos).

## 1. Repo state (current)

Both repos live under the personal account `tomasmb`:

- `tomasmb/aa-ai-os-template` — **public**. The assistant scaffold +
  installer. Public so the one-line `curl | bash` works before the
  user has any GitHub auth.
- `tomasmb/alpha-anywhere-kb` — **private**. The company brain.
  Collaborator-gated.

Org migration (e.g., `trilogy-group`) is deferred. See `TODO-LOCAL.md`
for the steps when you're ready. Until then, all member management is
direct collaborator add/remove on the private KB repo.

Sanity check from a fresh `gh auth login`:

```bash
gh repo view tomasmb/aa-ai-os-template \
    --json visibility,viewerCanAdminister
gh repo view tomasmb/alpha-anywhere-kb \
    --json visibility,viewerCanAdminister
```

Both should report `viewerCanAdminister: true` for you.

## 2. Inviting a new employee (the daily admin task)

Bootstrap captures the new hire's GitHub username on first run and
tells them to send it to you. When you have the username:

```bash
USERNAME="<their-gh-username>"
gh api -X PUT \
    repos/tomasmb/alpha-anywhere-kb/collaborators/$USERNAME \
    -f permission=push
```

GitHub emails the invitation. Once they **accept** (one click in the
email or in their notifications), they have read+write access to the
KB. Then have them rerun
`bash ~/Alpha\ AI\ OS/alpha-assistant/scripts/bootstrap.sh` (or
`.ps1`); the KB clone now succeeds, `memory/kb-status.md` flips off
`pending`, and onboarding Block 8 runs on the next session.

`aa-ai-os-template` is public — no invite needed for the assistant
scaffold itself.

### Bulk invite

If you have a CSV of `username,_` pairs:

```bash
while IFS=, read -r username _; do
  gh api -X PUT \
      repos/tomasmb/alpha-anywhere-kb/collaborators/"$username" \
      -f permission=push
done < new-hires.csv
```

### Check pending invites

```bash
gh api repos/tomasmb/alpha-anywhere-kb/invitations \
    --jq '.[] | {invitee: .invitee.login, created_at}'
```

### Removing access

```bash
gh api -X DELETE \
    repos/tomasmb/alpha-anywhere-kb/collaborators/$USERNAME
```

This revokes the KB clone — the user's local clone keeps working until
their next `git pull --rebase`, at which point it 403s. They keep
their local state; nothing on disk is wiped. (See §5 for true
destruction.)

## 3. Seeding the KB (already done — kept for record)

The KB was seeded from Notion on 2026-04-27. If you ever need to
re-seed from scratch, the procedure is in
[`packs/company-brain-seed.md`](../packs/company-brain-seed.md);
end-to-end Notion-source migration is in
[`docs/MIGRATION-RUNBOOK.md`](MIGRATION-RUNBOOK.md).

## 4. Notion → KB migration (one-time, before cutting v2.0.0)

Done on 2026-04-27. Slimdown of the legacy Notion hub completed the
same day per [`docs/NOTION-SLIMDOWN-RUNBOOK.md`](NOTION-SLIMDOWN-RUNBOOK.md).
The maintainer-run Node script lives in
[`scripts/migrate-from-notion/`](../scripts/migrate-from-notion).

If you ever re-run it (e.g., to migrate a sister workspace), the
quick form is:

```bash
node scripts/migrate-from-notion/inventory.mjs
NOTION_TOKEN=secret_… node scripts/migrate-from-notion/write.mjs \
    --kb ~/Alpha\ AI\ OS/alpha-anywhere-kb
node scripts/migrate-from-notion/validate.mjs --kb …
git -C ~/Alpha\ AI\ OS/alpha-anywhere-kb add -A \
    && git -C ~/Alpha\ AI\ OS/alpha-anywhere-kb commit \
        -m "seed: full migration from notion (snapshot $(date +%F))" \
    && git -C ~/Alpha\ AI\ OS/alpha-anywhere-kb push origin main
```

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
git clone --mirror git@github.com:tomasmb/alpha-anywhere-kb.git
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

# 6. GitHub also retains old SHAs for ~30 days in the reflog. To
#    purge sooner, contact GitHub support with the SHAs you need
#    expunged (no self-serve API for personal repos).
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

The tombstone is the audit trail; it's the only place a forget
remains visible after history rewrite.

## 6. Auto-invite (future, when in an org)

A small webhook that takes a GitHub username and runs the invite
one-liner removes the human handoff. Defer until the repos live in a
real GitHub org — collaborator-style invites on a personal account
require the maintainer's PAT and don't justify the infra. Spec
captured in `TODO-LOCAL.md`.

## 7. Domain-based auto-provision (Enterprise upgrade path)

Native domain auto-grant requires **GitHub Enterprise Cloud** + SAML
SSO + SCIM. Not applicable to the current personal-account layout.
When the repos move to an org (see `TODO-LOCAL.md`), the path is:

1. Upgrade the org to GitHub Enterprise Cloud.
2. Org settings → Authentication security → enable SAML SSO with
   the IdP (Google Workspace, Okta, Azure AD).
3. Enable SCIM provisioning. The IdP becomes the source of truth for
   org membership.
4. Create an IdP group `alpha-employees` and tie it to a GitHub team
   `<org>/employees`. SCIM auto-syncs group members.
5. Anyone added to the IdP group → auto-invited to the GitHub org +
   team within minutes. No manual invite step.

Eliminates §2 (the daily invite task) once configured. Cost:
Enterprise Cloud per-seat fees + IdP integration time. Worth it once
~20+ employees use the system.

## 8. Updating the assistant repo (publishing changes to all employees)

Daily ritual already runs `git -C ~/Alpha\ AI\ OS/alpha-assistant pull
--rebase --autostash` for every user (see `rituals/README.md`). To
ship a change:

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

Within 24h every active employee's morning ritual pulls the change.
For breaking changes (new required scripts, Contract additions
affecting boot), bump `manifest.json` `version` and `.version`, add an
entry to the `changelog` array — the morning ritual notices a version
bump and surfaces a one-line "what's new" message to the user.

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
# Who has KB access right now (accepted collaborators)
gh api repos/tomasmb/alpha-anywhere-kb/collaborators \
    --paginate --jq '.[].login'

# Pending invites
gh api repos/tomasmb/alpha-anywhere-kb/invitations \
    --paginate --jq '.[] | {login: .invitee.login, created_at}'

# Last commit on the KB
gh api repos/tomasmb/alpha-anywhere-kb/commits/main \
    --jq '{sha: .sha, when: .commit.author.date, msg: .commit.message}'

# Total KB file count by entity type (run from a local clone)
for d in core/people core/projects core/meetings core/decisions \
         core/insights core/goals core/teams; do
  printf '%-20s %d\n' "$d" "$(find "$d" -name '*.md' 2>/dev/null | wc -l)"
done
```

## 11. When to escalate to GitHub support

- A force-mirror push fails reflog purge: open a support ticket
  referencing the SHA you need expunged. Plan ~48h.
- Suspected security incident on the KB: rotate any leaked secrets
  *first*, then run §5, *then* file the ticket. Order matters.
