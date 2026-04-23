# Alpha AI OS — your personal assistant folder

> Your AI assistant with soul and memory. Open this folder in any supported AI
> tool and start talking. That's it.

## What this is

A downloadable folder that turns **any AI tool** — Claude Desktop, Cursor,
Claude Code, Codex CLI, or openclaw — into your personal assistant. The folder
is the assistant. The tool is just the window you look through.

## Five-minute setup

### 1. Download
Click the **Download** button on the Alpha AI OS Notion hub (see "Get Your
Assistant" page). You'll get a zip.

### 2. Unzip
Unzip anywhere on your computer. A folder called `alpha-assistant/` (or
`ai-os-template/`) will appear. Move it wherever you like — your home folder
is fine.

### 3. Open in your AI tool
Pick one:
- **Claude Desktop:** drop the folder into a new project / workspace.
- **Cursor:** File → Open Folder → select the folder.
- **Claude Code:** `cd` into the folder in your terminal, then run `claude`.
- **Codex CLI:** `cd` into the folder, then run `codex`.
- **openclaw:** point openclaw's workspace at this folder.

### 4. Say hi
Just say "hi" or ask anything. The assistant will load its Contract, see that
it doesn't know you yet, and walk you through a short conversational setup.

That's it. No files to edit. No commands to run. Keep talking.

## What happens automatically

- **Memory.** Everything you tell it is remembered. Ask anytime: *"what do you
  know about me?"* and you get a plain-English summary.
- **Company brain.** When something you say is useful to the team or company,
  the assistant writes a summary to Notion's "Assistant Updates" inbox on the
  right page. Owners consolidate on their own cadence. You don't do anything.
- **Shared brain, two tiers.** A lean **Core** of people, projects,
  decisions, insights, meetings, and goals loads every session so the
  assistant answers *"who owns X?"* or *"where are we on Q2 goals?"*
  instantly. A heavier **Archive** (students, playbooks, glossary) only
  loads on demand and respects Notion's row-level permissions — your
  assistant silently skips what you don't have access to.
- **Updates.** Once a day the assistant checks for a new version. If one's
  available, it asks you once: *"Want me to upgrade? Takes 30 seconds, your
  stuff is safe."*
- **Privacy.** Your personal memory (`memory/`, `USER.md`, `TONE.md`, etc.)
  never leaves your machine, except for the Notion promotes above.

## Getting Notion connected

The assistant needs access to your organization's Notion workspace. On first
run, if Notion isn't connected, the assistant will walk you through the
10–30-second setup for your specific tool. You don't need to read any docs.

## Folder layout (for the curious — you never need to touch these)

```
alpha-assistant/
  README.md                 ← you are here
  CONTRACT.md               ← the rules the assistant follows (don't edit)
  SOUL.md                   ← who the assistant is
  IDENTITY.md               ← its name and vibe (picked during setup)
  USER.md                   ← who you are (filled during setup)
  TONE.md                   ← how you like to be talked to
  WORKSTYLE.md              ← how you like to work
  CURRENT.md                ← what's on your plate this week
  NOTION-SYNC.md            ← where to read/write in Notion
  PROMOTION-RULES.md        ← what flows from you to Notion
  TOOLS.md                  ← MCPs and per-host setup notes
  AGENTS.md                 ← adapter for openclaw / Codex
  CLAUDE.md                 ← adapter for Claude Desktop / Code
  .cursor/rules/            ← adapter for Cursor
  onboarding/               ← company / role / team primers
  packs/                    ← optional capability packs
  memory/                   ← everything the assistant remembers (private)
  logs/                     ← session logs, queued writes
  .version                  ← current version of this template
```

## What if something goes wrong

- **The assistant acts weird or loses context.** Say *"reload yourself"* — it
  re-reads the Contract and context files.
- **You want to forget something.** Say *"forget X"* — it deletes locally and
  removes matching Notion inbox entries tagged to your assistant.
- **You want a fresh start.** Delete this folder and re-download. Your Notion
  contributions stay (they're tagged with your name).

## Version

See `.version` for the template version. The assistant will tell you in plain
English when a new release is available.
