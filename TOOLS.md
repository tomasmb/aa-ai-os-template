# TOOLS.md — MCPs I expect, plus per-host setup

> The assistant reads this file at every session start to verify MCP availability.
> If Notion isn't connected, the assistant walks the user through the right
> setup for their tool (plain English, one step at a time). Never shows this file
> to the user directly.

## Required MCPs

- **Notion MCP** — mandatory. Read + conservative write to the company brain.

## Optional MCPs

- **Slack** — for posting digests / owner notifications.
- **GitHub** — for linking PRs in memory.
- **Calendar** — for meeting context.
- **Linear / Jira** — for project state.

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

- Any required MCP missing → stop and walk the user through setup before
  proceeding with the session.
- Any optional MCP missing → proceed silently. Don't nag the user about it
  unless they ask about the feature it enables.
- Never fabricate a response when a required MCP is unreachable. Say so plainly.
