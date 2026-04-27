# pack: company-rituals — morning, end-of-day, weekly

> Foundational. Ships by default. Implements Contract Rule 15.
> Every ritual runs `scripts/sync-kb` first so context is fresh.

## The three rituals

| Ritual | Default time | What happens |
|---|---|---|
| **Morning check-in** | weekday 9:00 (configurable) | sync-kb → since-last-session briefing → daily orient |
| **End-of-day wrap** | weekday 17:30 | capture the day → surface one hanging thread → replay pending-writes queue |
| **Weekly review** | Friday 16:00 | look-back + look-ahead → email owner digest |

User configures times in `WORKSTYLE.md` during onboarding Block 7.

## Morning check-in

Steps:

1. Run `scripts/sync-kb`. If new commits since the user's last session, hold
   the diff for the briefing.
2. Run `scripts/preflight`. If red, tell the user plainly + run
   `scripts/bootstrap` if needed. If `kb-status.md = pending`, skip the
   briefing and run partial mode.
3. Read today's daily note in `memory/`, or create it.
4. Read `CURRENT.md` for what's on the user's plate.
5. Compose the message — 4–6 sentences:
   - One-sentence greeting referencing a specific current thread.
   - Top 1–2 changes from "since last session" briefing (if any).
   - The day's one most important thing per `CURRENT.md`.
   - Any at-risk goal where the user is `owner:` (read from `core/goals/`).
   - One-sentence offer: *"Want me to draft your update for the design sync at 11?"*

Skip the briefing entirely on weekends unless the user has overridden
`workstyle.weekend_rituals = true`.

## End-of-day wrap

Steps:

1. Run `scripts/sync-kb`.
2. Read `memory/<today>.md`.
3. Replay `logs/pending-writes.md` if any items are queued and the KB is
   reachable now.
4. Compose the message — 3–5 sentences:
   - One-sentence "today's shape" (what got done, what's open).
   - One **hanging thread** — a thing the user said in the morning that
     didn't close.
   - One small unblocking offer for tomorrow.

Append the message to `memory/<today>.md` so the morning briefing has
continuity.

## Weekly review

Triggered Friday afternoon (or last weekday if Friday is a holiday).

Steps:

1. Run `scripts/sync-kb`.
2. Look-back:
   - `git -C $KB log --since="last Monday" --oneline -- core/` — what changed
     in the brain.
   - `rg` user's own commits via `Promoted-By: <user-slug>` trailer.
   - From `memory/<each-day-this-week>.md` — what the user themselves logged.
3. Look-ahead:
   - Goals where the user is `owner:` and `status: at-risk` or `off-track`.
   - Upcoming meetings on Calendar (if Google Calendar MCP is connected).
   - Pending inbox items targeting entities the user owns.
4. Compose the **weekly owner digest** per `digests/email-weekly.md`.
5. Open a `mailto:` link in the user's default mail client with the digest
   pre-filled. The user clicks send.

The digest contains GitHub web URLs (commit + file blob) for every entity
mentioned, so owners can click through to consolidate.

## Sensitivity filter — applies to all rituals

Before sending any ritual message, run the Rule 14 sensitivity check on each
line. Filter out anything that's:

- Negative feedback about named colleagues.
- Personal frustration with a specific person.
- Health / family / personal-life matters.
- Compensation / career / interview content.
- Anything the user marked private.

Sensitive content stays in `memory/` and never appears in rituals or the digest.

## User controls (all honored immediately, persisted to `WORKSTYLE.md`)

- *"Skip today's check-in"* — one-shot.
- *"Pause rituals for a week"* — sets `rituals.paused_until: <date>`.
- *"Move morning to 10"* — updates `rituals.morning_time`.
- *"No digest this week"* — sets `rituals.digest_skip: this_week`.
- *"Stop the weekly digest"* — sets `rituals.digest_enabled: false`.

## Scheduling — graceful fallback

The assistant generates per-host scheduler config from templates in:

- `rituals/launchd/*.template` — macOS
- `rituals/cron/*.template` — Linux
- `rituals/windows/*.template` — Windows Task Scheduler XML

If the user declines scheduler setup, rituals **still fire** on the next
session open past their configured time. The assistant detects this by
comparing now against the configured time stored in `WORKSTYLE.md` plus
the timestamp in `memory/last-ritual-run.md`.

## Never interrupt

If the user is mid-conversation when the scheduled time hits, the assistant
queues the ritual and fires it at the next natural pause (3+ second user
silence, or after the assistant replies and the user goes quiet).
