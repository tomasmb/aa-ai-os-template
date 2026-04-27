#!/usr/bin/env bash
# Alpha AI OS — sync-kb (Contract Rules 16 + 2)
# Runs `git pull --rebase` on the KB and emits a "since last session" briefing.
# Prints nothing if no new commits. On conflict, surfaces per CONFLICT-PLAYBOOK.

set -uo pipefail

ASSISTANT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KB_LOC_FILE="$ASSISTANT_DIR/memory/kb-location.md"
KB_STATUS_FILE="$ASSISTANT_DIR/memory/kb-status.md"
LAST_SESSION_FILE="$ASSISTANT_DIR/memory/last-session.md"
LOG_FILE="$ASSISTANT_DIR/logs/session-log.md"

# Pending mode → no-op
if [ -f "$KB_STATUS_FILE" ] && grep -q '^status: pending' "$KB_STATUS_FILE"; then
    echo "[sync-kb] KB pending; skipping."
    exit 0
fi

[ -f "$KB_LOC_FILE" ] || { echo "[sync-kb] KB not configured. Run scripts/bootstrap.sh." >&2; exit 1; }
KB_DIR="$(head -n 1 "$KB_LOC_FILE" | tr -d '\r\n')"
[ -d "$KB_DIR/.git" ] || { echo "[sync-kb] KB at '$KB_DIR' is not a repo. Run scripts/bootstrap.sh." >&2; exit 1; }

# Capture old HEAD
OLD_HEAD="$(git -C "$KB_DIR" rev-parse HEAD 2>/dev/null || true)"

# Pull-rebase
if ! git -C "$KB_DIR" pull --rebase --autostash 2>/tmp/alpha-sync.err; then
    echo "[sync-kb] pull failed. See CONFLICT-PLAYBOOK.md."
    cat /tmp/alpha-sync.err >&2
    git -C "$KB_DIR" rebase --abort >/dev/null 2>&1 || true
    exit 2
fi

NEW_HEAD="$(git -C "$KB_DIR" rev-parse HEAD)"
mkdir -p "$ASSISTANT_DIR/memory" "$ASSISTANT_DIR/logs"

if [ "$OLD_HEAD" = "$NEW_HEAD" ]; then
    : # no new commits
else
    NCOMMITS="$(git -C "$KB_DIR" rev-list --count "$OLD_HEAD..$NEW_HEAD" 2>/dev/null || echo 0)"
    echo "[sync-kb] $NCOMMITS new commit(s) since last sync."
    echo
    echo "## Recent KB changes"
    git -C "$KB_DIR" log --oneline --no-decorate "$OLD_HEAD..$NEW_HEAD" -- core/ archive/ inbox/ \
        | head -n 20
    echo
    {
        echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") sync-kb pulled $NCOMMITS commits ($OLD_HEAD..$NEW_HEAD)"
    } >> "$LOG_FILE"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$LAST_SESSION_FILE"
exit 0
