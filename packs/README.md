# packs/ — Optional capability packs

> Packs add focused skills to the assistant. Drop one in, the next session
> recognizes it automatically. Remove it, the assistant forgets that skill.

## How packs work

- Each pack is a single markdown file.
- The assistant reads every `*.md` file in this directory at session start.
- Each pack declares: what it does, when to use it, and any specific prompts /
  checklists the assistant should follow.

## Pack types

| Type | Owner | Filename pattern |
|---|---|---|
| **Company-wide** | Alpha central | `company-*.md` — overwritten on `/update` |
| **Team** | team lead | `team-<team-name>.md` — protected within team |
| **Personal** | the user | `personal-*.md` — never touched by `/update` |

## Getting packs

The assistant knows about the current Notion "Packs Library" page. On request
("show me available packs", "add a writing pack"), it pulls the pack's content
from Notion and writes it here.

## Recommended first packs

- `company-brain.md` — **the shared knowledge graph** (Contract §14). Share-
  by-default writes to Notion's People / Projects / Decisions / Insights
  databases. Every other pack that surfaces facts routes through here.
  **Ships by default. Foundational.**
- `company-writing.md` — Alpha's writing voice + structure. **Ships by default.**
- `company-meetings.md` — meeting prep + post-meeting ingest (read.ai-ready).
  Writes Decisions + Insights to the brain. **Ships by default.**
- `company-scheduling.md` — 1-1 and meeting scheduling via Google Calendar +
  Notion Team directory. Updates People rows on scheduled 1-1s. **Ships by
  default.** Unlocks once the user connects Google Calendar MCP.
- `team-<your-team>.md` — team-specific rituals and workflows. Pull from
  the Packs Library when available.
- `personal-custom.md` — anything you want the assistant to always do your way.

## Which packs need extra MCPs

| Pack | Extra MCP needed | Behavior if MCP missing |
|---|---|---|
| `company-brain.md` | Notion MCP (required) + access to `🧠 AI Memory` page | Stop + walk user through granting Notion access to the AI Memory hub. |
| `company-writing.md` | None | Works out of the box. |
| `company-meetings.md` | None (paste-based today); optional read.ai / Gmail later | Works on pasted meeting notes. Writes to brain if brain access is healthy. |
| `company-scheduling.md` | **Google Calendar MCP** | Assistant offers to set it up the first time the user triggers the pack. |

## Removing a pack

Say "drop the <pack> pack" and the assistant moves the file to
`.backups/packs-removed/<date>/` so it can be restored later.
