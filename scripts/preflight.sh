#!/usr/bin/env bash
# Alpha AI OS — preflight (Contract Rule 17)
# Verifies KB clone health on every boot. Exits 0 on green, non-zero on red.
# Output is machine-readable on stderr; human summary on stdout.

set -uo pipefail

ASSISTANT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KB_LOC_FILE="$ASSISTANT_DIR/memory/kb-location.md"
KB_STATUS_FILE="$ASSISTANT_DIR/memory/kb-status.md"
KB_EXPECTED_REPO="${ALPHA_KB_REPO:-tomasmb/alpha-anywhere-kb}"

red()   { printf "\033[1;31m%s\033[0m\n" "$*"; }
yel()   { printf "\033[1;33m%s\033[0m\n" "$*"; }
grn()   { printf "\033[1;32m%s\033[0m\n" "$*"; }

fail() {
    red "preflight: FAIL — $*"
    echo "preflight_status=fail" >&2
    echo "preflight_reason=$*" >&2
    exit 1
}

# Pending mode is OK ---------------------------------------------------------
if [ -f "$KB_STATUS_FILE" ] && grep -q '^status: pending' "$KB_STATUS_FILE"; then
    yel "preflight: KB access pending — running partial mode."
    echo "preflight_status=pending" >&2
    exit 0
fi

# 1. kb-location.md exists --------------------------------------------------
[ -f "$KB_LOC_FILE" ] || fail "memory/kb-location.md missing — run scripts/bootstrap.sh"

KB_DIR="$(head -n 1 "$KB_LOC_FILE" | tr -d '\r\n')"
[ -d "$KB_DIR" ] || fail "KB path '$KB_DIR' does not exist — run scripts/bootstrap.sh"

# 2. Is git repo ------------------------------------------------------------
[ -d "$KB_DIR/.git" ] || fail "KB path '$KB_DIR' is not a git repo — run scripts/bootstrap.sh"

# 3. Clean working tree -----------------------------------------------------
if ! git -C "$KB_DIR" diff --quiet || ! git -C "$KB_DIR" diff --cached --quiet; then
    fail "KB working tree is dirty — see CONFLICT-PLAYBOOK.md Scenario 8"
fi

# 4. On main ----------------------------------------------------------------
BRANCH="$(git -C "$KB_DIR" rev-parse --abbrev-ref HEAD)"
[ "$BRANCH" = "main" ] || fail "KB on branch '$BRANCH', expected main — see CONFLICT-PLAYBOOK.md Scenario 9"

# 5. Origin matches ---------------------------------------------------------
ORIGIN="$(git -C "$KB_DIR" config --get remote.origin.url || true)"
case "$ORIGIN" in
    *"$KB_EXPECTED_REPO"*) ;;
    *) fail "KB origin '$ORIGIN' does not match expected '$KB_EXPECTED_REPO'" ;;
esac

# 6. Identity set -----------------------------------------------------------
[ -n "$(git config --global user.name || true)" ]  || fail "git config user.name not set — run scripts/bootstrap.sh"
[ -n "$(git config --global user.email || true)" ] || fail "git config user.email not set — run scripts/bootstrap.sh"

grn "preflight: OK ($KB_DIR on main, identity set)."
echo "preflight_status=ok" >&2
echo "kb_dir=$KB_DIR" >&2
exit 0
