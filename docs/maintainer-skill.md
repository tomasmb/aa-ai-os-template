# Maintainer playbook — Alpha AI OS

> For whoever owns the template, the Notion hub, and the release cadence.
> Today that's Tomás. As the system matures, delegate areas from the Ownership
> table in [7 — Governance & Versioning](https://www.notion.so/3492901d79088150aab3ebf136bb046e).

## Canonical sources

- **Git repo** (maintainer truth): [`tomasmb/aa-ai-os-template`](https://github.com/tomasmb/aa-ai-os-template)
- **Notion hub** (user truth): `Alpha AI OS — V1`
- **Spec:** [`docs/SPEC.md`](./SPEC.md) in this repo

If the two disagree, the repo wins. Edit spec → open PR → merge → update Notion to match.

## Weekly review (60–90 minutes, ideally same slot every week)

1. **Pending promotions audit.** Open the Notion hub. For each active page with an
   `## Assistant Updates` section, scan the inbox. Flag stale items (>14 days) to the
   page owner. Drafts a consolidation on request.
2. **Error queue.** Grep pilot users' `logs/pending-writes.md` (or sampled Slack
   reports). Look for: repeated Notion failures, `CONTRACT.md` rule misses, confused
   onboarding. Turn patterns into backlog items.
3. **Template drift.** `git log --since "1 week ago"` on the repo. If anything
   shipped, verify the corresponding Notion page was updated too.
4. **Pilot feedback.** Read the pilot channel / DMs. One concrete improvement per
   week lands in the backlog.
5. **Decisions log.** Anything non-trivial decided this week → append to
   `memory/decisions.md` in your own openclaw workspace (or wherever you track
   personal decisions). Don't push maintainer personal notes into this repo.

## Release process

For every release:

1. Branch off `main`, make changes, open a PR.
2. At least one reviewer from Core Team (async, 72h SLA).
3. On merge: bump `.version`, update changelog snippet for the release, tag
   `v<x.y.z>`, push tag.
4. Attach the freshly built zip as a release asset. Zip recipe:
   ```bash
   cd <parent-of-repo-checkout>
   cp -r aa-ai-os-template alpha-assistant
   zip -r alpha-assistant-v<x.y.z>.zip alpha-assistant -x "*.DS_Store" "alpha-assistant/.git/*"
   rm -rf alpha-assistant
   shasum -a 256 alpha-assistant-v<x.y.z>.zip
   ```
5. Update the download callout on the Notion "Get Your Assistant" page: URL
   (always latest/download/... is stable) + new sha256 + plain-English changelog.
6. Announce in the pilot channel with the plain-English changelog only
   (no semver in the announcement — Rule 3 applies to humans too).

## Pre-rollout checklist

Before telling employees at large, these must be true:

- [x] `manifest.json` attached to the latest release (so update checks work).
      *Shipped in v1.1.0.*
- [x] `NOTION-SYNC.md` has real page URLs for: AI OS hub, Operating Framework,
      Team directory, New Hire Onboarding DB, Onboarding Modules, Packs Library,
      Promotion Rules. *Shipped in v1.1.0.*
- [x] New hire gate built into `setup-questionnaire.md` + `new-hire-flow.md`.
      *Shipped in v1.1.0.*
- [x] `packs/company-writing.md` and `packs/company-meetings.md` exist.
      *Shipped in v1.1.0. Meetings pack is read.ai-ready.*
- [ ] **Every page the assistant writes to has an `## Assistant Updates` section.**
      At minimum: the hub, Operating Framework, each top-level Team page.
      *Tracked in the roadmap page; owner: Tomás / each team lead.*
- [ ] **Owner-digest channel is live** (Slack DM or email — weekly consolidation
      of what landed in each page's inbox).
- [ ] **3 non-maintainer pilot users** ran the full onboarding + used it for a
      week with no major complaints.

Items 1–4 are **done**. Items 5–7 are the remaining gates before company-wide
rollout.

## How to add `## Assistant Updates` sections at scale

The fastest way is a one-time script run by the page owner:

1. Open the page.
2. At the very bottom, add:
   ```
   ## Assistant Updates

   > This section collects auto-promoted notes from people's AI assistants.
   > Reviewed weekly by the page owner and consolidated into the canonical
   > content above. Do not edit canonical content from this section.
   ```
3. Save. That's it — the assistant starts writing here on next session.

Track adoption in a simple Notion checklist: one row per canonical page,
checked when the inbox is live.

## Anti-patterns to avoid

- **Over-building before N=3 adopters.** Every feature proposal should name the
  specific pilot user whose pain it solves.
- **Letting maintainer notes leak into the repo.** This repo ships to every
  employee. Personal scratch belongs in your own workspace, not in `docs/`.
- **Skipping the plain-English changelog.** Users see dates and sentences, not
  semver. If you don't have a sentence, you don't have a changelog.
- **Writing to canonical Notion sections from the assistant.** Only the inbox.
  If you catch the AI writing canonical, it's a Contract bug, not a preference.

## When to update the Contract

Updating the Contract changes the behavior of every assistant in every org. Do
it only when:

- A rule is wrong in the wild (AI is doing something users hate).
- A new universal behavior is provably better (proven on 3+ pilots).

Minor behavior additions → packs. Org-specific behavior → primers. Contract
changes are the last resort, not the first.

## Post-mortems

For anything that pages an employee's trust in the assistant (bad Notion write,
lost memory, confusing onboarding), write a short post-mortem. Save it as a
sub-page under `[0 — Design Decisions (locked)]`. Include: what happened, what
the Contract rule should have prevented, what we changed. These are the only
way we get the Contract right at scale.
