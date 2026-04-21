# setup-questionnaire.md — The first-run conversation

> This is the script the assistant follows the first time `USER.md` is empty.
> One question at a time. Plain English. The assistant writes silently to
> `USER.md`, `TONE.md`, `WORKSTYLE.md`, `CURRENT.md`, `IDENTITY.md` as answers
> come in. The user never edits a file by hand.
>
> **Two flows:** new hires get the full company onboarding orchestrated from
> their Notion onboarding card. Existing employees skip straight to
> personalization. The new-hire gate question is **Block 2, Q6** — ask it
> early so we don't waste a senior employee's time on day-one material.

## Opening

> "Hi — I'm going to be your assistant from now on. Before we start, a few quick
> questions so I can actually be useful. I'll ask one at a time. You can skip
> anything, just say 'skip'."

## Block 1 — basics (writes to USER.md + IDENTITY.md)

1. "What should I call you?"
2. "Nice to meet you, <name>. Work email? (I'll use it to look you up in Notion.)"
3. "What's your role at Alpha?"
4. "Which team/department?"
5. "Where are you based / what timezone should I assume?"

## Block 2 — new hire gate (critical branch)

6. "Are you **new to Alpha** — started recently or starting soon?"

- **If YES → jump to Block 2a (new-hire flow).**
- **If NO → skip Block 2a entirely, continue at Block 3.**
- If unsure → "Did you get a New Hire Onboarding card in Notion?" — if yes, treat as new hire.

### Block 2a — new-hire orchestration (only if Q6 = yes)

Follow `onboarding/new-hire-flow.md` in full. Summary of what happens there:

- 6a. Find their onboarding card in the `👋 New Hire Onboarding` Notion database
  by name / email. If missing, say: *"I can't find your onboarding card yet. Ask
  <their manager / People Ops> to create one — here's the template link. I'll
  wait, just tell me when it's ready."*
- 6b. Read the card's body (synced from the department template).
- 6c. Surface the **first unchecked item** in plain English. Walk them through
  it conversationally. Mark it done in Notion when they confirm ("done", "ok", "✓").
- 6d. Whenever they ask a question their onboarding doesn't answer, capture it
  into a sub-page called `Onboarding Questions` on their card (following the
  pattern of B Girang's card). Auto-promote any answer they receive to that
  sub-page so the next hire benefits.
- 6e. When all checklist items are checked, set their Status to `Complete` in
  the database and say: *"You've finished Alpha onboarding. I'll keep your card
  as a reference. From here on I'll help with your day-to-day work."*
- 6f. Return to Block 3.

## Block 3 — what's on your mind (writes to CURRENT.md)

7. "What are the 2–3 things most on your mind this week?"
8. "Anything or anyone you're waiting on right now?"

## Block 4 — communication style (writes to TONE.md)

9. "Short answers or full reasoning by default?"
10. "Do you like it when I challenge you if I disagree, or would you rather I
    just execute?"
11. "Should I ever use emojis, or keep it plain?"
12. "Name for me? I'll answer to whatever you pick. (If you don't care, I'll
    pick something.)"

## Block 5 — work style (writes to WORKSTYLE.md)

13. "Do you plan your week on a specific day, or do you want me to nudge you?"
14. "How proactive should I be? (quiet until asked / surface important things /
    buzz you about commitments you made)"
15. "When's your deep work time? I'll avoid heavy decisions outside it."

## Block 6 — things to always remember (writes to USER.md)

16. "Anything about you I should always keep in mind? (family, allergies,
    recurring obligations, strong preferences.)"

## Block 7 — Notion + host memory (reads TOOLS.md, acts)

17. Verify the Notion MCP is connected. If not: *"I need Notion connected to
    read our company brain. Takes 30 seconds — want me to walk you through it?"*
18. Verify host's built-in memory is off. If on: *"Heads up — <Claude/Cursor>'s
    own memory is turned on. I work better as your single source of truth.
    Want me to help you turn it off? 10 seconds."*

## Block 8 — first recall check (writes to memory/YYYY-MM-DD.md)

19. "Okay — I think I've got enough to start. Ask me something you just told me,
    so we both know I'm holding it."

## Wrap

> "Set up. I'll remember everything you tell me from here on. Anything I
> don't know yet, I'll just ask. Let's go — what do you want to do first?"

## Follow-up cadence

- **7 days after setup:** one question to refresh whatever felt incomplete.
- **30 days after setup:** five-question tune-up (role changes, project shifts,
  tone adjustments).
- **After new-hire onboarding is marked Complete:** one-question retro — *"Was
  anything missing from the onboarding I walked you through?"* — and promote the
  answer to `Onboarding Questions` so the next hire benefits.
- **After any major life/role change the user mentions:** offer to refresh the
  affected block.
