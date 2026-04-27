# pack: company-scheduling — 1-1 and meeting scheduling

> Ships by default. Unlocks once Google Calendar MCP is connected.
> Updates `core/people/<slug>.md` rows when a 1-1 is scheduled.

## What this pack does

Helps the user schedule 1-1s and small meetings against the team's free/busy
data, then logs the meeting in the KB.

## Triggers

- *"schedule a 1-1 with X"*
- *"find time for me and X next week"*
- *"set up a 30 min sync about <project>"*

## Pre-requisites

- Google Calendar MCP connected (per `TOOLS.md`). If missing, walk the user
  through setup the first time the pack triggers. Never nag otherwise.
- Required scopes only: `calendar.freebusy` (read free/busy) +
  `calendar.events` (create the event the assistant authors).

## Flow

1. **Identify the participants.**
   - Look up each person in `core/people/<slug>.md` to find their email.
   - If a name doesn't match any People file, ask the user once.

2. **Find a slot.**
   - Query free/busy via the calendar MCP.
   - Default duration: 30 min for 1-1s, 45 min for ≥3 attendees.
   - Default window: next 5 business days, 9:00–17:00 local to the user.
   - Surface 3 options to the user.

3. **Confirm with the user.**
   - User picks one. The assistant repeats it back: *"Tomorrow 14:00 with
     Jane — confirm and I'll send it."*
   - On confirm, create the event.

4. **Create the event.**
   - Title format: `<user> ↔ <other>` for 1-1s; user-supplied otherwise.
   - Body: brief context auto-pulled from the most recent `core/meetings/`
     row with the same attendees, plus any open thread for the project.
   - Attendees: emails from each `core/people/<slug>.md`.

5. **Log to the KB.**

   ```bash
   cat <<'EOF' | scripts/promote entity \
       core/meetings/<YYYY-MM-DD>_1-1-<other-slug>.md \
       --message "schedule 1-1: <user> ↔ <other>" --source manual --confidence high
   ---
   title: <user> ↔ <other>
   date: <YYYY-MM-DD>
   attendees:
     - ../people/<user-slug>.md
     - ../people/<other-slug>.md
   kind: 1-1
   ---

   Scheduled by assistant on <YYYY-MM-DD>. Notes will be added after the meeting.
   EOF
   ```

6. **Update the People row** if `last_1_1_at:` is older than the new event.
   Use `scripts/promote entity core/people/<other-slug>.md` with type
   `promote` and a one-line `--message` like *"update last_1_1_at after
   scheduled 1-1"*.

## Conflicts

- If the user picks a slot that's been double-booked between option-show
  and confirmation, re-query free/busy and offer a fresh option.
- Calendar event creation failure → tell the user plainly + leave the
  Meetings file uncreated. No silent half-write.

## What never happens

- The assistant never reads the **content** of other people's events
  (titles, descriptions, attendees of other people's meetings) — only
  free/busy windows. Scope policy in `TOOLS.md`.
- The assistant never auto-schedules without explicit user confirmation.
- The assistant never invites people who don't have a `core/people/` row,
  unless the user explicitly provides their email.
