#!/usr/bin/env bash
# Alpha AI OS — promote (Contract Rules 9, 14, 16)
# Atomic write to the KB: pull-rebase -> write -> add -> commit -> push.
#
# Subcommands:
#   inbox <entity-type> <slug> [--target-path PATH] [--source SRC] [--confidence C]
#       Reads body from stdin; writes inbox/<ts>_<entity-type>_<slug>.md.
#   entity <relative-path>
#       Reads file body from stdin; writes <relative-path> in the KB
#       (entity edit, Rule 14). Pass --type promote|consolidate|seed|fix|chore|docs.
#   forget <relative-path>
#       Deletes <relative-path> in the KB; commit type forget(<scope>).
#
# Common flags:
#   --message "subject line"   Required for entity/forget; auto for inbox.
#   --user <slug>              Defaults to memory/gh-username.md content.
#   --no-push                  Stop after commit (rare; for testing).
#   --dry-run                  Show what would happen, don't touch the repo.
#
# Conflicts: aborts the rebase and exits non-zero with details. The assistant
# surfaces the conflict to the user per CONFLICT-PLAYBOOK.md.

set -uo pipefail

ASSISTANT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KB_LOC_FILE="$ASSISTANT_DIR/memory/kb-location.md"
KB_STATUS_FILE="$ASSISTANT_DIR/memory/kb-status.md"
PENDING_FILE="$ASSISTANT_DIR/logs/pending-writes.md"
GH_USER_FILE="$ASSISTANT_DIR/memory/gh-username.md"

err() { printf "[promote] %s\n" "$*" >&2; }
die() { err "$*"; exit 1; }

# Pending KB → queue immediately, never attempt the push
if [ -f "$KB_STATUS_FILE" ] && grep -q '^status: pending' "$KB_STATUS_FILE"; then
    err "KB pending — queueing write to logs/pending-writes.md"
    mkdir -p "$ASSISTANT_DIR/logs"
    {
        echo "---"
        echo "queued_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo "argv: $*"
        echo "stdin:"
        cat
        echo "---"
    } >> "$PENDING_FILE"
    exit 0
fi

[ -f "$KB_LOC_FILE" ] || die "KB not configured; run scripts/bootstrap.sh"
KB_DIR="$(head -n 1 "$KB_LOC_FILE" | tr -d '\r\n')"
[ -d "$KB_DIR/.git" ] || die "KB '$KB_DIR' is not a git repo"

USER_SLUG="$(cat "$GH_USER_FILE" 2>/dev/null | tr -d '\r\n' || echo "unknown")"
SUBCMD=""; ENTITY=""; SLUG=""; REL_PATH=""
TARGET_PATH=""; SOURCE="conversation"; CONFIDENCE="medium"
MESSAGE=""; TYPE="promote"; PUSH=1; DRY=0

[ $# -ge 1 ] || die "usage: promote <inbox|entity|forget> ..."
SUBCMD="$1"; shift

while [ $# -gt 0 ]; do
    case "$1" in
        --target-path) TARGET_PATH="$2"; shift 2 ;;
        --source)      SOURCE="$2"; shift 2 ;;
        --confidence)  CONFIDENCE="$2"; shift 2 ;;
        --message)     MESSAGE="$2"; shift 2 ;;
        --user)        USER_SLUG="$2"; shift 2 ;;
        --type)        TYPE="$2"; shift 2 ;;
        --no-push)     PUSH=0; shift ;;
        --dry-run)     DRY=1; shift ;;
        --) shift; break ;;
        -*) die "unknown flag: $1" ;;
        *)
            if [ "$SUBCMD" = "inbox" ] && [ -z "$ENTITY" ]; then
                ENTITY="$1"
            elif [ "$SUBCMD" = "inbox" ] && [ -z "$SLUG" ]; then
                SLUG="$1"
            elif [ "$SUBCMD" != "inbox" ] && [ -z "$REL_PATH" ]; then
                REL_PATH="$1"
            else
                die "unexpected positional: $1"
            fi
            shift ;;
    esac
done

run() { if [ $DRY -eq 1 ]; then echo "+ $*"; else "$@"; fi; }

pull_rebase() {
    if ! git -C "$KB_DIR" pull --rebase --autostash 2>/tmp/alpha-promote.err; then
        git -C "$KB_DIR" rebase --abort >/dev/null 2>&1 || true
        err "pull --rebase failed. See CONFLICT-PLAYBOOK.md."
        cat /tmp/alpha-promote.err >&2
        return 1
    fi
}

