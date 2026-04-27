#!/usr/bin/env bash
# Alpha AI OS — one-line installer (macOS / Linux)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/alphaanywhere/aa-ai-os-template/main/scripts/install.sh | bash
#
# Idempotent: safe to re-run. Hands off to scripts/bootstrap.sh once cloned.

set -euo pipefail

REPO_URL="${ALPHA_REPO_URL:-https://github.com/alphaanywhere/aa-ai-os-template.git}"
ROOT="${ALPHA_ROOT:-$HOME/Alpha AI OS}"
ASSISTANT_DIR="$ROOT/alpha-assistant"

say() { printf "\n\033[1;36m[alpha]\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m[alpha]\033[0m %s\n" "$*"; }
die() { printf "\n\033[1;31m[alpha]\033[0m %s\n" "$*" >&2; exit 1; }

confirm() {
    local prompt="$1"
    if [ -t 0 ]; then
        read -r -p "$prompt [Y/n] " ans
        case "${ans:-Y}" in [Yy]*) return 0 ;; *) return 1 ;; esac
    fi
    return 0
}

detect_pm() {
    if command -v brew >/dev/null 2>&1; then echo "brew"; return; fi
    if command -v apt-get >/dev/null 2>&1; then echo "apt"; return; fi
    if command -v dnf >/dev/null 2>&1; then echo "dnf"; return; fi
    if command -v pacman >/dev/null 2>&1; then echo "pacman"; return; fi
    echo "unknown"
}

install_with() {
    local pm="$1"; shift
    case "$pm" in
        brew)   brew install "$@" ;;
        apt)    sudo apt-get update -y && sudo apt-get install -y "$@" ;;
        dnf)    sudo dnf install -y "$@" ;;
        pacman) sudo pacman -S --noconfirm "$@" ;;
        *)      die "No supported package manager found. Install git + gh manually, then re-run." ;;
    esac
}

ensure_tool() {
    local tool="$1" pkg="$2" pm="$3"
    if command -v "$tool" >/dev/null 2>&1; then return 0; fi
    say "Missing: $tool. Will install via $pm."
    confirm "Install $tool now?" || die "Cannot proceed without $tool."
    install_with "$pm" "$pkg"
}

main() {
    say "Welcome to Alpha AI OS. This installer will:"
    say "  1. Install git + gh CLI if missing."
    say "  2. Create $ROOT/."
    say "  3. Clone the assistant folder."
    say "  4. Hand off to bootstrap (auth + brain clone + AI tool detection)."
    confirm "Continue?" || die "Aborted."

    PM="$(detect_pm)"
    [ "$PM" = "unknown" ] && die "No supported package manager. See setup/linux.md for manual steps."
    say "Package manager: $PM."

    ensure_tool git git "$PM"
    if [ "$PM" = "apt" ] && ! command -v gh >/dev/null 2>&1; then
        say "Adding GitHub CLI apt repository (one-time)."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo apt-get update -y
    fi
    ensure_tool gh gh "$PM"

    mkdir -p "$ROOT"
    if [ -d "$ASSISTANT_DIR/.git" ]; then
        say "Assistant folder already exists at $ASSISTANT_DIR — pulling latest."
        git -C "$ASSISTANT_DIR" pull --rebase --autostash || warn "Pull had issues; continue manually if needed."
    else
        say "Cloning assistant into $ASSISTANT_DIR."
        git clone "$REPO_URL" "$ASSISTANT_DIR"
    fi

    say "Handing off to bootstrap."
    bash "$ASSISTANT_DIR/scripts/bootstrap.sh"
}

main "$@"
