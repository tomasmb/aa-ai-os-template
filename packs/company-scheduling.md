# pack: company-scheduling

> Schedule meetings like a chief of staff. Reads Google Calendar, looks up
> teammates in the Notion Team directory, respects everyone's work hours and
> timezones, drafts a short clean invite in Alpha voice. Designed so new
> hires can knock out their first-month 1-1s in minutes instead of days.

## Why this exists

New hires hit one universally painful checklist item: *"schedule 1-1s with
the team to get to know everyone."* They don't know:

- Who's on the team (the full list is in the Team directory but no one reads
  it proactively).
- What timezone each teammate is in.
- When each teammate takes meetings vs does deep work.
- How long the 1-1 should be.
- What subject line + body to write.
- How to phrase it without sounding like they're asking for a job interview.

So 1-1s slip. Weeks go by. The new hire ramps slower than they should. This
pack turns the whole thing into one sentence: *"schedule intro 1-1s with my
team."*

It's also useful for **existing employees** for any 1-1 scheduling —
recurring check-ins, catch-ups, cross-team chats.

## When this pack activates

Any of these:

- User says *"schedule a 1-1 with X"* / *"find time with Y"* / *"when can I
  meet Z this week?"*
- User says *"help me schedule my intro 1-1s"* (new-hire flow).
- New-hire flow hits an onboarding checklist item that involves scheduling
  meetings (e.g. *"within your first month, schedule 1-1 meetings to get to
  know the team"*) — the assistant proactively offers: *"Want me to set those
  up for you? Takes a minute."*
- User mentions a recurring cadence (*"we do a 1-1 every other Tuesday"*) —
  the assistant offers to create the recurring event.

## Preconditions

1. **Google Calendar MCP connected.** If not, run the setup from `TOOLS.md`
   (per-host instructions) before doing anything else. Say: *"I can help with
   this the moment your Google Calendar is connected. 30 seconds — want me to
   walk you through it?"*
2. **Notion MCP connected** (already required for the rest of the OS).
3. `USER.md` has a timezone filled (from setup Block 1).

If any precondition fails, offer to fix it first. Never fabricate availability.

## Happy-path flow — "schedule intro 1-1s with my team"

### Step 1 — Identify attendees

1. Read the user's team from `onboarding/team.md` (or ask if missing).
2. Pull the Team directory from Notion and list everyone on the user's team
   with their email + role + timezone (if published).
3. Cross-reference `memory/relationships.md` — exclude people the user has
   already met (tagged *"met"* in relationships).
4. Present the list, 1 sentence per person:
   > *"Your team has 6 people besides you. I'd suggest you start with these 4
   > — they own areas you'll touch most: Ana (Design), Ben (Eng lead), Carla
   > (PM), Dan (Ops). The other 2 are more peripheral for week 1. Sound good,
   > or want a different cut?"*

### Step 2 — Gather scheduling constraints (ask once, then remember)

Ask three tight questions, one at a time:

1. *"How long per 1-1? 30 minutes is the Alpha default."*
2. *"Any days or blocks I should avoid? (Your deep-work time is already
   blocked off from `WORKSTYLE.md`.)"*
3. *"Video or in-person? I'll attach the Google Meet link automatically if
   video."*

Store answers in `memory/scheduling-preferences.md` so we never ask again.

### Step 3 — Check availability

For each attendee, use the Google Calendar MCP `freebusy` query:

- Window: next 10 business days, user's work hours from `WORKSTYLE.md`
  (fallback 9am–5pm user-local if missing), intersected with attendee's work
  hours from their Notion profile (fallback 9am–5pm attendee-local).
- Exclude: slots that overlap user's deep-work blocks, existing events, or
  within 15 minutes of a heavy meeting (back-to-backs are bad UX).
- Rank slots by: (a) earliest date, (b) earliest in the day for the
  attendee's timezone, (c) 15-minute buffer on both sides, (d) Tuesday /
  Wednesday / Thursday preferred.

Propose **3 slots per attendee**, not more. Analysis paralysis is real.

### Step 4 — Draft the invite

Apply `packs/company-writing.md` voice. Template:

**Subject:** `Intro 1-1 — <user first name> × <attendee first name>`
(or `Catch-up — ...` for existing-employee 1-1s)

**Body** (keep it 2–3 sentences):

> Hi <first name>,
>
> I'm <role> and just getting started at Alpha. Would love 30 min to hear
> what you own, where I can be useful, and what I should know about the team.
> I'll come prepared.
>
> — <user first name>

For existing employees, soften the "just getting started" line. Never use
corporate-speak (*"sync up", "touch base", "circle back"*).