push_or_queue() {
    if [ $PUSH -eq 0 ]; then return 0; fi
    if ! git -C "$KB_DIR" push 2>/tmp/alpha-promote-push.err; then
        err "push failed; queueing to logs/pending-writes.md"
        mkdir -p "$ASSISTANT_DIR/logs"
        {
            echo "---"
            echo "queued_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
            echo "reason: push_failed"
            echo "kb_head: $(git -C "$KB_DIR" rev-parse HEAD)"
            echo "stderr: $(tr '\n' ' ' </tmp/alpha-promote-push.err)"
            echo "---"
        } >> "$PENDING_FILE"
        return 2
    fi
}

write_inbox() {
    [ -n "$ENTITY" ] || die "inbox: missing <entity-type>"
    [ -n "$SLUG" ]   || die "inbox: missing <slug>"
    case "$ENTITY" in people|projects|meetings|goals|decisions|insights) ;;
        *) die "inbox: invalid entity-type '$ENTITY'";;
    esac
    [ -n "$MESSAGE" ] || MESSAGE="surface ${ENTITY%s} update from ${SOURCE}"

    local ts iso path body
    ts="$(date -u +"%Y-%m-%dT%H-%M-%S")"
    iso="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    path="inbox/${ts}_${ENTITY}_${SLUG}.md"
    body="$(cat)"
    [ -n "$body" ] || die "inbox: empty body on stdin"

    pull_rebase || return 1
    {
        echo "---"
        echo "promoted_by: $USER_SLUG"
        echo "promoted_at: $iso"
        echo "target_entity: $ENTITY"
        [ -n "$TARGET_PATH" ] && echo "target_path: $TARGET_PATH"
        echo "source: $SOURCE"
        echo "confidence: $CONFIDENCE"
        echo "---"
        echo
        printf "%s\n" "$body"
    } > "$KB_DIR/$path"

    run git -C "$KB_DIR" add "$path"
    local commit_msg
    commit_msg="promote($ENTITY): $MESSAGE

Promoted-By: $USER_SLUG
Source: $SOURCE
Confidence: $CONFIDENCE"
    run git -C "$KB_DIR" commit -m "$commit_msg"
    push_or_queue || return $?
    echo "$path"
}

write_entity() {
    [ -n "$REL_PATH" ] || die "entity: missing <relative-path>"
    [ -n "$MESSAGE" ]  || die "entity: --message required"
    local body; body="$(cat)"
    [ -n "$body" ] || die "entity: empty body on stdin"

    local scope abs_path
    scope="$(printf "%s" "$REL_PATH" | awk -F/ '{print $1}')"
    case "$scope" in core|archive|inbox|operating-framework) ;;
        *) die "entity: top-level dir '$scope' not allowed";;
    esac
    abs_path="$KB_DIR/$REL_PATH"

    pull_rebase || return 1
    mkdir -p "$(dirname "$abs_path")"
    printf "%s" "$body" > "$abs_path"
    run git -C "$KB_DIR" add "$REL_PATH"

    local entity_scope
    entity_scope="$(printf "%s" "$REL_PATH" | awk -F/ '{print $2}')"
    [ -z "$entity_scope" ] && entity_scope="$scope"

    local commit_msg
    commit_msg="$TYPE($entity_scope): $MESSAGE

Promoted-By: $USER_SLUG
Source: $SOURCE
Confidence: $CONFIDENCE"
    run git -C "$KB_DIR" commit -m "$commit_msg"
    push_or_queue || return $?
    echo "$REL_PATH"
}

write_forget() {
    [ -n "$REL_PATH" ] || die "forget: missing <relative-path>"
    [ -n "$MESSAGE" ]  || MESSAGE="remove entry per user request"

    pull_rebase || return 1
    [ -f "$KB_DIR/$REL_PATH" ] || die "forget: '$REL_PATH' not found in KB"
    run git -C "$KB_DIR" rm "$REL_PATH"

    local entity_scope
    entity_scope="$(printf "%s" "$REL_PATH" | awk -F/ '{print $2}')"
    [ -z "$entity_scope" ] && entity_scope="inbox"

    local commit_msg
    commit_msg="forget($entity_scope): $MESSAGE

Promoted-By: $USER_SLUG
Source: manual
Confidence: high"
    run git -C "$KB_DIR" commit -m "$commit_msg"
    push_or_queue || return $?
    echo "$REL_PATH"
}

case "$SUBCMD" in
    inbox)  write_inbox ;;
    entity) write_entity ;;
    forget) write_forget ;;
    *) die "unknown subcommand: $SUBCMD" ;;
esac
