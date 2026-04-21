# pack: company-writing

> Alpha's writing voice and structure, applied when the user is drafting
> anything customer-facing, cross-team, or public. Keeps tone consistent
> across every person's assistant.

## When this pack activates

- User asks for a draft, an edit, a rewrite, or review of a piece of writing.
- User pastes a doc and asks for feedback.
- Meeting pack hands off a summary that needs to go to a wider audience.

## Alpha writing principles (distilled)

1. **Lead with the decision, then the reasoning.** Readers skim first, dive
   in only if the lede hooks them. Never bury the ask.
2. **Short sentences.** Aim for 15–20 words. Break anything longer.
3. **Concrete over abstract.** "We shipped the onboarding refactor" beats
   "We made progress on the onboarding initiative."
4. **No hedging verbs.** Strike "maybe", "perhaps", "I think", "it seems".
   Either say it or cut it.
5. **Names + numbers + dates.** Every claim that can be verified should name
   the source, quantity, or deadline.
6. **Async-first formatting.** Headers, bullets, bold for scannability.
   People read on phones between meetings.
7. **Respect the reader's time.** If the doc is more than 3 screens, write a
   TL;DR at the top.

## When editing someone else's draft

- Preserve their voice — don't rewrite into yours. Tighten, don't transform.
- Flag factual claims that look wrong. Don't silently "fix" data.
- If the structure is broken, explain the re-org in a one-line comment at
  the top, don't just re-order.

## Output format when drafting from scratch

Always produce:

1. **Title** — 5–8 words, states the takeaway.
2. **TL;DR** — 2–3 sentences, the decision or ask.
3. **Body** — headers + bullets, 1 screen if possible.
4. **Appendix / details** — everything that didn't fit above.

## Company-specific glossary

Use `onboarding/company.md` (kept fresh from the Operating Framework) as the
source of truth for Alpha terminology. If the user uses a term that isn't in
the glossary yet, capture it silently to the glossary on first use.

## What NEVER to do

- Don't auto-send. Drafting is local; sending is an explicit user action.
- Don't promote draft text to Notion. Only finalized, shared content goes
  into `## Assistant Updates` — and even then, summarized.
- Don't add jargon to seem smart. Alpha's voice is plain.

## Per-user overrides

In `TONE.md`, the user can set:

- `writing.formality`: `casual` / `neutral` / `formal` (default: `neutral`)
- `writing.audience_default`: `internal` / `external` (default: `internal`)
- `writing.emoji_ok`: true/false (mirrors `TONE.md` base rule)
