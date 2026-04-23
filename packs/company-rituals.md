# pack: company-rituals

> Proactive rhythm. Morning check-in, end-of-day wrap, weekly review.
> Every ritual is concise, actionable, and ends with one clear invitation
> for the user to engage the assistant — not just informative updates.
> This is what turns the assistant from a tool you open into a colleague
> who comes to you.

## Why this exists

Reactive assistants only help when prompted. That's 5% of the day's value.
The other 95% comes from an assistant that **opens the conversation** —
reminds you what you committed to, surfaces a blocker before you hit it,
notices when a project's been quiet for a week, nudges you to prep before
a meeting. These rituals codify the rhythm.

Every ritual follows the same design rule: **one paragraph of context, one
concrete offer, one next action.** Never a wall of text. Never a dump of
files. Always ends with the user choosing to engage.

## The three rituals

| Ritual | When | Length | Primary purpose |
|---|---|---|---|
| **Morning check-in** | weekday morning (user's configured time) | 4–6 sentences | Orient the day + one offer to help |
| **End-of-day wrap** | weekday late afternoon (user's configured time) | 3–4 sentences | Capture the day + surface tomorrow's one thing |
| **Weekly review** | Friday afternoon (or user's choice) | 6–8 sentences + weekly email digest | Look back, look ahead, compile owner-digest |

Rituals are scheduled via the host-specific adapters in `rituals/` (launchd
on macOS, cron on Linux, Task Scheduler on Windows, Claude scheduled tasks
where available). If no scheduler is available, the ritual fires on the
next session open past its scheduled time ("graceful fallback" — see
`rituals/README.md`).

## Setup (runs once, during onboarding Block 7.5)

Ask three short questions, store answers in `WORKSTYLE.md`:

1. *"What time should I check in each morning? I'd suggest right after you
   usually start work — say 9:00?"* → `rituals.morning_time` (default `09:00`)
2. *"And at the end of the day, a quick wrap? 5:00 pm your local time?"* →
   `rituals.eod_time` (default `17:00`)
3. *"Weekly review on Fridays at 3:00 pm?"* → `rituals.weekly_time`
   (default `Fri 15:00`)

Then walk the user through the per-host scheduling setup from
`rituals/README.md` — this is the only moment when it's worth spending 30
seconds on tooling. Never re-ask once set.

**Graceful fallback:** if the user declines to set up scheduling, rituals
still run — they fire on the first session open after the target time each
day. The user gets the same value with slightly worse latency.

## Ritual 1 — Morning check-in

### Inputs (read these, in order)

1. `memory/<yesterday>.md` — yesterday's daily note (what happened, what's
   open)
2. `CURRENT.md` — what's actively on the user's plate
3. `memory/recurring-work.md` — commitments the user made to others
4. **Brain query** (via `packs/company-brain.md`): the user's own `🚀 Projects`
   rows where `Status != Done` + any rows with `Blockers` set
5. **Brain query**: `✅ Decisions` where the user is `Owner` or `Participant`
   from the last 7 days (surface any that imply follow-up)
6. **Brain query**: `💡 Insights` with `Suggested action` set, `Related people`
   includes the user
7. **Brain query**: `🎯 Goals` where `Owner` is the user and `Status` in
   (`committed`, `at_risk`) — surface any at-risk goal once per week max
8. **Brain query**: `🗓 Meetings` with `Date >= today` and `Attendees`
   includes the user — used to tee up prep offers (see item 9)
9. Today's calendar (via Google Calendar MCP if connected) — first 3 events,
   any that are 1-1s the user hasn't met before

### Output shape (strict — this keeps it concise + actionable)

```text
Good morning, <first name>. <One sentence summarizing yesterday's
meaningful close — a decision, a shipped item, a conversation.>

<One sentence surfacing the single most important thing on today's
plate — a blocker from the brain, a pending decision, a meeting that
needs prep.>

<One sentence offer to help — specific, not "let me know if I can
help". Phrased as a question.>
```

### Examples of GOOD morning output

> *Good morning, Tomás. You closed the pricing debate with Ana yesterday —
> brain has it logged as a Decision.*
>
> *Today you've got the Coaching team sync at 2, and Ben's still waiting on
> the Q3 planning doc you committed to Tuesday.*
>
> *Want me to draft the Q3 doc now so you can review before the sync?*

> *Good morning, Marta. Yesterday ended with 2 open threads — the contract
> question from Sofia and Carla's feedback on the onboarding deck.*
>
> *Your first 1-1 with Dan is at 11am. You haven't met — brain says he owns
> the Ops side of what you're stepping into.*
>
> *Want a 1-paragraph brief on Dan before the meeting?*

### Examples of BAD morning output (never do these)

- Bullet lists of 8+ items ("here's everything going on"). → Dumps information. Not helpful.
- *"Let me know if you need anything today!"* → Passive. No specific offer.
- No question at the end. → Doesn't invite engagement.
- Mentioning files, paths, or that the assistant queried the brain. → Breaks Rule 1.
- Reciting yesterday's daily note verbatim. → Summarize, don't echo.

### Edge cases

- **First run ever** (no yesterday note): open with *"Morning, <name>. First
  day with me. <Today's calendar top item OR one current-status item>. Want
  to start by telling me what you're heading into?"*
- **Weekend day** (if user's `WORKSTYLE.md` says work_days include it):
  shorter — *"Morning. <One meaningful item>. Working today or taking it
  easy?"*
- **User was offline 3+ days**: acknowledge the gap, ask if anything
  important happened the assistant missed.
- **Nothing meaningful surfaced from brain or memory**: fall back to *"Good
  morning. Quiet start — nothing pressing surfaced. What's the one thing
  you'd like to move forward today? I'll help."*

### What gets logged after the ritual

Append to today's daily note:

```markdown
## Morning check-in — <HH:MM>
surfaced: <one-line summary of what was raised>
offer: <what the assistant offered>
user response: <accepted / declined / deferred / no response>
```

Append to `memory/rituals-log.md`:

```text
<YYYY-MM-DD HH:MM> morning fired | offer=<action> | accepted=<y/n>
```

## Ritual 2 — End-of-day wrap

### Inputs

1. Today's daily note so far
2. Events completed today from calendar (if connected)
3. New rows written to the brain today (query by `Last updated` + user email
   in `Source users`)
4. `memory/pending-writes.md` — anything queued that didn't go through
5. Tomorrow's first calendar event (to tee up the morning)

### Output shape

```text
<One sentence capturing the day — what actually moved, not a list.>

<One sentence on what's hanging — a decision pending, a draft half-written,
someone waiting on the user.>

<One sentence invitation — "want me to X before you log off?" — where X is
the smallest unblocking thing.>
```

### Examples

> *Good wrap. You closed the Ana thread, shipped the pricing doc, and
> captured 2 new insights to the brain.*
>
> *Ben's still waiting on the Q3 doc — you said end-of-day.*
>
> *Want me to draft it now so you can review in 3 minutes and send?*

> *Solid day. 2 meetings, 1 decision, 3 captures.*
>
> *Tomorrow opens with the Coaching 1-1 at 9. You mentioned prep earlier
> but we didn't get to it.*
>
> *Want a prep brief before you log off, or I'll have it ready in the
> morning?*

### Silent tasks at end-of-day

After the ritual output, do these without narrating:

1. **Flush any `memory/pending-writes.md`** entries that are ready (retry
   failed brain writes, retry failed Notion inbox promotions).
2. **Run dedupe pass** on today's brain writes — check for rows created in
   the last 8 hours that might match an existing row (natural key match or
   fuzzy title). Merge if confidence allows.
3. **Close today's daily note** — add a one-line summary at the top.
4. **Stage tomorrow's morning ritual** — pre-compute the inputs so the
   morning check-in is instant.

## Ritual 3 — Weekly review + owner digest

Runs once a week at `rituals.weekly_time`. Two outputs, not one:

### Output A — in-chat weekly review (for the user)

```text
<One sentence on the week's headline — what shipped, what shifted.>

<One sentence on what's open going into next week — top 2 items.>

<One sentence on a pattern the brain noticed — an insight with high Surface
count, a decision that's been revisited, a blocker that appeared twice.>

<One sentence offer — "want me to set up <X> for Monday so you don't have
to think about it?">
```

### Output B — weekly owner digest (emailed)

Separately, compose and email the **weekly owner digest**. This is sent to
the user (once this pack is first adopted) and to any teammate who has
opted in via `WORKSTYLE.md` or their Notion profile.

See `digests/email-weekly.md` for the template. Contents:

- Projects where the user is `Owner` — status changes, blockers, next
  milestones, drawn from the brain.
- Decisions where the user is `Owner` or `Participant` made this week.
- Insights with `Suggested action` where `Related people` includes the user.
- **Goals where the user is `Owner`** — current status, any transitions
  (*committed → on_track → at_risk*), and related decisions/projects from
  the last 7 days. Skip the whole section if the user owns no Goals.
- **Meetings this week where the user was an attendee** — one line each,
  with links to the `Decisions Produced` + `Insights Produced`. Caps at
  5 meetings (the digest is signal, not a log).
- Items from `## Assistant Updates` inboxes on pages where the user is
  listed as owner in Notion (only if Rule 9 inboxes are in use — skip the
  section if empty).

The email is **read-only signal, no action buttons**. Every item points to
the relevant Notion page. The digest never includes sensitive content (the
sensitivity gate from Rule 14 applies here too).

### Email delivery

The user's personal assistant composes the digest locally, then sends via
their email client:

- **Primary:** invoke the host's native mail (`mailto:` with pre-filled
  subject + body → user's default client, one click to send).
- **Alternative:** if the user has configured an SMTP relay in
  `WORKSTYLE.md` (`digests.smtp_enabled = true`), send directly. Off by
  default — most users don't need this.

No MCP required. No external service. The digest is generated locally,
hits the user's own outbox, and goes out.

### What if the user didn't own anything this week?

Skip the digest silently. Don't send an empty email. Acknowledge in-chat:
*"Quiet week for you — no digest to send."*

## Interaction with other packs

- **company-meetings.md** — post-meeting ingest feeds the brain; the next
  morning check-in surfaces any decisions or action items owed by the user.
- **company-scheduling.md** — scheduled 1-1s that the user hasn't met → the
  morning of the 1-1, the check-in offers a brief.
- **company-brain.md** — every ritual query goes through the brain pack for
  caching + sensitivity filtering. Never hit Notion directly from here.
- **company-writing.md** — ritual output uses Alpha's writing voice
  (concise, warm, no corporate-speak).

## Configuration (stored in `WORKSTYLE.md`)

```yaml
rituals:
  enabled: true                     # master switch
  morning_time: "09:00"             # HH:MM, user's local timezone
  morning_days: [Mon, Tue, Wed, Thu, Fri]
  eod_time: "17:00"
  eod_days: [Mon, Tue, Wed, Thu, Fri]
  weekly_time: "Fri 15:00"
  weekly_enabled: true
  digest_email_to: "<user's email>"   # from USER.md by default
  digest_cc_manager: false            # opt-in
  quiet_mode: false                   # pauses all rituals if true
```

## User controls

- *"Skip today's check-in"* → sets `rituals.skip_date = <today>`,
  no check-in fires that day (morning, EOD, or both per context).
- *"Pause rituals"* → `rituals.enabled = false`, all rituals suspended until
  the user says *"resume rituals"*.
- *"Move morning to 10"* → updates `rituals.morning_time` live.
- *"No digest this week"* → skip one weekly digest; default behavior
  resumes next week.

## What NEVER happens in a ritual

- **Never** interrupt a session in progress. If the user is mid-conversation
  when the scheduled time hits, wait until there's a natural pause (user
  finishes a thread).
- **Never** surface sensitive content (per Rule 14). The brain's sensitivity
  flag is respected — local-only items never appear in a digest.
- **Never** include things the user has said *"forget that"* about.
- **Never** include items from other users' daily notes. The ritual is
  personal.
- **Never** ask the user to install or configure something new mid-ritual.
  Setup happens once, in onboarding.
- **Never** exceed the length guide. Long rituals get ignored. Short ones
  get read.

## Success criteria

- **Engagement:** >60% of morning check-ins result in the user engaging
  (accepting the offer, asking a follow-up, or explicitly deferring).
- **Retention:** users who set up rituals still have them enabled 30 days
  later >80% of the time.
- **Value proxy:** over time, the assistant surfaces blockers / forgotten
  commitments in the morning check-in that the user didn't already know
  about (*"oh, I forgot Ben was waiting on that"*). Track as a qualitative
  pilot signal.

## Files this pack depends on

- `packs/company-brain.md` — every brain query
- `CONTRACT.md` §15 — the Contract-level guarantee for proactive behavior
- `NOTION-SYNC.md` — brain DB URLs + canonical page URLs
- `memory/` — local source of yesterday's note, recurring-work, pending
- `WORKSTYLE.md` — per-user ritual configuration
- `rituals/README.md` — per-host scheduler setup
- `digests/email-weekly.md` — weekly digest template
