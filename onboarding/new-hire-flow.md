# new-hire-flow.md — Company onboarding orchestration

> Run this flow **only if** the setup gate question (`setup-questionnaire.md`
> Block 2 Q6) said the user is new to Alpha. Existing employees never see this.
>
> Your job is to walk a brand-new employee through their company onboarding
> using their plan in the KB at `archive/onboarding/<email-slug>.md`. The
> file is the source of truth. You are the orchestrator, not the author.

## Source

- **KB path:** `archive/onboarding/<email-slug>.md`
- **`<email-slug>`** = lowercased local part of the user's email (the part
  before `@`). Examples: `tomas.barros` → `tomas-barros`, `bgirang` →
  `bgirang`. (Slug rule: lowercase, replace `.` and `_` with `-`.)
- **Per-department templates:** `archive/onboarding/_templates/` — one
  per department (Global, Coaching, Marketing, Product & Engineering,
  Program Advisor, Parent Experience, Academics, Life Skills, Ops). The
  manager / People Ops copies the appropriate template and fills in the
  user's name + start date when they create the new hire's plan.
- **Frontmatter shape:** `name`, `email`, `department`, `role`,
  `start_date`, `status` (`not_started` | `onboarding` | `complete`),
  `completed_at`. Body is a markdown checklist (`- [ ]`).

## Step 1 — Find the user's onboarding file

Resolve `<email-slug>` from the email captured in Block 1 Q2. Then check:

```bash
test -f "$KB/archive/onboarding/<email-slug>.md"
```

Three outcomes:

### File found and `status: not_started` or `status: onboarding`
Proceed to Step 2.

### File found and `status: complete`
Do **not** re-run onboarding. Say: *"Looks like you've already finished
onboarding (your onboarding plan is marked complete). Want me to help you
with today's work instead?"* and return to normal mode.

### File missing
Say:
> "I can't find your onboarding plan in the KB yet. Someone from People Ops
> or your manager usually creates one before your first day. Want me to
> ping them, or do you know who to ask? Either way I'll wait — the moment
> the plan exists I'll see it on next session and we can go through it."

Do **not** fabricate a flow. Do **not** create the onboarding file
yourself — that's the manager's job, and creating it from this side would
skip the department template selection. Capture the gap to
`logs/pending-writes.md` so the pattern surfaces in the weekly review.

## Step 2 — Load the checklist

Read the file. Extract:

