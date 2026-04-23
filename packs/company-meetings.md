# pack: company-meetings

> Handle meeting prep + meeting notes. Works with anything the user pastes
> (Zoom / Google Meet transcripts, read.ai summaries, Otter, hand-written
> notes). Also designed to auto-ingest read.ai notes when an integration ships.

## When this pack activates

Any of these triggers:

- User says *"I have a meeting with X tomorrow"* / *"help me prep for…"*
- User pastes text that looks like a meeting summary (names + timestamps +
  action items).
- User says *"here are my notes from the <topic> meeting"*.
- (Future) A read.ai note lands in `memory/meetings/` via integration.

## Prep flow (before the meeting)

When user asks to prep for a meeting:

1. Query the `🗓 Meetings` DB for the most recent row with these attendees
   (or this title pattern). Follow its `Decisions Produced` and
   `Insights Produced` relations. That's usually 60–80% of prep context.
2. Pull every recent mention of the attendees from `memory/relationships.md`
   and Notion. Summarize: *"Last time you met with X (April 10), you agreed
   on Y. Z was open."*
3. Pull every recent mention of the topic. Surface 1–3 facts the user should
   recall before walking in. Include any active `🎯 Goals` row the meeting
   touches if the user's prompt mentions the goal area.
4. Ask: *"Want me to draft an agenda, or are you set?"*
5. If yes → produce a 3–5 bullet agenda grounded in the context above.
6. Save prep note as `memory/meetings/<YYYY-MM-DD>-<slug>-prep.md`.

## Ingest flow (after the meeting)

When user pastes a transcript / read.ai summary / notes:

1. **Save the raw input** to `memory/meetings/<YYYY-MM-DD>-<slug>.md` verbatim.
   Never lose the source.
2. **Extract structured facts** into a summary block at the top of the file:
   - **Attendees** → names, matched to `memory/relationships.md`.
   - **Topics** → one line each.
   - **Decisions made** → one line each, with who decided.
   - **Action items** → `- [ ] <owner>: <action> — by <date>`.
   - **Open questions** → one line each.
   - **Mentioned projects / people / tools** → tagged inline.
3. **Auto-capture to the right memory files** (Contract §4):
   - Decisions → append to `memory/decisions.md`.
   - Attendees and what they said they'd do → update
     `memory/relationships.md`.
   - Action items owned by the user → append to today's daily note.
   - New facts/norms → `memory/learnings.md`.
4. **Write structured rows to the AI Memory brain** (Contract §14, via
   `packs/company-brain.md`). The Meeting row is the backbone — every other
   write from this meeting links back to it via the `Source Meeting`
   relation:
   - **Meeting row** (always first) → upsert one `🗓 Meetings` row. Dedup
     by `Title + Date`. Fill `Kind`, `Attendees` (→ People), `Related
     Project` if the meeting is project-scoped, `Related Student` if it's a
     coaching session (permissioned — will be written only if the user has
     access to the Student row), and `Notes Link` pointing to the canonical
     notes page (the `memory/meetings/<date>-<slug>.md` local file or the
     Notion notes page if one exists). **Never paste the transcript body
     into the row.**
   - Each **Decision made** → upsert a `✅ Decisions` row. Title = the
     decision statement. `Decided on` = meeting date. `Owner` = person who
     made the call (relation to `👤 People`). `Participants` = attendees.
     `Rationale` = the reasoning as captured. `Outcome` = the decision
     itself. `Source` = `meeting`. `Status` = `Active`. `Source Meeting`
     → the Meetings row from the first step. Confidence = high if
     explicit, medium if inferred. Dedup by Title + Decided on. Also
     back-link by adding the Decision row to the Meeting's `Decisions
     Produced` relation.
   - Each attendee the assistant doesn't already know → upsert `👤 People`
     row with whatever context the transcript reveals (role mentions,
     expertise, views). Never write sensitive content about an attendee.
   - Each cross-cutting observation (*"onboarding's slow because X"*,
     *"customers keep asking for Y"*) → upsert `💡 Insights` row. If a
     fuzzy match exists, increment `Surface count`. Tag appropriately.
     Set `Source Meeting` → the Meetings row; back-link via
     `Insights Produced`.
   - Each project referenced with state change (*"Project X is now
     blocked on Y"*) → update `🚀 Projects.Status` + `Blockers`.
   - Each goal status update (*"We're on track for Q2 growth"*) → update
     the matching `🎯 Goals` row's `Status` and append the Decision row to
     its `Related Decisions` if applicable.
5. **Auto-promote to Notion canonical pages** (Contract §9) the qualifying
   items:
   - If a decision affects a project → promote summary to that project page's
     `## Assistant Updates` inbox (Rule 9), AND write the structured row to
     `✅ Decisions` (Rule 14). Both fire on one event.
   - If an action item is owed to another Alpha employee → promote to their
     team page's `## Assistant Updates` inbox, tagged with their name.
   - If a question is company-wide → promote to the Operating Framework
     page's `## Assistant Updates`.
   - Skip any item the user marks *"keep local"* / *"don't share"*.
6. **Run the sensitivity gate** on anything involving interpersonal
   feedback, compensation, strategic doubt, or explicit privacy markers
   from the meeting. Gated items never write to brain or canon; they land
   in `memory/meetings/` with a `[LOCAL ONLY]` tag.
7. **Confirm in one sentence:** *"Got the <topic> meeting. 3 decisions, 2
   action items for you, 1 for <person>. Brain: 1 Meeting + 3 Decisions +
   1 Insight. Canon: 2 inbox entries on <project>."*

## Auto-ingest from read.ai (future-ready design)

Today (V1): the user pastes read.ai summary email text into chat. This pack
handles it.

Tomorrow (V1.x): when a read.ai integration lands, notes will auto-land in
`memory/meetings/` as markdown files. Detect unprocessed files at session
start and run the ingest flow on each one silently. Notify the user once:
*"I processed 3 new meetings from read.ai while you were away — here's the
30-second summary."*

Schema we expect for auto-dropped files (once integration exists):

```
memory/meetings/
  2026-04-22-prod-sync.md       ← raw read.ai summary, verbatim
  2026-04-22-prod-sync-processed.json  ← {ingested_at, promoted_to: [...]}
```

The `-processed.json` sidecar prevents reprocessing.

## What NEVER gets promoted

- Verbatim transcripts (always summarize — Contract §9).
- Personal / off-topic conversation in the meeting (trim it).
- Anything marked confidential, HR-related, or about hiring decisions —
  capture locally only; if auto-promote logic flags it, default to skip and
  log to `logs/session-log.md` for user review.

## Memory layout

```
memory/meetings/
  README.md                      ← short doc of this structure
  <date>-<slug>.md              ← one file per meeting, with structured header
  <date>-<slug>-prep.md         ← (optional) pre-meeting prep notes
```

## Configurable per user

In `WORKSTYLE.md` or `TONE.md`, the user can override:

- `meetings.promote_action_items_to_others`: default `true`. Set `false` to
  keep action items private until the user says otherwise.
- `meetings.summary_length`: `short` (default), `medium`, `full`.
- `meetings.ingest_automatically`: default `true`. Set `false` to require
  explicit *"process this meeting"*.
