# rituals-log.md

> Append-only audit of scheduled ritual fires (Contract §15 /
> `packs/company-rituals.md`). The assistant reads this log at session
> start to detect missed rituals (for graceful fallback) and to measure
> engagement.

## Format

One line per fired ritual. Newest at the top.

```text
<YYYY-MM-DD HH:MM> <morning|eod|weekly> fired | offer=<action> | accepted=<y/n>
```

Fields:

- **timestamp** — local time the ritual fired
- **ritual** — `morning`, `eod`, or `weekly`
- **offer** — one-line summary of the offer the assistant made to the user
- **accepted** — `y` if user engaged with the offer, `n` if declined or
  ignored, `d` if deferred to a later time

## Entries

<!-- Assistant appends here. Never edit by hand. -->
