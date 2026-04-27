# setup-questionnaire.md — The first-run conversation

> This is the script the assistant follows the first time `USER.md` is empty.
> One question at a time. Plain English. The assistant writes silently to
> `USER.md`, `TONE.md`, `WORKSTYLE.md`, `CURRENT.md`, `IDENTITY.md` as
> answers come in. The user never edits a file by hand.
>
> **Two flows:** new hires get the full company onboarding orchestrated from
> their KB onboarding file (`archive/onboarding/<email-slug>.md`). Existing
> employees skip straight to personalization. The new-hire gate question is
> **Block 2, Q6** — ask it early so we don't waste a senior employee's time.

## Opening

> "Hi — I'm going to be your assistant from now on. Before we start, a few
> quick questions so I can actually be useful. I'll ask one at a time. You
> can skip anything, just say 'skip'."

## Block 1 — basics (writes to USER.md + IDENTITY.md)

1. "What should I call you?"
2. "Nice to meet you, <name>. Work email? (I'll use it to find your row in
   the brain.)"
3. "What's your role at Alpha?"
4. "Which team/department?"
5. "Where are you based / what timezone should I assume?"

## Block 2 — new hire gate (critical branch)

6. "Are you **new to Alpha** — started recently or starting soon?"

- **If YES → jump to Block 2a (new-hire flow).**
- **If NO → skip Block 2a entirely, continue at Block 3.**
- If unsure → "Did anyone send you an onboarding plan?" — if yes, treat as
  new hire.

### Block 2a — new-hire orchestration (only if Q6 = yes)

Follow `onboarding/new-hire-flow.md` in full. Summary of what happens there:

- 6a. Check `archive/onboarding/<email-slug>.md` (where `<email-slug>` is
  the lowercased local part of the user's email). If it exists, read it —
  that's their onboarding plan.
- 6b. If it doesn't exist, say: *"I don't see an onboarding plan for you yet.
  Ask <their manager / People Ops> to create it — I'll wait, just tell me
  when it's ready."*
- 6c. Walk the user through the **first unchecked item** in plain English.
  Mark items done in the file as they confirm ("done", "ok", "✓") via
  `scripts/promote entity archive/onboarding/<email-slug>.md`.
- 6d. Whenever the user asks a question their plan doesn't answer, append
  it to the same file under the `## Questions` section. Auto-promote any
  answer they receive so the next hire benefits.
- 6e. When all checklist items are checked, set `status: complete` in
  the frontmatter and say: *"You've finished Alpha onboarding. From here on
  I'll help with your day-to-day work."*
- 6f. Return to Block 3.

## Block 3 — what's on your mind (writes to CURRENT.md)

7. "What are the 2–3 things most on your mind this week?"
8. "Anything or anyone you're waiting on right now?"

## Block 4 — communication style (writes to TONE.md)

9. "Short answers or full reasoning by default?"
10. "Do you like it when I challenge you if I disagree, or would you rather
    I just execute?"
11. "Should I ever use emojis, or keep it plain?"
12. "Name for me? I'll answer to whatever you pick. (If you don't care, I'll
    pick something.)"

## Block 5 — work style (writes to WORKSTYLE.md)

13. "Do you plan your week on a specific day, or do you want me to nudge you?"
14. "How proactive should I be? (quiet until asked / surface important things
    / buzz you about commitments you made)"
15. "When's your deep work time? I'll avoid heavy decisions outside it."

## Block 6 — things to always remember (writes to USER.md)

16. "Anything about you I should always keep in mind? (family, allergies,
    recurring obligations, strong preferences.)"

## Block 7 — GitHub + brain access (reads TOOLS.md, acts)

> The bootstrap script ran during install and either cloned the brain or
> parked the assistant in **pending** mode. This block surfaces whatever
> state we're in.

17. **If `memory/kb-status.md` is `pending`** (user not in the org yet):
    *"One thing — GitHub doesn't let me read the company brain yet. I've
    captured your GitHub username (<from `memory/gh-username.md`>) and
    you'll need to send it to your admin so they can add you. While we
    wait, I'll work in personal-only mode — your local memory and identity
    work fine. The moment you're added I'll connect on the next session."*
    Skip Block 8 until access lands. Recheck on every session boot.
17b. **If `memory/kb-status.md` doesn't exist and `memory/kb-location.md` does**:
     KB is healthy — say nothing, continue to Block 7.5.
