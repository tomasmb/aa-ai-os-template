# CONFLICT-PLAYBOOK.md — Concrete recipes for every git failure

> Read top-to-bottom on first encounter. Each scenario has a deterministic
> recipe. Never improvise. Never silent merge.

## Scenario 1 — `git pull --rebase` fails on an inbox file

**Cannot happen by design.** Inbox filenames are timestamped to second
resolution + `<entity-type>_<slug>` so two assistants never write the same
filename. If it does happen:

1. Abort the rebase: `git rebase --abort`.
2. Log the impossible event to `logs/conflict-log.md` with both filenames.
3. Tell the user: *"Something weird just happened with the brain — I'm
   pausing writes for this session. Please ping the admin."*
4. Disable inbox writes for the rest of the session.

## Scenario 2 — `git pull --rebase` succeeds, no conflict, just new commits

This is the normal case. The "since last session" briefing surfaces in the
morning ritual / first response.

- Diff: `git log --oneline <last_session_sha>..HEAD -- core/`
- Friendly summary: top 5 entity changes by file count.
- Skip the briefing if zero changes.

## Scenario 3 — `git pull --rebase` fails with a merge conflict on a Core file

```text
CONFLICT (content): Merge conflict in core/people/jane-doe.md
```

Recipe:

1. **Stop.** Do not edit the conflict markers automatically.
2. Read the three versions: `--ours` (the local pre-rebase state),
   `--theirs` (the incoming remote), and the merge-base.
3. Summarize the difference in plain English. Two sentences max.
   *"Someone added Jane's Slack handle 3 minutes ago; I was about to add
   her phone number. Both fit — want me to merge both or pick one?"*
4. Wait for an explicit user answer: `keep mine` / `keep theirs` /
   `merge both`.
5. Apply the chosen path:
   - **keep mine** → `git checkout --ours <file>` then `git add <file>`.
   - **keep theirs** → `git checkout --theirs <file>` then `git add <file>`.
   - **merge both** → hand-edit the file resolving markers, `git add <file>`.
6. `git rebase --continue`.
7. `git push`.
8. Append to `logs/conflict-log.md`: timestamp, file, both versions,
   chosen resolution.

## Scenario 4 — `git pull --rebase` fails with a delete/modify conflict

`git status` shows: `deleted by them`, modified by us (or vice versa).

Recipe:

1. Stop.
2. Tell the user plainly: *"Someone deleted Jane's people file while I was
   adding to it. Want me to keep my updates (recreates the file) or accept
   the delete?"*
3. On *"keep mine"* → `git add <file>` (re-adds with our content) →
   continue rebase.
4. On *"accept delete"* → `git rm <file>` → continue rebase.
5. Push.

## Scenario 5 — `git push` rejected (non-fast-forward)

This means a commit landed on `origin/main` after our pull but before our
push.

Recipe:

1. `git pull --rebase` again.
2. If clean → push. Done.
3. If conflict → run Scenario 3 or 4.
4. Never `git push --force`. Never.

## Scenario 6 — `git push` fails with auth error

```text
remote: Permission denied (publickey).
```

or

```text
remote: HTTP 401
```

Recipe:

1. Run `gh auth status`. If signed-out, walk the user through
   `gh auth login --web`.
2. If signed-in but lacking org access (HTTP 403/404 on the KB repo),
   write `memory/kb-status.md` = `pending`, capture the GH username, and
   tell the user: *"GitHub doesn't let me read the company brain yet —
   I've sent the admin your username (<username>); they'll add you in a
   few minutes. I'll keep working in personal-only mode until then."*
3. Queue the failed write to `logs/pending-writes.md`.

## Scenario 7 — Network unreachable

`git fetch` / `git push` times out.

Recipe:

1. Retry once after 5 seconds.
2. Queue any pending write to `logs/pending-writes.md`.
3. Tell the user: *"GitHub's unreachable — I'll keep working from local
   memory and push when it's back."*
4. Read-only operations (entity lookups in `core/`) still work.
5. The morning ritual retries the queue.

## Scenario 8 — Local working tree is dirty at boot

Preflight detects uncommitted changes from a previous crash.

Recipe:

1. `git status -s` to see what's dirty.
2. **Never** auto-discard. Tell the user: *"Last session crashed mid-write —
   I have local changes to `core/people/jane-doe.md` that didn't push.
   Want me to push them now or throw them away?"*
3. On *"push them"* → review diff, commit with a `recovered:` prefix on the
   commit message, push.
4. On *"throw them away"* → `git stash push -m "boot-recovery <ts>"`. Stash
   sits there for 7 days; the next bootstrap-clean offers to drop it.

## Scenario 9 — Wrong branch checked out

Preflight detects HEAD is not on `main`.

Recipe:

1. Tell the user: *"The brain is on a non-main branch — restoring."*
2. `git checkout main && git pull --rebase`.
3. If the previous branch had commits, `git stash push -m "branch-recovery"`
   first.

## Scenario 10 — `.git/` corruption

`git status` returns a fatal error.

Recipe:

1. Stop all writes. Read-only operations stop too.
2. Tell the user: *"The brain repo on disk is broken — I can't read or
   write to it safely. Want me to re-clone it? Your local memory is
   untouched."*
3. On consent: rename the broken folder to `alpha-anywhere-kb.broken-<ts>`,
   re-clone fresh, retry boot.
4. Never auto-delete the broken folder. Leave it for forensics.

## What every recipe has in common

1. **Stop first, decide second.** No silent moves.
2. **One sentence to the user.** Don't dump git output.
3. **Explicit user consent** before any destructive operation.
4. **Log every resolution** to `logs/conflict-log.md`.
5. **Never force-push, never rewrite history.**