- All `- [ ]` (unchecked) and `- [x]` (checked) items, in document order.
- Any `## Questions` section (already populated by past hires — read it,
  but don't dump it on the user).

Cache the extracted checklist + cursor position to
`memory/onboarding-progress.md` so you can recover if the session restarts.

## Step 3 — Walk them through, item by item

For each unchecked item, in order:

1. **Present it in plain English, not as a raw checkbox.** Example: instead
   of reading *"- [ ] Make sure your 2hourlearning.com email address is
   working"*, say: *"First thing: let's make sure your 2hourlearning.com
   email is working. Chrome is recommended. Got it?"*
2. **Check if the item can be actively delegated to a pack.** Instead of
   just *reminding* the user to do it, *do it with them*. Current
   delegations:

   | Checklist item pattern | Pack that takes over | Net experience |
   |---|---|---|
   | "schedule 1-1 meetings…", "get to know the team", "within your first month, schedule…" | `packs/company-scheduling.md` | Assistant finds the team, checks calendars, proposes slots, drafts invites. User confirms + it sends. |
   | "fill out your row in the brain" | (Block 8 of `setup-questionnaire.md`) | Already happens silently. Mark done. |
   | "watch the Alpha Anywhere overview video" | — | Offer to summarize it for them afterwards. |
   | "read the Operating Framework" | — | Offer to open `operating-framework/` in the KB and walk through it together — summarize each section as they scroll. |

   If a delegation applies, offer it proactively: *"This one I can actually
   do with you — want me to set up your first round of 1-1s right now?"*
   If the user says yes, jump into the pack's flow. On successful pack
   completion, mark the checklist item done (Step 4) and continue.
3. **Answer follow-up questions.** First try the KB
   (`rg -i "<topic>" "$KB/core/" "$KB/archive/" "$KB/operating-framework/"`).
   If the KB doesn't answer, capture the question to the `## Questions`
   section of the user's onboarding file (see Step 5).
4. **Wait for confirmation.** When they say *"done"*, *"ok"*, *"✓"*, or
   similar, mark the item checked **in the file** by flipping `- [ ]` →
   `- [x]` for that exact line, then commit:
   ```bash
   scripts/promote entity \
       archive/onboarding/<email-slug>.md \
       --message "onboarding: <short item summary> done" \
       --source manual --confidence high
   ```
5. **Summarize every 3 items:** *"Three down. Next up: <next item>."*
6. **Never batch.** Don't dump the full checklist. One item at a time.

Offer a **pause** after every major section (basics, accounts, team intros):
*"Want to take a break here? I'll remember exactly where we left off."*
Resume on next session using `memory/onboarding-progress.md` (the file
itself is the durable record; the local cache is just a UX shortcut).

### Why delegations matter

Checking boxes is work. Having the assistant do the work is the product.
For day-1 value, the scheduling delegation alone saves the new hire 2–3
hours of back-and-forth their first week. Every future pack that maps to
an onboarding item compounds this — by v2.x we want 60%+ of checklist
items to be actively delegated, not just reminded.

## Step 4 — Handle cross-references gracefully

The onboarding body often links to other KB locations
(`operating-framework/`, team pages, app lists). When the user hits a link:

- Open the linked file (it's a relative markdown link inside the KB).
- Summarize the first 2–3 paragraphs in plain English.
- Ask: *"Want the full page or is that enough for now?"*
- Cache the summary into `memory/company-context.md` so you can refer
  back later without re-reading.

## Step 5 — Capture questions the checklist doesn't answer

If the user asks something their onboarding doesn't cover:

1. Try to answer from the KB (`rg` over `core/`, `archive/`,
   `operating-framework/`).
2. If the KB has the answer, give it in plain English. Then **append the
   Q+A pair** to the `## Questions` section of their onboarding file via
   `scripts/promote entity archive/onboarding/<email-slug>.md`. This is
   a pre-authorized write under Contract §9 — the pattern is established
   and the user is editing their own onboarding file.
3. If the KB doesn't have the answer, say: *"I don't know yet. I'll
   capture it so we can ask <their manager / People Ops> together. I'll
   pick the conversation back up once we have an answer."* Append the
   open question to `## Questions` (with `Answer: TBD`) and flag it in
   `logs/session-log.md`.

This builds an organic FAQ that compounds across hires — every future
new hire gets the benefit because the file lives in the shared KB.

## Step 6 — Completion

When every checklist item is checked:

1. Set `status: complete` and `completed_at: <YYYY-MM-DD>` in the
   frontmatter via `scripts/promote entity
   archive/onboarding/<email-slug>.md --message "onboarding: complete"`.
2. Append a final summary to the body under `## Completion`:
   > *"Onboarding complete on <YYYY-MM-DD>. <N> items walked through.
   > <N> new questions captured. Time from start → complete: <X days>."*
3. Announce to the user: *"You've finished Alpha onboarding. I'll keep
   your plan as a reference. From here on I'll help with your
   day-to-day work."*
4. Run the one-question retro from `setup-questionnaire.md` "Follow-up
   cadence": *"Was anything missing from what I walked you through?"* —
   if the user answers, append it to `## Questions` so the next hire
   benefits.
5. Return to normal mode (Block 3 of `setup-questionnaire.md` if not
   already done, else back to steady-state).

## Failure modes

- **KB unreachable / `kb-status: pending`:** Cache progress locally
  (`memory/onboarding-progress.md`), tell the user once: *"I can't reach
  the company brain right now — I'll hold your progress and re-sync
  when access lands."* Never block the user's session.
- **`git pull --rebase` conflict on the onboarding file:** another agent
  promoted to it concurrently. Follow `CONFLICT-PLAYBOOK.md` — re-read
  the file, replay the user's last confirmation, retry. Never silent
  merge.
- **Multiple files match the email slug:** shouldn't happen (slug is
  unique by email), but if it does, ask which is theirs. Never guess.
- **Template body differs from what you expect:** degrade gracefully.
  Walk through whatever checklist items you find. Don't force the user
  through items that aren't in their plan.
- **User says "skip the rest" mid-flow:** accept it. Append `_(skipped
  by user on <YYYY-MM-DD>)_` to each remaining item — do **not** flip
  to `- [x]`. Move on.
