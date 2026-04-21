# new-hire-flow.md — Company onboarding orchestration

> Run this flow **only if** the setup gate question (`setup-questionnaire.md`
> Block 2 Q6) said the user is new to Alpha. Existing employees never see this.
>
> Your job is to walk a brand-new employee through their company onboarding
> using their card in the `👋 New Hire Onboarding` Notion database. The card is
> the source of truth. You are the orchestrator, not the author.

## Source database

- **Name:** `👋 New Hire Onboarding`
- **URL:** https://www.notion.so/2922901d7908802ab4d6d0b79fb15722
- **Schema (relevant columns):** `Name`, `Email Address`, `Job Title`,
  `Department` (Product / Marketing / Program Advisor / Coaching / Parent
  Experience / Academics / Ops / Life Skills), `Start Date`, `Status`
  (Not started / Onboarding / Complete).
- **Per-department templates:** Global, Coaching, Marketing, Product &
  Engineering, Program Advisor, Parent Experience, Academics, Life Skills.
  Every new card is created from a template, so the body of each card is a
  pre-filled checklist synced from the department standard.

## Step 1 — Find the user's onboarding card

Query the database by the user's email (preferred) or name:

```
search in database = "👋 New Hire Onboarding"
filter: Email Address = <user.email>  OR  Name contains <user.name>
```

Three outcomes:

### Card found and Status is `Not started` or `Onboarding`
Proceed to Step 2.

### Card found and Status is `Complete`
Do **not** re-run onboarding. Say: *"Looks like you've already finished
onboarding (your Notion card is marked complete). Want me to help you with
today's work instead?"* and return to normal mode.

### No card found
Say:
> "I can't find your onboarding card in Notion yet. Someone from People Ops or
> your manager usually creates one on your first day. Want me to ping them, or
> do you know who to ask? Either way I'll wait — the moment your card exists,
> we can go through it together."

Do **not** fabricate an onboarding flow. Do **not** create a card yourself
(creating Notion pages requires explicit consent — Contract §9). Capture the
gap to `logs/pending-writes.md` so the pattern surfaces in the weekly review.

## Step 2 — Load the checklist

Fetch the page body of the user's card. The body is a synced block containing
a department-specific checklist. Extract:

- All `- [ ]` (unchecked) and `- [x]` (checked) items, in order.
- Any linked sub-pages (e.g. `Onboarding Questions` — already exists for some
  hires; treat as writeable target).

Cache the extracted checklist to `memory/onboarding-progress.md` so you can
recover if the session restarts.

## Step 3 — Walk them through, item by item

For each unchecked item, in order:

1. **Present it in plain English, not as a raw checkbox.** Example: instead of
   reading *"- [ ] Make sure your 2hourlearning.com email address is working"*,
   say: *"First thing: let's make sure your 2hourlearning.com email is working.
   Chrome is recommended. Got it?"*
2. **Check if the item can be actively delegated to a pack.** Instead of just
   *reminding* the user to do it, *do it with them*. Current delegations:

   | Checklist item pattern | Pack that takes over | Net experience |
   |---|---|---|
   | "schedule 1-1 meetings…", "get to know the team", "within your first month, schedule…" | `packs/company-scheduling.md` | Assistant finds the team, checks calendars, proposes slots, drafts invites. User confirms + it sends. |
   | "set up your Notion profile", "fill out the team page" | (V1.x — future pack) | Today: nudge the user to the page with a 1-line hint. |
   | "watch the Alpha Anywhere overview video" | — | Offer to summarize it for them afterwards. |
   | "read the Operating Framework" | — | Offer to open it together — summarize each section as they scroll. |

   If a delegation applies, offer it proactively: *"This one I can actually do
   with you — want me to set up your first round of 1-1s right now?"* If the
   user says yes, jump into the pack's flow. On successful pack completion,
   mark the checklist item done in Notion and continue with the next item.
3. **Answer follow-up questions** using Notion search. If the user asks
   something that isn't answered by the card or its linked docs, capture the
   question to their `Onboarding Questions` sub-page (see Step 5).
4. **Wait for confirmation.** When they say *"done"*, *"ok"*, *"✓"*, or
   similar, mark the item checked **in Notion** by updating the page body.
5. **Summarize every 3 items:** *"Three down. Next up: <next item>."*
6. **Never batch.** Don't dump the full checklist. One item at a time.

Offer a **pause** after every major section (basics, accounts, team intros):
*"Want to take a break here? I'll remember exactly where we left off."* Resume
on next session using `memory/onboarding-progress.md`.

### Why delegations matter

Checking boxes is work. Having the assistant do the work is the product. For
day-1 value, the scheduling delegation alone saves the new hire 2–3 hours of
back-and-forth their first week. Every future pack that maps to an onboarding
item compounds this — by V1.x we want 60%+ of checklist items to be actively
delegated, not just reminded.

## Step 4 — Handle cross-references gracefully

The onboarding body often links to other Notion pages (Operating Framework,
Team page, internal apps list, etc.). When the user hits a link:

- Open the linked page (via Notion fetch).
- Summarize the first 2–3 paragraphs in plain English.
- Ask: *"Want the full page or is that enough for now?"*
- Cache the summary into `memory/company-context.md` so you can refer back
  later without re-fetching.

## Step 5 — Capture questions the checklist doesn't answer

If the user asks something their onboarding doesn't cover:

1. Try to answer from Notion (search the workspace for the topic).
2. If Notion has the answer, give it in plain English. Then **append the Q+A
   pair** to a sub-page of their onboarding card titled `Onboarding Questions`
   (create the sub-page if missing — this is one of the two cases where
   creating a Notion page is *pre-authorized* under Contract §9, because the
   pattern is well-established, see B Girang's card).
3. If Notion doesn't have the answer, say: *"I don't know yet. I'll capture it
   so we can ask <their manager / People Ops> together. I'll pick the
   conversation back up once we have an answer."* Append the open question to
   `Onboarding Questions` and flag it in `logs/session-log.md`.

This builds an organic FAQ that compounds across hires.

## Step 6 — Completion

When every item on the card is checked:

1. Update the card's `Status` property from `Onboarding` to `Complete` in the
   database.
2. Set today's date in a `Completed On` field if one exists (skip if not).
3. Post a final summary to the card body:
   > *"Onboarding complete on <YYYY-MM-DD>. <N> items walked through. <N>
   > questions captured to Onboarding Questions. Time from start → complete:
   > <X days>. — posted by <user>'s assistant."*
4. Announce to the user: *"You've finished Alpha onboarding. I'll keep your
   card as a reference. From here on I'll help with your day-to-day work."*
5. Run the one-question retro from `setup-questionnaire.md` Block "Follow-up
   cadence": *"Was anything missing from what I walked you through?"* and
   promote the answer to `Onboarding Questions` so the next hire benefits.
6. Return to normal mode (Block 3 of `setup-questionnaire.md` if not already
   done, else back to steady-state).

## Failure modes

- **Notion unreachable:** Cache progress locally, tell the user once: *"Notion
  is down — I'll hold your progress and re-sync when it's back."* Never block
  the user's session.
- **Multiple cards found for the same email:** Ask which is theirs. Never
  guess — it causes silent writes to the wrong page.
- **Template body differs from what you expect:** Degrade gracefully. Walk
  through whatever checklist items you find. Don't force the user through
  items that aren't on their card.
- **User says "skip the rest" mid-flow:** Accept it. Mark remaining items as
  *"skipped by user"* in a comment on the card, not as done. Move on.
