#!/usr/bin/env bash
set -euo pipefail

REPO=""
BRANCH="main"
CHECKS="test,aar"
STRICT=false
ENFORCE_ADMINS=true
LINEAR_HISTORY=true
CONVERSATION_RESOLUTION=true
NO_FORCE_PUSHES=true
NO_DELETIONS=true
NO_BLOCK_CREATIONS=true
NO_SIGNATURES=true
NO_LOCK_BRANCH=true
NO_FORK_SYNCING=true

usage() {
    cat <<EOF
Usage: $0 --repo OWNER/REPO [options]

Apply forge-gatekeeper-style branch protection to any repo.

Required:
  --repo OWNER/REPO        Repository in owner/repo format

Options:
  --branch BRANCH          Branch to protect (default: main)
  --checks CHECKS          Comma-separated status check contexts (default: test,aar)
  --strict true|false      Require status checks to pass before merging (default: false)
  --enforce-admins         Enforce protection for administrators (default: true)
  --linear-history         Require linear commit history (default: true)
  --conversation-resolution Require conversation resolution before merging (default: true)
  --no-force-pushes        Prevent force pushes (default: true)
  --no-deletions           Prevent branch deletions (default: true)
  --no-block-creations     Allow branch creation (default: true)
  --no-signatures          Do not require signed commits (default: true)
  --no-lock-branch         Do not lock the branch (default: true)
  --no-fork-syncing        Prevent fork syncing (default: true)
  --help                   Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            REPO="${2:-}"
            shift 2
            ;;
        --branch)
            BRANCH="${2:-}"
            shift 2
            ;;
        --checks)
            CHECKS="${2:-}"
            shift 2
            ;;
        --strict)
            STRICT="${2:-}"
            shift 2
            ;;
        --enforce-admins)
            ENFORCE_ADMINS=true
            shift
            ;;
        --no-enforce-admins)
            ENFORCE_ADMINS=false
            shift
            ;;
        --linear-history)
            LINEAR_HISTORY=true
            shift
            ;;
        --no-linear-history)
            LINEAR_HISTORY=false
            shift
            ;;
        --conversation-resolution)
            CONVERSATION_RESOLUTION=true
            shift
            ;;
        --no-conversation-resolution)
            CONVERSATION_RESOLUTION=false
            shift
            ;;
        --no-force-pushes)
            NO_FORCE_PUSHES=true
            shift
            ;;
        --force-pushes)
            NO_FORCE_PUSHES=false
            shift
            ;;
        --no-deletions)
            NO_DELETIONS=true
            shift
            ;;
        --deletions)
            NO_DELETIONS=false
            shift
            ;;
        --no-block-creations)
            NO_BLOCK_CREATIONS=true
            shift
            ;;
        --block-creations)
            NO_BLOCK_CREATIONS=false
            shift
            ;;
        --no-signatures)
            NO_SIGNATURES=true
            shift
            ;;
        --signatures)
            NO_SIGNATURES=false
            shift
            ;;
        --no-lock-branch)
            NO_LOCK_BRANCH=true
            shift
            ;;
        --lock-branch)
            NO_LOCK_BRANCH=false
            shift
            ;;
        --no-fork-syncing)
            NO_FORK_SYNCING=true
            shift
            ;;
        --fork-syncing)
            NO_FORK_SYNCING=false
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ -z "$REPO" ]; then
    echo "ERROR: --repo is required" >&2
    usage >&2
    exit 1
fi

if ! printf '%s' "$REPO" | grep -qE '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'; then
    echo "ERROR: --repo must be 'owner/repo', got '$REPO'" >&2
    exit 1
fi

if [ "$STRICT" != "true" ] && [ "$STRICT" != "false" ]; then
    echo "ERROR: --strict must be 'true' or 'false', got '$STRICT'" >&2
    exit 1
fi

IFS=',' read -ra CHECK_ARRAY <<< "$CHECKS"
CHECKS_JSON="$(printf '%s\n' "${CHECK_ARRAY[@]}" | jq -R . | jq -s .)"

STRICT_JSON="$([[ "$STRICT" == "true" ]] && echo "true" || echo "false")"

