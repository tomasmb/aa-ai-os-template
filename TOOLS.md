# TOOLS.md — MCPs I expect, plus per-host setup

> The assistant reads this file at every session start to verify MCP availability.
> If a required MCP isn't connected, the assistant walks the user through the
> right setup for their tool (plain English, one step at a time). Never shows
> this file to the user directly.

## Required MCPs

- **Notion MCP** — mandatory. Read + conservative write to the company brain.

## Recommended MCPs (unlock specific packs)

- **Google Calendar MCP** — unlocks `packs/company-scheduling.md`. Strongly
  recommended for new hires (day-1 scheduling is the highest-leverage use case).
- **Google Mail MCP** (optional) — enables richer invite bodies + follow-up
  detection. Not required; the scheduling pack works with Calendar-only.
- **Slack MCP** — for posting owner digests and team notifications.
- **GitHub MCP** — for linking PRs into memory (useful for engineers).
- **Linear / Jira MCP** — for project state (useful for PMs).

## Notion MCP setup by host

### Claude Desktop

1. Open Claude Desktop → Settings → Connectors (or Extensions).
2. Search for "Notion" and click Install.
3. In the browser window that opens, click "Connect to Notion" and approve.
4. Restart Claude Desktop once.

**Assistant verifies connection by calling `notion-search` with a trivial query.**

### Cursor

1. Open Cursor → Settings → Features → Model Context Protocol.
2. Click "Add MCP Server".
3. Preferred: hosted — name `notion`, URL `https://mcp.notion.com`, type `streamable-http`.
4. Approve the OAuth prompt.
5. Reload the Cursor window.

### Claude Code (CLI)

1. Edit `~/.claude/mcp.json` (create if missing).
2. Add an entry for Notion pointing at `https://mcp.notion.com` with OAuth.
3. Restart the Claude Code session.

### Codex CLI

1. Edit `~/.codex/config.toml`.
2. Add a `[mcp_servers.notion]` block pointing at the hosted Notion MCP.
3. Restart Codex.

### openclaw

- Already configured via the `plugin-notion-workspace-notion` plugin. No action
  needed — the assistant verifies tool availability and proceeds.

## Google Calendar MCP setup by host

> The assistant activates this walkthrough the first time the user says anything
> that triggers `packs/company-scheduling.md` (e.g. *"schedule a 1-1 with X"*) —
> or when a new-hire checklist item requires scheduling. Never nag otherwise.

### Claude Desktop

1. Open Claude Desktop → Settings → Connectors.
2. Search for "Google Calendar" and click Install. (Google Workspace connector
   also enables it; either works.)
3. Approve OAuth in the browser — sign in with your `@2hourlearning.com`
   account.
4. Grant **read free/busy** + **create events** scopes. Other scopes are not
   needed.
5. Restart Claude Desktop once.

**Assistant verifies connection by querying free/busy on the user's own
calendar for the next hour.**

### Cursor

1. Settings → Features → Model Context Protocol → Add MCP Server.
2. Use a community Google Calendar MCP (e.g. `@modelcontextprotocol/gcal` or
   a Workspace-connected variant). Paste the config snippet from the MCP's
   README.
3. Approve OAuth.
4. Reload Cursor.

### Claude Code (CLI)

1. Edit `~/.claude/mcp.json`.
2. Add a Google Calendar entry (OAuth-based; follow the MCP's README).
3. Run `claude mcp login google-calendar` and complete OAuth.
4. Restart the session.

### Codex CLI

1. Edit `~/.codex/config.toml`.
2. Add `[mcp_servers.google_calendar]` per the MCP's setup docs.
3. Run the auth flow, restart Codex.

### openclaw

1. The calendar MCP is expected to be installed via the workspace's plugin
   manager.
2. Confirm availability and proceed.

### Required OAuth scopes

Only these — nothing else is needed:

- `https://www.googleapis.com/auth/calendar.freebusy` — read free/busy.
- `https://www.googleapis.com/auth/calendar.events` — create / update events
  the assistant authors.

**Not requested:** reading event contents (titles, descriptions, attendees of
other people's events). Free/busy is enough.

## Host memory — turn it OFF

The assistant runs on this folder's memory. A second memory system (Claude's
built-in, Cursor's memory, etc.) creates conflicts. At first run, the assistant
detects and walks the user through disabling:

### Claude Desktop
Settings → Memory → toggle **off**. Takes 10 seconds.

### Claude Code / Claude.ai
Same Memory toggle in the account settings page.

### Cursor
Settings → Features → Memory → toggle **off**.

### Codex CLI / openclaw
No built-in memory. Nothing to disable.

## Failure policy

- **Required MCP missing** (Notion) → stop and walk the user through setup
  before proceeding with the session.
- **Recommended MCP missing** (Google Calendar) → proceed silently. Only
  mention it when the user triggers a pack that needs it, then offer to set
  it up. Never nag.
- **Any optional MCP missing** → proceed silently.
- Never fabricate a response when a required MCP is unreachable. Say so plainly.
