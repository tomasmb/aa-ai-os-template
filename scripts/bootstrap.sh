#!/usr/bin/env bash
# Alpha AI OS — bootstrap (macOS / Linux)
# Runs after scripts/install.sh has cloned the assistant.
# - Authenticates with GitHub via `gh auth login --web`.
# - Captures GitHub username + email; sets git config if unset.
# - Clones alpha-anywhere-kb as a sibling. On 403/404, writes
#   memory/kb-status.md=pending and lets the assistant run in partial mode.
# - Copies *.template -> live editable files on first run only.
# - Detects installed AI tools (Claude Desktop first) and prints next-step.
# - Idempotent: safe to re-run.

set -euo pipefail

ASSISTANT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(dirname "$ASSISTANT_DIR")"
KB_DIR="$ROOT/alpha-anywhere-kb"
KB_REPO="${ALPHA_KB_REPO:-tomasmb/alpha-anywhere-kb}"
KB_URL="https://github.com/$KB_REPO.git"

mkdir -p "$ASSISTANT_DIR/memory" "$ASSISTANT_DIR/logs"

say() { printf "\n\033[1;36m[alpha]\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m[alpha]\033[0m %s\n" "$*"; }
die() { printf "\n\033[1;31m[alpha]\033[0m %s\n" "$*" >&2; exit 1; }

# 1. GitHub auth ------------------------------------------------------------
ensure_auth() {
    if gh auth status >/dev/null 2>&1; then
        say "GitHub auth: ok ($(gh api user --jq .login))."
        return 0
    fi
    say "Signing you into GitHub. A browser window will open."
    gh auth login --web -h github.com -p https
}

# 2. Git identity -----------------------------------------------------------
ensure_git_identity() {
    local user_name user_email
    user_name="$(gh api user --jq '.name // .login')"
    user_email="$(gh api user/emails --jq 'map(select(.primary==true))[0].email // empty' 2>/dev/null || true)"
    [ -z "$user_email" ] && user_email="$(gh api user --jq '.email // empty')"

    if [ -z "$(git config --global user.name || true)" ]; then
        say "Setting git user.name = $user_name"
        git config --global user.name "$user_name"
    fi
    if [ -z "$(git config --global user.email || true)" ] && [ -n "$user_email" ]; then
        say "Setting git user.email = $user_email"
        git config --global user.email "$user_email"
    fi

    local gh_user; gh_user="$(gh api user --jq .login)"
    printf "%s\n" "$gh_user" > "$ASSISTANT_DIR/memory/gh-username.md"
}

# 3. KB clone ---------------------------------------------------------------
clone_kb() {
    if [ -d "$KB_DIR/.git" ]; then
        say "KB already cloned at $KB_DIR."
        echo "$KB_DIR" > "$ASSISTANT_DIR/memory/kb-location.md"
        rm -f "$ASSISTANT_DIR/memory/kb-status.md"
        return 0
    fi

    say "Cloning the company brain ($KB_REPO)."
    if gh repo clone "$KB_REPO" "$KB_DIR" 2>/tmp/alpha-kb-clone.err; then
        echo "$KB_DIR" > "$ASSISTANT_DIR/memory/kb-location.md"
        rm -f "$ASSISTANT_DIR/memory/kb-status.md"
        say "Brain ready at $KB_DIR."
        return 0
    fi

    local err; err="$(cat /tmp/alpha-kb-clone.err 2>/dev/null || echo)"
    if echo "$err" | grep -qiE "(404|not found|403|forbidden|permission denied)"; then
        local gh_user; gh_user="$(gh api user --jq .login)"
        cat > "$ASSISTANT_DIR/memory/kb-status.md" <<EOF
status: pending
github_username: $gh_user
checked_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
admin_contact: see docs/ADMIN-GUIDE.md
note: |
  GitHub doesn't let me read $KB_REPO yet. Send your GH username ($gh_user) to
  the admin so they can add you to the org. The assistant will keep working in
  personal-only mode until access lands and will recheck on every session boot.
EOF
        warn "Brain access pending. Continuing in personal-only mode."
        return 0
    fi
    warn "KB clone failed: $err"
    warn "You can re-run bootstrap later: bash scripts/bootstrap.sh"
}

# 4. Editable templates -----------------------------------------------------
copy_templates() {
    say "Initializing editable files from templates (first run only)."
    local count=0
    while IFS= read -r tmpl; do
        local live="${tmpl%.template}"
        if [ ! -f "$live" ]; then
            cp "$tmpl" "$live"
            count=$((count + 1))
        fi
    done < <(find "$ASSISTANT_DIR" -type f -name '*.template' \
        -not -path '*/.git/*' -not -path '*/node_modules/*')
    say "Copied $count template(s) to live editable files."
}

# 5. AI tool detection ------------------------------------------------------
detect_ai_tool() {
    say "Detecting which AI tool you have installed."
    local found=""

    # Claude Desktop (recommended)
    if [ -d "/Applications/Claude.app" ] || [ -d "$HOME/Applications/Claude.app" ]; then
        found="claude-desktop"
    elif command -v claude >/dev/null 2>&1; then
        found="claude-code"
    elif [ -d "/Applications/Cursor.app" ] || [ -d "$HOME/Applications/Cursor.app" ] \
            || command -v cursor >/dev/null 2>&1; then
        found="cursor"
    elif command -v codex >/dev/null 2>&1; then
        found="codex"
    elif command -v openclaw >/dev/null 2>&1; then
        found="openclaw"
    fi

    case "$found" in
        claude-desktop)
            say "Found: Claude Desktop (recommended)."
            cat <<EOF

Open Claude Desktop and add a new project pointing at:

  $ASSISTANT_DIR

Then say "hi" — your assistant will load the Contract and walk you through setup.
EOF
            ;;
        claude-code)
            say "Found: Claude Code."
            echo
            echo "  cd \"$ASSISTANT_DIR\" && claude"
            ;;
        cursor)
            say "Found: Cursor."
            cat <<EOF

Open Cursor → File → Open Folder → select:

  $ASSISTANT_DIR

Then say "hi" — your assistant will load the Contract and walk you through setup.
EOF
            ;;
        codex)
            say "Found: Codex CLI."
            echo "  cd \"$ASSISTANT_DIR\" && codex"
            ;;
        openclaw)
            say "Found: openclaw."
            echo "  Open openclaw and point its workspace at $ASSISTANT_DIR"
            ;;
        "")
            warn "No supported AI tool detected. Install one (Claude Desktop recommended):"
            cat <<EOF

  1. Claude Desktop (recommended): https://claude.ai/download
  2. Cursor:                       https://cursor.com
  3. Claude Code (CLI):            npm install -g @anthropic-ai/claude-code
  4. Codex CLI:                    npm install -g @openai/codex
  5. openclaw:                     ask your admin

After installing, open the folder above and say "hi" to your assistant.
EOF
            ;;
    esac
}

# Run ----------------------------------------------------------------------
main() {
    say "Bootstrap starting."
    ensure_auth
    ensure_git_identity
    clone_kb
    copy_templates
    detect_ai_tool
    say "Bootstrap complete."
    if [ -f "$ASSISTANT_DIR/memory/kb-status.md" ]; then
        warn "Brain access is pending. The assistant will run in personal-only mode."
    fi
}

main "$@"