ENFORCE_ADMINS_JSON="$([[ "$ENFORCE_ADMINS" == "true" ]] && echo "true" || echo "false")"
LINEAR_HISTORY_JSON="$([[ "$LINEAR_HISTORY" == "true" ]] && echo "true" || echo "false")"
CONVERSATION_RESOLUTION_JSON="$([[ "$CONVERSATION_RESOLUTION" == "true" ]] && echo "true" || echo "false")"
ALLOW_FORCE_PUSHES_JSON="$([[ "$NO_FORCE_PUSHES" == "true" ]] && echo "false" || echo "true")"
ALLOW_DELETIONS_JSON="$([[ "$NO_DELETIONS" == "true" ]] && echo "false" || echo "true")"
BLOCK_CREATIONS_JSON="$([[ "$NO_BLOCK_CREATIONS" == "true" ]] && echo "true" || echo "false")"
REQUIRED_SIGNATURES_JSON="$([[ "$NO_SIGNATURES" == "true" ]] && echo "true" || echo "false")"
LOCK_BRANCH_JSON="$([[ "$NO_LOCK_BRANCH" == "true" ]] && echo "true" || echo "false")"
ALLOW_FORK_SYNCING_JSON="$([[ "$NO_FORK_SYNCING" == "true" ]] && echo "false" || echo "true")"

PAYLOAD="$(jq -n \
    --argjson checks "$CHECKS_JSON" \
    --argjson strict "$STRICT_JSON" \
    --argjson enforce_admins "$ENFORCE_ADMINS_JSON" \
    --argjson required_linear_history "$LINEAR_HISTORY_JSON" \
    --argjson required_conversation_resolution "$CONVERSATION_RESOLUTION_JSON" \
    --argjson allow_force_pushes "$ALLOW_FORCE_PUSHES_JSON" \
    --argjson allow_deletions "$ALLOW_DELETIONS_JSON" \
    --argjson block_creations "$BLOCK_CREATIONS_JSON" \
    --argjson required_signatures "$REQUIRED_SIGNATURES_JSON" \
    --argjson lock_branch "$LOCK_BRANCH_JSON" \
    --argjson allow_fork_syncing "$ALLOW_FORK_SYNCING_JSON" \
    '{
        required_status_checks: {
            strict: $strict,
            contexts: $checks
        },
        enforce_admins: $enforce_admins,
        required_linear_history: $required_linear_history,
        required_conversation_resolution: $required_conversation_resolution,
        allow_force_pushes: $allow_force_pushes,
        allow_deletions: $allow_deletions,
        block_creations: $block_creations,
        required_signatures: $required_signatures,
        lock_branch: $lock_branch,
        allow_fork_syncing: $allow_fork_syncing
    }')"

echo "Applying branch protection to $REPO branch $BRANCH..."
echo "Payload: $PAYLOAD"

result=""
gh api --method PUT "repos/$REPO/branches/$BRANCH/protection" --input - <<< "$PAYLOAD" >/dev/null 2>&1 || {
    echo "ERROR: failed to apply branch protection to $REPO/$BRANCH" >&2
    exit 1
}

echo "Protection applied. Verifying..."

RESULT="$(gh api "repos/$REPO/branches/$BRANCH/protection" 2>&1)" || {
    echo "ERROR: failed to fetch branch protection for $REPO/$BRANCH" >&2
    exit 1
}

echo "--- Branch Protection Result ---"
printf '%s\n' "$RESULT" | jq .

echo "--- Verification ---"
ACTUAL_CONTEXTS="$(printf '%s' "$RESULT" | jq -r '.required_status_checks.contexts | join(",")')"
if [ "$ACTUAL_CONTEXTS" != "$CHECKS" ]; then
    echo "ERROR: status check contexts mismatch: expected '$CHECKS', got '$ACTUAL_CONTEXTS'" >&2
    exit 1
fi

ACTUAL_STRICT="$(printf '%s' "$RESULT" | jq -r '.required_status_checks.strict')"
if [ "$ACTUAL_STRICT" != "$STRICT_JSON" ]; then
    echo "ERROR: strict mismatch: expected '$STRICT_JSON', got '$ACTUAL_STRICT'" >&2
    exit 1
fi