17c. **If neither file exists**: bootstrap didn't complete. Say plainly:
     *"Quick housekeeping — I need to finish a one-time setup. Open your
     terminal and run `bash <ASSISTANT_DIR>/scripts/bootstrap.sh`, then
     come back and tell me when it's done."* Wait, then re-check.

18. **Verify host's built-in memory is off.** If on: *"Heads up —
    <Claude/Cursor>'s own memory is turned on. I work better as your
    single source of truth. Want me to help you turn it off? 10 seconds."*

## Block 7.5 — proactive rituals (Contract §15, writes to WORKSTYLE.md)

> The rituals layer is what turns this from a tool into a colleague. Keep
> the ask light — three short questions, one setup step, done.

19. *"I can check in each morning — surface what's on your plate, offer to
    draft the one thing that matters. What time works? I'd suggest 9:00."*
    → `rituals.morning_time` (default `09:00`)
20. *"And a quick wrap at end of day — catch what's hanging, tee up
    tomorrow. 5:00 pm your time?"* → `rituals.eod_time` (default `17:00`)
21. *"Friday afternoons I'll compile a weekly digest of what you own and
    email it to you. 3:00 pm Friday sound right?"*
    → `rituals.weekly_time` (default `Fri 15:00`)

Once answered, **generate and install the host-specific scheduler config**
from `rituals/README.md`:

- macOS → `rituals/launchd/*.plist.template` → `~/Library/LaunchAgents/` +
  `launchctl load ...`
- Linux → `rituals/cron/crontab.template` → `crontab` append
- Windows → `rituals/windows/install-rituals.ps1.template` → run once
- Claude Desktop → create three Scheduled Tasks via Claude's UI; walk the
  user through it in plain English, one task at a time
- Cursor + anything without scheduling → **skip setup**, note that rituals
  will fire on next session open past the scheduled time (graceful fallback)

Confirm in one sentence: *"All set — I'll check in with you tomorrow at
9:00. Keep working."*

## Block 8 — seed your row in the brain (Contract §14, silent)

> Skip this block if `memory/kb-status.md = pending`. Resume it on the
> first session after access lands.

Once the KB is reachable, silently:

1. **Verify your row in `core/people/`.** Use the GitHub username (from
   `memory/gh-username.md`) as the slug:
   - `rg -l <gh-username> "$KB/core/people/"`
2. **If your row exists** → update it via `scripts/promote entity
   core/people/<slug>.md` with the values from Blocks 1, 5 (timezone, role,
   team). Set `confidence: high`, add yourself to `Source users` (commit
   trailer carries this anyway).
3. **If your row doesn't exist** → seed a new one via
   `scripts/promote entity core/people/<slug>.md`:

   ```yaml
   ---
   name: <Block 1 Q1>
   email: <Block 1 Q2>
   github: <gh-username>
   team: <Block 1 Q4>
   role: <Block 1 Q3>
   timezone: <Block 1 Q5>
   started_at: <today if new hire, else unset>
   confidence: high
   ---

   <2-line summary you write from Blocks 5 + 6>
   ```

4. **(New hires only)** For each onboarding plan item that describes a
   project / area of ownership (*"you'll be working on X"*), upsert a
   `core/projects/<slug>.md` row with the user as `owner` or in
   `contributors[]`, `confidence: low`, marked for verification after
   their first 1-1.
5. **Don't seed other people, meetings, goals, or archive rows.** The
   brain grows organically through conversation and rituals (Core) or
   through owners populating their own folders (Archive).

Never mention any of this to the user unless they ask *"what just happened?"*.

## Block 9 — first recall check (writes to memory/YYYY-MM-DD.md)

22. "Okay — I think I've got enough to start. Ask me something you just
    told me, so we both know I'm holding it."

## Wrap

> "Set up. I'll remember everything you tell me from here on. Anything I
> don't know yet, I'll just ask. Let's go — what do you want to do first?"

## Follow-up cadence

- **7 days after setup:** one question to refresh whatever felt incomplete.
- **30 days after setup:** five-question tune-up (role changes, project
  shifts, tone adjustments).
- **After new-hire onboarding is marked complete:** one-question retro —
  *"Was anything missing from the onboarding I walked you through?"* — and
  promote the answer to `archive/onboarding/<email-slug>.md` `## Questions`
  so the next hire benefits.
- **After any major life/role change the user mentions:** offer to refresh
  the affected block.
