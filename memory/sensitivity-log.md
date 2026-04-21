# sensitivity-log.md — Audit of the sensitivity gate

> Every time the assistant asked before writing to the shared brain, the answer
> is logged here. Every *"forget that"* / *"that was private"* is also logged.
> The user can read this any time to see exactly what has and hasn't been
> shared, and to spot-check the assistant's behavior.

## Format

Append-only. One entry per event. Newest at the top.

```text
## <YYYY-MM-DD HH:MM> — <event type>
- trigger: <short quote or description>
- category: <which sensitivity heuristic fired>
- assistant asked: <yes / no — defaulted local>
- user answer: <share / local / skipped>
- action: <wrote to <DB.Row> / stayed local / deleted <DB.Row>>
- reason (if forget): <user's stated reason or "not given">
```

## Example entries

```text
## 2026-05-03 14:12 — asked before writing
- trigger: "Marco's been shipping late on the parent dashboard"
- category: negative feedback about named colleague
- assistant asked: yes
- user answer: local
- action: stayed local — noted in memory/relationships.md only

## 2026-05-04 09:42 — forget request
- trigger: user said "actually, forget that last bit about comp"
- category: compensation / career
- assistant asked: n/a (retroactive)
- user answer: n/a
- action: deleted 2 entries from today's daily note; no brain write had occurred
- reason: not given
```

## Entries

<!-- The assistant appends below this line. Do not edit by hand. -->
