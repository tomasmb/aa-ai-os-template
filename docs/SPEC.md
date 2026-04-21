# Alpha AI OS — V1 Spec

- Status: canonical
- Owner: Tomás Morales
- Last revised: 2026-04-21
- Supersedes: `ai-os-mvp-thesis.md`, `alpha-v1-master-plan.md`, `alpha-v1-assistant-folder-standard.md`

## One-sentence pitch

A downloadable folder that turns **any AI tool** (openclaw, Claude Desktop, Cursor, Claude Code,
Codex CLI) into a personal assistant with soul and memory, wired into Notion as the company's
shared brain — so every employee operates with real continuity, and durable knowledge flows upward
automatically.

## The core insight

Build the thing once as a folder, not as an app. The folder IS the agent. You copy it to your
computer, open it with whatever AI tool you like, and it already knows who it is, who you are, and
how to behave. The tool is replaceable. The folder standard is the contract.

## Design principles

Every feature decision passes all six. If it fails any, it does not ship.

1. **The folder is the product.** Not an app. Not an extension. A folder of markdown.
2. **The AI is the UX.** Users only talk. No file editing, no commands, no folder browsing.
3. **Tool-agnostic.** Works in openclaw, Claude Desktop, Cursor, Claude Code, Codex CLI. The folder
   ships thin adapters (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`) so every supported tool picks it
   up automatically.
4. **Notion is the shared brain.** All durable, company-wide, cross-team knowledge lives in Notion.
   The local folder handles private and in-flight knowledge.
5. **Self-healing and self-improving.** The AI detects missing info, stale context, outdated
   templates, or disconnected MCPs, and fixes them — asking the user only when it truly needs input.
6. **Private by default, promoted deliberately.** Private memory stays local. Shared knowledge is
   promoted to Notion only when it meets the promotion rules — summarized, structured, deduped.

## The three layers

```text
┌───────────────────────────────────────────────────┐
│  Notion = shared company brain (canonical truth)  │
│  - org knowledge, team knowledge, decisions       │
│  - onboarding, packs, promotion rules             │
│  - visible, editable, human-facing                │
└──────────────────────┬────────────────────────────┘
                       │ MCP (read + conservative write)
┌──────────────────────┴────────────────────────────┐
│  Local assistant folder = personal runtime        │
│  - identity, soul, user profile, memory           │
│  - private notes, in-flight work                  │
│  - the AI Contract lives here                     │
└──────────────────────┬────────────────────────────┘
                       │ loaded by
┌──────────────────────┴────────────────────────────┐
│  AI tool = interaction interface                  │
│  openclaw / Claude Desktop / Cursor / Claude Code │
│  / Codex CLI                                      │
└───────────────────────────────────────────────────┘
```

Notion distributes. The folder runs. The assistant helps, remembers, and promotes.

## Folder contract

The canonical structure every Alpha AI OS install has. Tool-specific adapter files are optional and
only act as redirects into the main files.

```text
alpha-assistant/
  README.md                      what this folder is, how to use it
  AGENTS.md                      adapter for openclaw / Codex CLI
  CLAUDE.md                      adapter for Claude Code / Desktop
  .cursor/
    rules/
      alpha-assistant.mdc        adapter for Cursor

  SOUL.md                        identity, values, non-negotiable behavior
  CONTRACT.md                    the AI Contract (mandatory behavior rules)
  IDENTITY.md                    assistant name + vibe
  USER.md                        the employee's profile (filled during setup)
  TONE.md                        communication preferences
  WORKSTYLE.md                   planning, reminders, proactivity
  CURRENT.md                     short-horizon context (this week's priorities)
  NOTION-SYNC.md                 where to read from and write to in Notion
  PROMOTION-RULES.md             what gets promoted, how, to which scope
  TOOLS.md                       MCPs expected; fallback behavior if missing

  onboarding/
    setup-questionnaire.md       the conversation the AI runs on first boot
    new-hire-flow.md             orchestration playbook for the 👋 New Hire Onboarding DB
    company.md                   company context cache (pulled from Operating Framework)
    team.md                      team context cache (pulled from Team directory)
    role.md                      role context cache (from onboarding card + role page)

  packs/
    README.md                    how packs work, how to add/remove them
    company-writing.md           Alpha writing voice + structure (v1.1)
    company-meetings.md          meeting prep + ingest (read.ai-ready, v1.1)
    company-scheduling.md        1-1 + meeting scheduling via GCal MCP (v1.2)
    team-<team>.md               team-level pack (optional install)
    personal-*.md                user can add their own

  memory/
    YYYY-MM-DD.md                daily notes (one per day)
    decisions.md                 durable decisions with context
    relationships.md             who's who: collaborators, clients, family
    recurring-work.md            patterns the AI has noticed
    learnings.md                 things learned from outcomes
    onboarding-progress.md       mid-onboarding recovery state (new hires only)
    meetings/                    one file per meeting, structured header + raw notes
    templates/                   scaffolds the assistant fills in

  logs/
    session-log.md               append-only session summaries
    pending-writes.md            queue for captures that couldn't reach Notion

  manifest.json                  update manifest (version, sha256, changelog)
  .version                       folder-standard version for update/migration
  .backups/                      automatic pre-migration backups
```

### Zones

| Zone | Files | Owner | Who edits |
|---|---|---|---|
| **Company-standard (protected)** | `README.md`, `SOUL.md`, `CONTRACT.md`, `NOTION-SYNC.md`, `PROMOTION-RULES.md`, `onboarding/company.md`, `packs/company-*.md` | Alpha (central) | Updates via folder release |
| **Team-standard (semi-protected)** | `onboarding/team.md`, `packs/team-<team>.md` | Team lead | Team can customize |
| **Personal (editable)** | `USER.md`, `TONE.md`, `WORKSTYLE.md`, `CURRENT.md`, `onboarding/role.md`, `packs/personal-custom.md`, all of `memory/` and `logs/` | Employee | Employee + AI |

## The AI Contract (the heart of the product)

Shipped as `CONTRACT.md`. Non-negotiable. Loaded at every session start. This is what makes the
system work for non-technical people: every line shifts work from the user to the AI.

See `CONTRACT.md` (template below, in full form).

### Contract summary (the thirteen rules)

1. **Identity and tone.** Greet by name. Plain English only. Never mention files, paths, JSON, MCP,
   schemas. Acknowledge captures in ≤5 words.
2. **Session-start context load.** Always read SOUL, USER, CURRENT, latest daily note, CONTRACT.
   Produce a 1–2 sentence greeting that references specific context to prove continuity.
3. **Update awareness.** Once per day, check for a new folder version. Mention once in plain
   English with a date and a one-line changelog ("A new version shipped Friday — 3 small
   improvements"). Never say semver unless the user explicitly asks.
4. **Proactive capture.** When the user states a fact, decision, preference, or commitment,
   capture it without asking. Create entities if they don't exist.
5. **Onboarding (two flows, gated).** If USER is incomplete, run the setup conversation — one
   question at a time, plain English, skip anything the user skips. Ask early whether the user is
   a new hire. **If new hire:** orchestrate the full company onboarding from their card in the
   `👋 New Hire Onboarding` Notion database (walk the checklist item-by-item, mark items done in
   Notion, capture Q&A to an `Onboarding Questions` sub-page on their card — see
   `onboarding/new-hire-flow.md`). **If existing employee:** skip the new-hire flow entirely and
   go straight to personalization. Also detect if the host's built-in memory is on and offer to
   turn it off (the AI OS is the single source of truth).
6. **Recall and truthfulness.** Answer from memory or say "I don't have that yet." Never invent.
7. **Self-repair.** Every boot, verify schema version, MCP connections (especially Notion),
   host-memory toggle, maintenance schedule, daily note, USER completeness. Fix with one-question
   consent.
8. **Update execution.** Back up → fetch new release from GitHub → verify sha256 → migrate →
   reload. Rollback on any failure. Report in plain English.
9. **Auto-promote to Notion.** When user says something that qualifies under Promotion Rules,
   write it to Notion without asking — but only into the target page's "Assistant Updates" inbox
   section, never directly into canonical content. Always summarize. Always dedupe against nearby
   existing entries (update, don't duplicate). Creating a new Notion page still requires explicit
   consent; appending to an existing page does not.
10. **Privacy.** Never transmit workspace contents except through user's explicit action or an
    auto-promote that matches Rule 9. On "what do you know about me?", dump a plain-English
    summary, not raw files.
11. **Forgetting.** "Forget X" → delete + tombstone + confirm in one sentence. Also remove from any
    Notion inbox entries traceable to this user's assistant.
12. **Failure modes.** Tool errors retry once, then surface plainly. Never silently lose data.
13. **Non-goals.** Never teach folder structure unprompted. Never dump JSON. Never ask permission to
    remember things locally. Never batch onboarding questions. Never show semver unless asked.

The full Contract text lives in `CONTRACT.md` (see template section below).

## Distribution — public template, private content

The folder is distributed in two halves, which is what makes it safe and easy at the same time:

- **Public GitHub repo** `tomasmb/aa-ai-os-template` — contains ONLY the generic template
  (Contract, SOUL, file scaffolding, adapter files, setup questionnaire, empty personal templates).
  Nothing sensitive. Nothing Alpha-specific. Permissions-free download.
- **Alpha-specific content stays in private Notion** — company primer, team primers, packs. The
  assistant pulls whatever it needs on first run via the Notion MCP the user already has auth for.

The "Get Your Assistant" Notion page is the front door: one big **Download** button pointing to the
latest GitHub release zip. User clicks → gets a zip → unzips → opens the folder in their AI tool.
No git, no permissions, no CLI.

Power users can `git clone` the repo if they want, but zero non-technical users need to.

## Setup flow — zero questions at install, all questions in conversation

1. User downloads the zip from the Notion "Get Your Assistant" page.
2. User opens the folder in their AI tool of choice. The adapter file (AGENTS.md, CLAUDE.md, or
   cursor rules) points the AI to `CONTRACT.md`.
3. AI loads the Contract. Detects USER.md is incomplete. Per Contract §5, runs setup:
   - "Hi — I'm going to be your assistant from now on. What should I call you?"
   - "Nice to meet you, <name>. What's your role?"
   - "What team are you on?"
   - "What are the 2–3 things most on your mind this week?"
   - "Anything you'd always want me to remember? (partner, kids, allergies, recurring meetings)"
   - "How do you like to be communicated with — concise or thorough? Proactive or only when asked?"
4. AI writes USER.md, TONE.md, WORKSTYLE.md, CURRENT.md silently during the conversation.
5. AI checks MCP availability (Notion first). If Notion is not connected, AI explains plainly what
   to do for the user's specific tool (see "Notion MCP setup by host" section). Offers to help.
6. AI confirms: "Set up. I'll remember everything you tell me. Try me — ask me anything."

The user has only typed natural-language answers. No file edits. No paths. No commands.

## Notion MCP setup by host

Different tools wire up MCPs differently. The AI Contract §7 (self-repair) includes checking Notion
availability at every boot. If missing, the AI tells the user the exact steps for their host.

### Claude Desktop
- Install the Notion extension (`.mcpb`) from `notion.so/mcp` or from desktopextensions.com.
- One click. Auth via OAuth in browser.
- AI detects connection via `notion-search` tool availability.

### Cursor
- Cursor Settings → Features → Model Context Protocol → Add MCP server.
- Preferred: `https://mcp.notion.com` (hosted, OAuth).
- AI detects via presence of `notion-*` tools.

### Claude Code
- Edit `~/.claude/mcp.json` or project-level `.mcp.json`.
- Add the Notion MCP server (hosted URL preferred).
- Reload Claude Code.

### Codex CLI
- Edit `~/.codex/config.toml` → `[mcp_servers.notion]` block.
- Restart Codex.

### openclaw
- Already configured via `openclaw.json`. The plugin `plugin-notion-workspace-notion` provides all
  `notion-*` tools automatically.

The folder ships `TOOLS.md` with these instructions. The AI walks the user through them if Notion
is missing. The AI never makes the user read the file directly — it reads it and conversates.

## Notion structure (the shared brain)

The canonical Notion hub page tree for V1:

```text
Alpha AI OS — V1                   (the hub, human-visible)
  ├── Overview                     what this is, how it works, who it's for
  ├── Get Your Assistant           download link + setup walkthrough
  ├── AI Contract                  canonical Contract text (synced from folder)
  ├── Folder Template              every file in the template, explained
  │     ├── SOUL.md
  │     ├── CONTRACT.md
  │     ├── IDENTITY.md
  │     ├── USER.md (template)
  │     ├── TONE.md (template)
  │     ├── WORKSTYLE.md (template)
  │     ├── CURRENT.md (template)
  │     ├── NOTION-SYNC.md
  │     ├── PROMOTION-RULES.md
  │     └── TOOLS.md
  ├── Tool Setup                   Claude Desktop / Cursor / Claude Code / Codex / openclaw
  ├── Promotion Rules              what gets promoted, how, to which scope
  ├── Onboarding Modules           company primer, role primers, team primers
  ├── Packs Library                optional capability packs
  ├── Governance & Versioning      how the template evolves, who owns what
  └── Roadmap                      where it's going
```

Every page is human-editable by the person accountable for that knowledge. The assistant only
writes to Notion under promotion rules.

## Promotion rules (AI → Notion)

### Promote to project scope when
- a decision changes execution
- a blocker affects multiple contributors
- a status change affects others
- a meeting creates shared follow-ups

### Promote to team scope when
- a workflow is reusable across the team
- a recurring issue is identified
- a norm changes
- a template becomes durable

### Promote to org scope when
- policy or definitions change
- multiple teams need the same insight
- a cross-cutting pattern is confirmed

### Keep local when
- private, sensitive, draft
- only useful to one person
- would create Notion noise

### How to promote (auto, with guardrails)
- **Auto-promote without asking** — per Contract §9. Speed matters more than ceremony.
- **Promote to the target page's "Assistant Updates" section**, NEVER directly into canonical
  content. Owners consolidate inbox → canonical on their own cadence.
- **Always summarize first.** Never dump raw transcripts.
- **Always update existing entries** if a semantic match exists in the "Assistant Updates" section
  or nearby canonical content. Dedupe is mandatory.
- **Creating a new Notion page requires explicit consent.** Appending to existing pages does not.
- **Use the promotion format** in `PROMOTION-RULES.md`: title, decision, context, who, next step,
  auto-tag with "promoted by <user>'s assistant on <date>".
- **Owner notification** — weekly Slack digest (or equivalent) to each page owner listing pending
  assistant updates on their pages. Never a modal, never a per-item ping.

## Update & versioning mechanism

The folder is downloadable from a public GitHub release. To handle iteration:

- **Template version** is semver internally (e.g. `1.4.2`), tracked in `.version`.
- **Users never see semver.** They see dates and plain-English changelogs:
  - Default silent state: *"Your assistant is up to date."*
  - Update available: *"A new version shipped Friday — 3 small improvements. Want me to upgrade?"*
  - Changelog shown as sentences, not bullets of fix-IDs.
  - If asked directly: *"Up to date as of April 21. (v1.4.2 if you want the technical answer.)"*
- **Remote manifest** at `https://github.com/tomasmb/aa-ai-os-template/releases/latest` — the
  assistant parses the release metadata + an attached `manifest.json` asset with the bundle URL,
  sha256, plain-English changelog, and any migration scripts.
- **AI checks once per day** (Contract §3). Non-blocking single sentence if an update exists.
- **`/update`** is the consent path. On yes:
  1. Back up everything to `.backups/pre-update-<date>.tar.gz`.
  2. Download the release zip + verify sha256.
  3. Overwrite ONLY protected/company-standard files. Leave personal files alone.
  4. Run any schema migrations in order.
  5. Write new `.version`.
  6. Reload Contract.
  7. Report in plain English: *"Updated. This release: faster search, better meeting summaries."*
- **On failure**, restore from backup and report plainly.

The assistant never touches personal files (USER, TONE, WORKSTYLE, CURRENT, memory/, logs/) during
an update.

## Claude's built-in memory — off

The AI OS folder IS the memory. Running two memory systems in parallel creates conflicts,
duplicated facts, and unclear source of truth. At setup, the Contract requires the assistant to
detect if the host's built-in memory is on and offer to walk the user through turning it off
(10 seconds). This is covered in Contract §7 and TOOLS.md.

If the host doesn't expose a programmatic toggle, TOOLS.md ships step-by-step instructions per
host that the assistant reads and walks the user through in conversation.

## Success metrics

- **Activation.** % of installs that complete setup (USER/TONE/WORKSTYLE filled) within 24h.
  Target: >85%.
- **Continuity.** % of sessions opening with a context-specific reference. Target: 100%.
- **Capture rate.** Facts captured per hour of conversation. Grows monthly.
- **Update adoption.** Median days from template release to user `/update`. Target: <7.
- **Recall accuracy.** Sampled "do you remember X?" correctness. Target: >90%.
- **Promotion quality.** % of inbox items the Notion owner keeps when consolidating. Target: >70%.
- **Consolidation cadence.** Median days from inbox-promote to owner consolidation. Target: <14.
- **Trust.** % of users who have run `/what-do-you-know` at least once in month 1.

## V1 risks and mitigations

| Risk | Mitigation |
|---|---|
| Notion spam from loose promotion | Conservative default, human consent required for every promote in V1 |
| Stale templates | Contract §3 update nag + `/update` command |
| Drift from protected files edited by user | Protected zone documented; `/update` always overwrites these |
| Weak first-run setup → generic assistant | Setup conversation is a Contract obligation, not a suggestion |
| Notion MCP not configured → broken experience | Contract §7 detects this and walks the user through per-host setup |
| Scope creep beyond adoption | Explicit non-goals: no central platform, no orchestration, no custom UI |

## What is explicitly NOT in V1

- No central backend or hosted memory service
- No agent orchestration platform
- No team-wide admin UI
- No custom web app
- No cross-user sharing beyond Notion
- No one-click per-host installers (zip works everywhere; revisit in v1.x if friction data warrants)
- No multi-device sync (design path for V2)
- No semantic search (grep in V1, opt-in embeddings in V2)

## Roadmap

### v0.1 — N=1 (internal, Tomás)
- Finalize the folder template in the `tomasmb/aa-ai-os-template` repo. Reference implementation
  and iteration happens in the repo; Tomás's personal openclaw workspace is only a dogfooding
  consumer, not the canonical source.
- Write the Contract v1 text.
- Publish the Notion hub.
- Dogfood for 1–2 weeks.

### v0.2 — Friends & family (3–5 employees)
- Update mechanism end-to-end.
- Setup conversation polished.
- Notion hub complete with onboarding modules.

### v1.0 — Company rollout
- Signed template releases on a public URL.
- All teams have team packs.
- Onboarding path: Notion "Get Your Assistant" → download → 5-minute setup → productive.

### v1.x — Growable surface
- Community packs.
- Opt-in local semantic search.
- Team-level shared memory (beyond Notion promotion).

## Design decisions (locked)

| Question | Decision | Rationale |
|---|---|---|
| Where is the folder repo hosted? | **Public GitHub** `tomasmb/aa-ai-os-template` | Template is generic; no secrets. Public removes permission friction for every employee. |
| Is company-specific content in the repo? | **No** — it stays in private Notion and is pulled on first run | Keeps the public repo safe and keeps Notion as the single source of truth for org knowledge. |
| How do non-technical users download? | **Download button on the "Get Your Assistant" Notion page → zip from latest GitHub release** | No git, no CLI. One click. Power users can still clone. |
| Consent per Notion write? | **Auto-promote to "Assistant Updates" inbox section; explicit consent only to create new pages** | Speed without spam. Owners consolidate inbox → canonical on their own cadence. |
| One-click per-host installers (.mcpb, etc.)? | **Not in V1.** Revisit only if adoption data shows friction | Maintaining 5 wrappers is 5× cost for marginal onboarding gain. |
| How do users see versions? | **Dates + plain-English changelog.** Semver only on request | Non-technical users shouldn't be confronted with `v1.4.2`. |
| Claude's built-in memory? | **Off.** The AI OS folder is the single source of truth | Two memories = conflicts and unclear ownership; folder memory is visible, editable, portable. |

## Open questions

- Exact Slack/email digest channel for page-owner notifications on inbox promotes. Pick tool + cadence before v0.2.
- Threshold for "semantic match" dedupe — heuristic rules in V1, embeddings opt-in in V2?
- When (if ever) does a mature assistant earn the right to auto-promote directly into canonical
  sections, skipping the inbox?

## Canonical sources

The AI OS project is self-contained across two places only. Nothing canonical lives on any
individual's machine.

- **Git repo** (maintainer source of truth): [`tomasmb/aa-ai-os-template`](https://github.com/tomasmb/aa-ai-os-template)
  - Template files = shipped product.
  - `docs/SPEC.md` (this file) = the one spec. Edit here first; reflect in Notion after.
  - `docs/maintainer-skill.md` = the maintainer's playbook (what to review weekly, how to release).
- **Notion hub** (user source of truth): `Alpha AI OS — V1` page. Human-facing docs, primers,
  packs, onboarding, governance.

If the spec and the hub disagree, the repo wins — open a PR, update both in lockstep.