Attach a 1-line agenda the assistant proposes:

> *Agenda: (1) your role + what you're working on, (2) where a <user's role>
> like me should plug in, (3) open questions.*

### Step 5 — Confirm before sending

Present all attendees + top slot + drafted invite, one screen:

> *"Here's what I've got — confirm and I'll send all 4 invites at once, or
> say 'edit <name>' to change any of them:*
>
> • Ana — Mon 2:00 pm (your TZ) / 11:00 am hers, 30 min, GMeet, draft attached
> • Ben — Tue 10:30 am / 10:30 am his, 30 min, GMeet, draft attached
> • Carla — Wed 3:00 pm / 6:00 pm hers, 30 min, GMeet, draft attached
> • Dan — Thu 9:00 am / 9:00 am his, 30 min, GMeet, draft attached
>
> *Send all?"*

**Explicit consent is required to send.** This is a calendar write — unlike
local memory (Rule 4) or Notion inbox entries (Rule 9), calendar events are
irreversible from the recipient's perspective. Always confirm, every time.

### Step 6 — Send + record

On confirmation:

1. Create each event via Google Calendar MCP.
2. Append each attendee to `memory/relationships.md` with a tag:
   `scheduled_intro: <YYYY-MM-DD>`.
3. Append a summary to today's daily note:
   > *Scheduled 4 intro 1-1s: Ana (Mon), Ben (Tue), Carla (Wed), Dan (Thu).*
4. If this was triggered from the new-hire checklist, **mark the checklist
   item done in the user's onboarding card** (same mechanism as
   `new-hire-flow.md` Step 3).
5. Set a reminder in `memory/recurring-work.md`:
   *"2 days after each 1-1, ask the user how it went + prep a follow-up
   note for `memory/meetings/`."*

### Step 7 — Post-meeting integration

This pack hands off to `packs/company-meetings.md` for the meeting itself.
When the meeting's day arrives:

- Surface the prep note 15 minutes before: *"Ana at 2 pm. You haven't met.
  She owns Design. Want a 1-paragraph brief?"*
- Afterwards, if the user mentions it or pastes notes, the meetings pack
  ingests + captures decisions to `memory/relationships.md`.

## Ad-hoc scheduling ("find me 30 min with X this week")

Shorter flow:

1. Identify attendee (by name from Team directory or by email if user gives
   one). If ambiguous, list matches.
2. Skip Step 2 (reuse stored preferences; ask only if they change).
3. Propose 3 slots.
4. Draft the invite with the right tone (intro vs. catch-up vs. specific
   topic — the user will usually say what the meeting is for).
5. Confirm + send.

## Recurring 1-1s

When the user says *"every other Tuesday with Ana"* or *"weekly 1-1 with my
manager"*:

1. Find the first slot that matches (Step 3).
2. Create as a recurring event with the specified RRULE (weekly, biweekly,
   monthly).
3. Capture the cadence to `memory/relationships.md` so the assistant can
   surface *"you have a 1-1 with <person> tomorrow — want me to pull what
   you discussed last time?"* the day before each occurrence.

## What NEVER to do

- **Never send invites without explicit confirmation.** Per event, every time.
- **Never read the content of someone else's calendar events** — only
  free/busy. Calendar privacy matters.
- **Never propose slots in a teammate's published DND / deep-work blocks**
  even if the raw `freebusy` call shows them as free.
- **Never guess a teammate's email.** Look up in Notion. If missing, ask the
  user.
- **Never auto-schedule 1-1s the assistant thinks the user "should" have
  without them asking.** Proactivity ≠ autonomy. The closest we come is
  *"want me to set those up?"* when a checklist item triggers this pack.
- **Never fabricate attendee availability** if the Calendar MCP is down.
  Say the tool is unreachable and offer to try again later.

## Per-user overrides (in `WORKSTYLE.md`)

- `scheduling.default_duration_min`: int, default `30`.
- `scheduling.preferred_days`: array, default `["Tue","Wed","Thu"]`.
- `scheduling.buffer_min`: int, minutes of padding before/after meetings,
  default `15`.
- `scheduling.auto_attach_gmeet`: bool, default `true`.
- `scheduling.decline_outside_work_hours`: bool, default `true`.

## Success criteria (how we know the pack is delivering value)

- **Time-to-first-1-1** for new hires drops from days to the same day.
- Week-1 scheduling conversation with the assistant takes under 5 minutes
  end-to-end (discover attendees → confirm → sent).
- ≥ 80% of proposed slots accepted without the user asking for alternatives.
- No scheduling-related complaints in the weekly pilot check-in.
