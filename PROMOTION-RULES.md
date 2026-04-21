# PROMOTION-RULES.md — What flows from me to Notion

> These rules are read once at session start and enforced at every potential
> promotion. Defaults err toward keeping Notion lean. The Contract §9 overrides
> anything here if there's a conflict.

## What to promote (by scope)

### Project scope — promote when
- a **decision** changes execution (chosen approach, cancelled direction)
- a **blocker** affects multiple contributors
- a **status change** others need to know (shipped, blocked, delayed)
- a **meeting** created shared follow-ups

### Team scope — promote when
- a **workflow** is reusable across the team (a process, a template, a checklist)
- a **recurring issue** is identified across multiple people
- a **norm or ritual** changes (new standup format, new review cadence)
- a **template** becomes durable (the right way to write PR descriptions, for
  example)

### Org scope — promote when
- a **policy or definition** changes (KPI definitions, role ladders)
- **multiple teams** need the same insight
- a **cross-cutting pattern** is confirmed from multiple data points

## Keep local (never promote)

- Private reflections, venting, personal context.
- Raw conversation transcripts.
- Anything the user explicitly marked private.
- Drafts before the user has confirmed them.
- Things only useful to this one person on this one day.

## How to promote (the mandatory format)

Auto-promotes go into the target page's `## Assistant Updates` section as a
bullet of this shape:

```
- **<title — one line>** — <1–3 sentence summary>.
  Decision / Context / Who / Next step: <inline if relevant>
  _(promoted by <user's first name>'s assistant, YYYY-MM-DD)_
```

### Hard rules
1. **Always summarize.** Never paste raw quotes longer than one sentence.
2. **Always dedupe.** Scan the `## Assistant Updates` section + nearby canonical
   content for a semantic match. If found, **update** the existing entry instead
   of appending a new one.
3. **Always tag** the entry with user + date so owners can trace it.
4. **Never auto-create** a new Notion page. Ask the user once if a create is
   needed ("There's no page for 'Billing migration' yet — want me to create one
   under Projects?").
5. **Never write outside** the `## Assistant Updates` section.
6. **Rate limit** — no more than one promote per entity per hour. Batch if
   needed.
7. **Log everything** — write the Notion URL and the entry text to
   `logs/session-log.md`.

## What owners see (weekly consolidation rhythm)

Page owners receive a weekly email digest (see `digests/email-weekly.md` and
Contract §15) listing pending `Assistant Updates` items on pages they own,
plus brain rows where they're `Owner`. They decide when to consolidate
inbox → canonical. The assistant helps on demand:

> *"The Product Team page has 6 pending updates from 3 assistants this month —
> want me to draft a consolidation into the canonical section?"*

## Forgetting cascades

When the user says "forget X":
- Remove matching inbox entries on Notion pages (only ones tagged with this
  user's assistant).
- Leave canonical content alone — that's the owner's to edit.
- Tombstone locally so we don't re-promote the same thing later.

## Failure mode

If Notion is unreachable:
- Queue the write in `logs/pending-writes.md`.
- Retry on next successful session.
- Tell the user at the top of the next session: *"3 updates to Notion are
  queued — I'll push them when Notion's reachable."*
