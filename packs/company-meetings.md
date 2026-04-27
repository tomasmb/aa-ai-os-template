# pack: company-meetings — meeting prep + post-meeting ingest

> Ships by default. Implements meetings as the event backbone of the KB:
> every meeting becomes a `core/meetings/` row that other entities link back to.

## What this pack does

Two flows:

1. **Pre-meeting prep** — when the user mentions an upcoming meeting, the
   assistant pulls relevant context from `core/` and surfaces a 3-bullet brief.
2. **Post-meeting ingest** — when the user pastes meeting notes (or an
   automated tool drops a transcript into `inbox/raw/`), the assistant
   processes them into a Meetings row + linked Decisions/Insights + an
   archived full notes file.

## Pre-meeting prep — 3-bullet brief

Trigger words: *"prep me for…"*, *"what should I know about my 1-1 with X?"*,
*"meeting with the design team in 30 min"*.

Steps:

1. `rg` `core/meetings/` for prior meetings with the same attendees or
   project tag. Take the 3 most recent.
2. `rg` `core/projects/` for any project the meeting title references.
3. `rg` `core/people/` for each known attendee.
4. Compose 3 bullets:
   - **Last touchpoint** — most recent prior meeting + 1-line outcome.
   - **Open threads** — at-risk goals, pending decisions, unresolved insights.
   - **Their context** — relevant facts about the people in the room.
5. End with one offer: *"Want me to take notes during the meeting?"*

Never paste raw memory dumps. Always synthesize.

## Post-meeting ingest — paste-based

Trigger: user pastes a transcript or summary, or says *"here are my notes
from the X meeting"*.

Steps:

1. Identify date + title + attendees from the input. If anything is
   ambiguous, ask one question to confirm.
2. Determine `<slug>` (kebab-case from title).
3. **Write the full body to Archive** first:

   ```bash
   cat <<'EOF' | scripts/promote entity \
       archive/meeting-notes/<YYYY-MM-DD>_<slug>.md \
       --message "ingest meeting notes: <title>" --source meeting --confidence high
   <full notes body>
   EOF
   ```

4. **Then write the Core Meetings row** linking back:

   ```bash
   cat <<'EOF' | scripts/promote entity \
       core/meetings/<YYYY-MM-DD>_<slug>.md \
       --message "log meeting: <title>" --source meeting --confidence high
   ---
   title: <title>
   date: <YYYY-MM-DD>
   attendees:
     - ../people/<slug-1>.md
     - ../people/<slug-2>.md
   related_project: ../projects/<slug>.md
   notes_path: ../../archive/meeting-notes/<YYYY-MM-DD>_<slug>.md
   ---

   <≤10 line summary>
   EOF
   ```

5. **Extract Decisions and Insights** as separate atomic commits:

   ```bash
   # One per decision
   cat body | scripts/promote entity \
       core/decisions/<YYYY-MM-DD>_<decision-slug>.md \
       --message "log decision: <title>" --source meeting --confidence high

   # One per insight
   cat body | scripts/promote entity \
       core/insights/<YYYY-MM-DD>_<insight-slug>.md \
       --message "log insight: <title>" --source meeting --confidence medium
   ```

   Decisions and Insights link back to the Meetings row via
   `source_meeting:` frontmatter.

6. **Update related Goals** if the meeting changed status. Use a
   `consolidate(goals):` commit type.

## Sensitivity gate

Apply Rule 14 to the entire ingest. If any line of the notes meets the
sensitivity criteria (negative feedback about named people, salary, etc.):

- That line stays in `memory/` only, never lands in the brain.
- Tell the user once: *"Two parts of those notes felt sensitive — kept those
  in your local journal."*

## Recurring meetings

`core/meetings/recurring/<slug>.md` (seeded by `company-brain-seed`) holds
the definition. Each occurrence creates a fresh `core/meetings/YYYY-MM-DD_<slug>.md`
that links to the recurring template via frontmatter `series:`.

## Failure modes

- KB pending → all writes queue to `logs/pending-writes.md`. The assistant
  tells the user: *"Brain access isn't live yet — I'll push these notes
  when you're added to the org."*
- Push fails → same queue, replayed by morning ritual.
- Conflict on a meeting file → unlikely (date + slug + ts is unique). If it
  happens, follow `CONFLICT-PLAYBOOK.md`.

## What never happens

- The assistant never sends the meeting transcript to a network destination
  other than the KB git push (Rule 10).
- The assistant never auto-creates a new Project / Person row from a meeting
  unless the user explicitly approves (Rule 9 hard rule #4 in
  `PROMOTION-RULES.md`).
- The assistant never edits prior decisions in place. New context lands as
  a new Decision or an inbox note that the owner consolidates.
