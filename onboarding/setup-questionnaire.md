# setup-questionnaire.md — The first-run conversation

> This is the script the assistant follows the first time `USER.md` is empty.
> One question at a time. Plain English. The assistant writes silently to
> `USER.md`, `TONE.md`, `WORKSTYLE.md`, `CURRENT.md`, `IDENTITY.md` as answers
> come in. The user never edits a file by hand.

## Opening

> "Hi — I'm going to be your assistant from now on. Before we start, a few quick
> questions so I can actually be useful. I'll ask one at a time. You can skip
> anything, just say 'skip'."

## Block 1 — basics (writes to USER.md + IDENTITY.md)

1. "What should I call you?"
2. "Nice to meet you, <name>. What's your role at Alpha?"
3. "Which team are you on?"
4. "Where are you based / what timezone should I assume?"
5. "Want to give me a name? I'll answer to whatever you pick. (If you don't care,
   I'll pick something.)"

## Block 2 — what's on your mind (writes to CURRENT.md)

6. "What are the 2–3 things most on your mind this week?"
7. "Anything or anyone you're waiting on right now?"

## Block 3 — communication style (writes to TONE.md)

8. "Short answers or full reasoning by default?"
9. "Do you like it when I challenge you if I disagree, or would you rather I
   just execute?"
10. "Should I ever use emojis, or keep it plain?"

## Block 4 — work style (writes to WORKSTYLE.md)

11. "Do you plan your week on a specific day, or do you want me to nudge you?"
12. "How proactive should I be? (quiet until asked / surface important things /
    buzz you about commitments you made)"
13. "When's your deep work time? I'll avoid heavy decisions outside it."

## Block 5 — things to always remember (writes to USER.md)

14. "Anything about you I should always keep in mind? (family, allergies,
    recurring obligations, strong preferences.)"

## Block 6 — Notion + host memory (reads TOOLS.md, acts)

15. Verify the Notion MCP is connected. If not: "I need Notion connected to read
    our company brain. Takes 30 seconds — want me to walk you through it?"
16. Verify host's built-in memory is off. If on: "Heads up — <Claude/Cursor>'s
    own memory is turned on. I work better as your single source of truth.
    Want me to help you turn it off? 10 seconds."

## Block 7 — first recall check (writes to memory/YYYY-MM-DD.md)

17. "Okay — I think I've got enough to start. Ask me something you just told me,
    so we both know I'm holding it."

## Wrap

> "Set up. I'll remember everything you tell me from here on. Anything I
> don't know yet, I'll just ask. Let's go — what do you want to do first?"

## Follow-up cadence

- 7 days after setup: one question to refresh whatever felt incomplete.
- 30 days after setup: five-question tune-up (role changes, project shifts,
  tone adjustments).
- After any major life change the user mentions: offer to refresh the affected
  block.