ACTUAL_ENFORCE_ADMINS="$(printf '%s' "$RESULT" | jq -r '.enforce_admins')"
if [ "$ACTUAL_ENFORCE_ADMINS" != "$ENFORCE_ADMINS_JSON" ]; then
    echo "ERROR: enforce_admins mismatch: expected '$ENFORCE_ADMINS_JSON', got '$ACTUAL_ENFORCE_ADMINS'" >&2
    exit 1
fi

ACTUAL_LINEAR_HISTORY="$(printf '%s' "$RESULT" | jq -r '.required_linear_history')"
if [ "$ACTUAL_LINEAR_HISTORY" != "$LINEAR_HISTORY_JSON" ]; then
    echo "ERROR: required_linear_history mismatch: expected '$LINEAR_HISTORY_JSON', got '$ACTUAL_LINEAR_HISTORY'" >&2
    exit 1
fi

ACTUAL_REQUIRED_SIGNATURES="$(printf '%s' "$RESULT" | jq -r '.required_signatures')"
if [ "$ACTUAL_REQUIRED_SIGNATURES" != "$REQUIRED_SIGNATURES_JSON" ]; then
    echo "ERROR: required_signatures mismatch: expected '$REQUIRED_SIGNATURES_JSON', got '$ACTUAL_REQUIRED_SIGNATURES'" >&2
    exit 1
fi

ACTUAL_BLOCK_CREATIONS="$(printf '%s' "$RESULT" | jq -r '.block_creations')"
if [ "$ACTUAL_BLOCK_CREATIONS" != "$BLOCK_CREATIONS_JSON" ]; then
    echo "ERROR: block_creations mismatch: expected '$BLOCK_CREATIONS_JSON', got '$ACTUAL_BLOCK_CREATIONS'" >&2
    exit 1
fi

ACTUAL_CONVERSATION_RESOLUTION="$(printf '%s' "$RESULT" | jq -r '.required_conversation_resolution')"
if [ "$ACTUAL_CONVERSATION_RESOLUTION" != "$CONVERSATION_RESOLUTION_JSON" ]; then
    echo "ERROR: required_conversation_resolution mismatch: expected '$CONVERSATION_RESOLUTION_JSON', got '$ACTUAL_CONVERSATION_RESOLUTION'" >&2
    exit 1
fi

ACTUAL_LOCK_BRANCH="$(printf '%s' "$RESULT" | jq -r '.lock_branch')"
if [ "$ACTUAL_LOCK_BRANCH" != "$LOCK_BRANCH_JSON" ]; then
    echo "ERROR: lock_branch mismatch: expected '$LOCK_BRANCH_JSON', got '$ACTUAL_LOCK_BRANCH'" >&2
    exit 1
fi

ACTUAL_ALLOW_FORCE_PUSHES="$(printf '%s' "$RESULT" | jq -r '.allow_force_pushes')"
if [ "$ACTUAL_ALLOW_FORCE_PUSHES" != "$ALLOW_FORCE_PUSHES_JSON" ]; then
    echo "ERROR: allow_force_pushes mismatch: expected '$ALLOW_FORCE_PUSHES_JSON', got '$ACTUAL_ALLOW_FORCE_PUSHES'" >&2
    exit 1
fi

ACTUAL_ALLOW_DELETIONS="$(printf '%s' "$RESULT" | jq -r '.allow_deletions')"
if [ "$ACTUAL_ALLOW_DELETIONS" != "$ALLOW_DELETIONS_JSON" ]; then
    echo "ERROR: allow_deletions mismatch: expected '$ALLOW_DELETIONS_JSON', got '$ACTUAL_ALLOW_DELETIONS'" >&2
    exit 1
fi

ACTUAL_ALLOW_FORK_SYNCING="$(printf '%s' "$RESULT" | jq -r '.allow_fork_syncing')"
if [ "$ACTUAL_ALLOW_FORK_SYNCING" != "$ALLOW_FORK_SYNCING_JSON" ]; then
    echo "ERROR: allow_fork_syncing mismatch: expected '$ALLOW_FORK_SYNCING_JSON', got '$ACTUAL_ALLOW_FORK_SYNCING'" >&2
    exit 1
fi

echo "All branch protection settings verified successfully for $REPO/$BRANCH."