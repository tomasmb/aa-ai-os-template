# COMMIT-CONVENTIONS.md — Commit message format for the assistant

> Every commit the assistant makes — to the KB or to the assistant repo —
> follows this format. The same conventions are mirrored in the KB's own
> `COMMIT-CONVENTIONS.md` so humans editing by hand match the same style.

## Format

```text
<type>(<scope>): <subject>

<optional body — 1–3 sentences, plain English>

Promoted-By: <user-slug>
Source: conversation | meeting | manual
Confidence: high | medium | low
```

- **No emojis.** Ever. They make `git log --oneline` noisy and `rg`-unfriendly.
- **Subject ≤ 72 characters.** Imperative mood. No trailing period.
- **Body wraps at 100 characters.** Explain *why*, not *what* — the diff
  shows the what.
- **Trailers are mandatory** for assistant-authored commits. Humans can
  skip them.

## Allowed `<type>` values

| Type | When |
|---|---|
| `promote` | Inbox writes (Rule 9) and direct Core/Archive entity writes (Rule 14) |
| `consolidate` | Owner-led merge of inbox items into a canonical entity |
| `forget` | Tombstone deletes triggered by *"forget X"* |
| `seed` | Bootstrap-time first creation of an entity (e.g. user's own People row) |
| `docs` | KB conventions / framework / readme edits |
| `chore` | Renames, lint fixes, retention pruning |
| `fix` | Repair of a malformed file or broken cross-reference |

## Allowed `<scope>` values

Entity-type plural matching the KB folder name:

`people` · `projects` · `meetings` · `goals` · `decisions` · `insights` ·
`students` · `playbooks` · `glossary` · `framework` · `inbox` · `repo`

## Examples

**Inbox promote:**

```text
promote(insights): churn signal from Tuesday team sync

Three coaches independently flagged Q2 retention dip on long-tenure students.
Worth surfacing to the leadership team for the next planning cycle.

Promoted-By: jane-doe
Source: meeting
Confidence: medium
```

**Core entity update:**

```text
promote(people): add Slack handle to Jane Doe

Promoted-By: tomas-mb
Source: conversation
Confidence: high
```

**Owner consolidation:**

```text
consolidate(projects): roll up 6 inbox items into Q2-churn brief

Folded the last month of inbox notes into the canonical project page.
Removed promoted-by attribution per consolidation policy.

Promoted-By: jane-doe
Source: manual
Confidence: high
```

**Forget:**

```text
forget(inbox): remove 3 entries about salary discussion

Promoted-By: tomas-mb
Source: manual
Confidence: high
```

## What never lands in a commit message

- Raw conversation transcripts.
- Sensitive content (Rule 14 sensitivity gate applies to commit messages too).
- Anonymous promotions. Always include `Promoted-By:`.
- Multi-purpose commits ("update people and projects and add insight"). Split
  into atomic commits, one entity per commit.
