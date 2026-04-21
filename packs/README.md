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

- `company-writing.md` — writing norms (voice, brevity, structure).
- `company-meetings.md` — meeting prep + follow-up templates.
- `team-<your-team>.md` — team-specific rituals and workflows.
- `personal-custom.md` — anything you want the assistant to always do your way.

## Removing a pack

Say "drop the <pack> pack" and the assistant moves the file to
`.backups/packs-removed/<date>/` so it can be restored later.
