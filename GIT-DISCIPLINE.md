# GIT-DISCIPLINE.md — How the assistant uses git

> Behavior spec for every git operation the assistant runs against the KB
> repo (`alpha-anywhere-kb`) and against this assistant repo. Enforced by
> Contract Rule 16. Concrete failure scripts live in `CONFLICT-PLAYBOOK.md`.

## Mental model

The KB is a sibling git repo. Reads are local file ops (instant). Writes are
**atomic** git operations: pull-rebase → edit → commit → push. The window
between pull and push is < 5 seconds in practice, which keeps conflicts rare.
Concurrency is designed away by **one file per entity** + **append-only
inboxes with timestamped filenames**.

The assistant never force-pushes, never rebases pushed commits, never
rewrites history. Hard-forget is a **maintainer-run** procedure (see
`docs/ADMIN-GUIDE.md`).

## Session boot

1. Run `scripts/preflight` → confirms both repos are healthy.
2. Run `scripts/sync-kb` → `git pull --rebase` on the KB; surfaces a
   "since last session" briefing from `git log --since="<last_session_ts>"
   -- core/`. If nothing changed, skip the briefing.
3. Cache the boot timestamp in `memory/last-session.md`.

If preflight or sync fails, run `scripts/bootstrap` and explain plainly.

## Reads

- **First read of canonical entity files in a session** → no extra pull
  needed; sync-kb already ran at boot.
- **Subsequent reads later in the session** → if the last pull was > 5 min
  ago and the user is about to write, `git pull --rebase` first.
- **Inbox reads** → never need a refresh (timestamped, append-only).
- **Search** → always use `rg` over the local KB clone. Never round-trip
  to GitHub.

## Writes — the atomic promote

Every write goes through `scripts/promote` which runs:

```text
git -C "$KB" pull --rebase
<edit file>
git -C "$KB" add <path>
git -C "$KB" commit -m "<conventional commit message>"
git -C "$KB" push
```

Rules:

- **One promote = one commit.** Never batch unrelated changes into one
  commit. If a single observation produces two writes (e.g. an inbox
  entry AND a Core entity update), they are two separate commits.
- **Commit message format** — see `COMMIT-CONVENTIONS.md`. Conventional
  Commits with entity-type scope, no emojis, trailer `Promoted-By:
  <user-slug>`.
- **Push immediately.** Don't sit on local commits.
- **No commits to detached HEAD or non-`main` branches.** v2.0.0 uses
  direct commit + push to `main`. PR-based workflows are out of scope.

## Conflicts — never silent merge

If `git pull --rebase` fails with a merge conflict on an inbox file:

- **Cannot happen** by design (timestamped filenames). If it does, file a
  bug and abort the write.

If it fails on a Core/Archive entity file:

1. **Stop.** Do not auto-resolve.
2. Read both versions (yours-staged vs. theirs-incoming).
3. Summarize the diff in plain English to the user. Two sentences max.
4. Ask: *"Keep yours, theirs, or merge both?"* Wait for an explicit answer.
5. Apply the answer, finish the rebase, commit, push.
6. Append the resolution to `logs/conflict-log.md` (timestamp, file,
   chosen path).

Never use `git checkout --theirs` / `--ours` without the user's confirmation.

## Push failures

If `git push` fails (network, auth, rate limit):

1. Retry once with the same command.
2. If still failing, **queue** the intended write to `logs/pending-writes.md`
   with: timestamp, target path, full intended commit message, and the file
   diff.
3. Tell the user once per session: *"3 updates to the brain are queued —
   I'll push them when GitHub's reachable."*
4. The morning ritual replays the queue.
5. Never silently lose data. Never skip the queue.

## Hard rules (the things the assistant must never do)

- **Never** `git push --force` or `--force-with-lease`.
- **Never** `git reset --hard` on the KB without user-explicit consent
  + a tarball backup written first.
- **Never** rebase commits that are already pushed.
- **Never** commit to a branch other than `main` (in v2.0.0).
- **Never** rewrite history (`git filter-branch`, `git filter-repo`,
  interactive rebase that drops/squashes pushed commits). Hard-forget is
  maintainer-only.
- **Never** modify `.git/` internals.
- **Never** run a destructive op without first capturing the current state
  in `.backups/`.

## Identity

Every commit carries the user's name + email from `git config`.
Bootstrap reads `gh api user` on first run and sets:

```bash
git config --global user.name "<user's GitHub display name>"
git config --global user.email "<user's GitHub primary email>"
```

If the user already has globals set, leave them alone. The trailer
`Promoted-By: <user-slug>` in commit messages adds an extra layer of
attribution that survives email changes.

## Auto-update of the assistant repo

The morning ritual runs `git pull --rebase` on the **assistant** repo too,
so users always have the latest Contract / packs / scripts. Editable files
(USER.md, IDENTITY.md, etc.) are gitignored locally — see Contract Rule 16
and `scripts/bootstrap` for the templates pattern. Conflicts on the
assistant repo's own pull are reported same as KB conflicts.

## What "atomic" actually buys us

With one-file-per-entity + 5-second pull-to-push window:

- Two assistants editing **different** entities → no interaction at all.
- Two assistants editing the **same** entity within 5s → second one
  rebases cleanly on top (line-disjoint changes) or surfaces a conflict
  conversation (overlap). Honest, not silent.
- Two assistants writing **inbox** entries simultaneously → never collide
  (timestamped filenames).

This is why git works as the brain: the conflict surface is engineered
small, not just hoped to be small.
