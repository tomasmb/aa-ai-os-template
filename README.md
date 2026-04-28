# Alpha AI OS — your personal assistant folder

> Your AI assistant with soul and memory, backed by a shared company brain in
> git. One paste in your terminal, then open the folder in Claude Desktop. Done.

## What this is

A git-based system that turns **any AI tool** — Claude Desktop (recommended),
Cursor, Claude Code, Codex CLI, or openclaw — into your personal assistant.
Two pieces:

1. **`alpha-assistant/`** — this folder. Your behavior, identity, local memory.
2. **`alpha-anywhere-kb/`** — the company brain (private git repo). People,
   projects, decisions, insights, meetings, goals, plus archived bodies.

Both live side-by-side in `~/Alpha AI OS/`. The assistant pulls updates from
both repos automatically every morning.

## One-line setup

You'll need a GitHub account. The setup script asks you to sign in once.

### macOS / Linux

Open Terminal and paste:

```bash
curl -fsSL https://raw.githubusercontent.com/tomasmb/aa-ai-os-template/main/scripts/install.sh | bash
```

### Windows

Open PowerShell and paste:

```powershell
iwr https://raw.githubusercontent.com/tomasmb/aa-ai-os-template/main/scripts/install.ps1 -useb | iex
```

The script will:

1. Install `git` and `gh` (the GitHub CLI) if you don't have them.
2. Create `~/Alpha AI OS/`.
3. Clone the assistant folder there.
4. Run the bootstrap: signs you into GitHub, clones the company brain (or
   tells the admin to add you if you're not in the org yet), detects your
   AI tool, and tells you exactly what to open next.

If your AI tool isn't installed, the bootstrap shows you the download link.

## Open it in your AI tool

After the installer finishes, open the folder in your AI tool. Recommended:

- **Claude Desktop** — drop `~/Alpha AI OS/alpha-assistant` into a new project.
- **Cursor** — File → Open Folder → select `~/Alpha AI OS/alpha-assistant`.
- **Claude Code:** `cd ~/Alpha\ AI\ OS/alpha-assistant && claude`.
- **Codex CLI:** `cd ~/Alpha\ AI\ OS/alpha-assistant && codex`.
- **openclaw:** point its workspace at `~/Alpha AI OS/alpha-assistant`.

Then say "hi" or ask anything. The assistant will load its Contract, see
that it doesn't know you yet, and walk you through a short conversational
setup. You'll never edit a file by hand.

## What happens automatically

- **Memory.** Everything you tell it is remembered. Ask anytime: *"what do
  you know about me?"* and you get a plain-English summary.
- **Company brain.** When something you say is useful to the team, the
  assistant writes a short summary as a file in the KB git repo and pushes
  it. Owners consolidate on their own cadence. You don't do anything.
- **Two-tier brain.** A lean **Core** (people, projects, decisions, insights,
  meetings, goals) loads every session so the assistant answers *"who owns
  X?"* or *"where are we on Q2 goals?"* instantly. A heavier **Archive**
  (full meeting notes, playbooks, glossary, students) only loads on demand.
- **Updates.** Once a day the morning ritual runs `git pull` on both repos —
  Contract / packs / scripts / brain stay current automatically.
- **Privacy.** Your personal memory (`memory/`, `USER.md`, `TONE.md`, etc.)
  never leaves your machine, except for explicit promotions to the brain.

## What if I'm not in the GitHub org yet?

The bootstrap captures your GitHub username and tells you to ping the admin.
Until you're added, the assistant runs in **personal-only mode** — identity,
tone, workstyle all work fine. The moment access lands, the assistant clones
the brain on the next session and you're fully connected.

## Folder layout (you never need to touch these)

```text
~/Alpha AI OS/
├── alpha-assistant/         ← this folder
│   ├── CONTRACT.md          ← the rules the assistant follows
│   ├── SOUL.md              ← who the assistant is
│   ├── KB-SYNC.md           ← brain layout + git sync rules
│   ├── GIT-DISCIPLINE.md    ← git playbook
│   ├── COMMIT-CONVENTIONS.md
│   ├── CONFLICT-PLAYBOOK.md
│   ├── PROMOTION-RULES.md
│   ├── TOOLS.md             ← git, gh, optional MCPs
│   ├── *.template files     ← USER, IDENTITY, TONE, WORKSTYLE, CURRENT
│   ├── scripts/             ← install / bootstrap / sync-kb / promote / preflight
│   ├── setup/               ← per-OS setup notes
│   ├── docs/                ← admin guide, migration runbooks
│   ├── onboarding/          ← company / role / team primers
│   ├── packs/               ← optional capability packs
│   ├── rituals/             ← morning / EOD / weekly templates
│   ├── digests/             ← weekly email digest template
│   ├── memory/              ← everything the assistant remembers (private, gitignored)
│   ├── logs/                ← session logs, pending writes (gitignored)
│   └── .version
└── alpha-anywhere-kb/       ← the brain (private git repo)
    ├── core/                ← lean entity rows
    ├── archive/             ← bodies + raw material
    ├── inbox/               ← assistant-promoted notes (append-only)
    └── operating-framework/ ← Alpha doctrine
```

## What if something goes wrong

- **The assistant acts weird or loses context.** Say *"reload yourself"* — it
  re-reads the Contract and context files.
- **You want to forget something.** Say *"forget X"* — it deletes locally and
  removes matching inbox entries tagged to your assistant.
- **You want a fresh start.** Delete `~/Alpha AI OS/alpha-assistant` and
  re-run the installer. Your brain contributions stay (they're tagged with
  your name). Your local memory is gone.
- **GitHub is unreachable.** The assistant works from local memory and queues
  writes to `logs/pending-writes.md`. Replays automatically when GitHub is back.

## Version

See `.version` for the template version. The assistant will tell you in plain
English when a new release is shipped (after a daily morning pull).

## For admins

See `docs/ADMIN-GUIDE.md` for org setup, team automation, KB seeding, and
hard-forget procedures.
