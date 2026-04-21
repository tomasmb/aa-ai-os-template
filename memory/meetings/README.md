# memory/meetings/

> Raw and processed meeting notes. Owned by the user. Populated by the
> `company-meetings` pack (see `packs/company-meetings.md`).

## Files you'll see here

- `<YYYY-MM-DD>-<slug>.md` — one per meeting. Raw notes at the bottom, a
  structured summary at the top (attendees, decisions, action items, open
  questions). Written by the assistant after you paste the meeting notes or
  when read.ai ingest runs.
- `<YYYY-MM-DD>-<slug>-prep.md` — optional pre-meeting prep note.
- `<YYYY-MM-DD>-<slug>-processed.json` — sidecar that tracks what already
  got promoted to Notion, so re-runs don't duplicate.

## What's safe to edit by hand

Anything. These are your notes.

If you edit the structured summary block, the assistant re-reads it on next
session and updates `memory/decisions.md`, `memory/relationships.md`, and
today's daily note to match.

## What's *not* here

- Verbatim transcripts of private conversations you didn't ask to store.
- Anything you told the assistant to forget (see Contract §11).
