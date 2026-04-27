#!/usr/bin/env bash
# Alpha AI OS — sync-assistant
# `git pull --rebase --autostash` on the assistant repo itself, so
# users get the latest Contract / packs / scripts every morning.
# Idempotent. Silent when nothing changed. Mirrors sync-kb.sh shape.

set -uo pipefail

ASSISTANT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$ASSISTANT_DIR/logs/session-log.md"

[ -d "$ASSISTANT_DIR/.git" ] || {
    echo "[sync-assistant] $ASSISTANT_DIR is not a git repo; skipping." >&2
    exit 0
}

OLD_HEAD="$(git -C "$ASSISTANT_DIR" rev-parse HEAD 2>/dev/null || true)"

if ! git -C "$ASSISTANT_DIR" pull --rebase --autostash 2>/tmp/alpha-sync-assistant.err; then
    echo "[sync-assistant] pull failed. See CONFLICT-PLAYBOOK.md." >&2
    cat /tmp/alpha-sync-assistant.err >&2
    git -C "$ASSISTANT_DIR" rebase --abort >/dev/null 2>&1 || true
    exit 2
fi

NEW_HEAD="$(git -C "$ASSISTANT_DIR" rev-parse HEAD)"
mkdir -p "$ASSISTANT_DIR/logs"

if [ "$OLD_HEAD" != "$NEW_HEAD" ]; then
    NCOMMITS="$(git -C "$ASSISTANT_DIR" rev-list --count "$OLD_HEAD..$NEW_HEAD" 2>/dev/null || echo 0)"
    echo "[sync-assistant] $NCOMMITS new commit(s) on the assistant repo."
    git -C "$ASSISTANT_DIR" log --oneline --no-decorate "$OLD_HEAD..$NEW_HEAD" | head -n 10
    {
        echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") sync-assistant pulled $NCOMMITS commits ($OLD_HEAD..$NEW_HEAD)"
    } >> "$LOG_FILE"
fi

exit 0
