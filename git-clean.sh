#!/usr/bin/env bash

set -Eeuo pipefail

#######################################
# Git Clean CLI
# Author: Aman Kumar
# Description: Clean local Git repositories or delete GitHub repositories.
#######################################

VERSION="1.0.0"

# ---------- Colors ----------
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
BOLD="\033[1m"
RESET="\033[0m"

# ---------- Helpers ----------

info()    { echo -e "${BLUE}${1}${RESET}"; }
success() { echo -e "${GREEN}${1}${RESET}"; }
warn()    { echo -e "${YELLOW}${1}${RESET}"; }
error()   { echo -e "${RED}${1}${RESET}" >&2; }

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        error "Missing dependency: $1"
        exit 1
    }
}

usage() {
cat <<EOF
${BOLD}Git Clean v${VERSION}${RESET}

Usage:
  git-clean local [PATH ...]
      Search and delete local Git repositories.

  git-clean github [--private]
      Search and delete repositories from your GitHub account.

Options:
  -h, --help        Show help.
  -v, --version     Show version.

Examples:
  git-clean local
  git-clean local ~/Projects ~/Work
  git-clean github
  git-clean github --private
EOF
}

confirm_delete() {
    echo
    warn "This action is permanent."
    read -rp "Type DELETE to continue: " confirm

    [[ "$confirm" == "DELETE" ]]
}

#######################################
# Local Repository Cleaner
#######################################

local_clean() {

    require_cmd git
    require_cmd fzf

    local roots=()

    if [[ $# -gt 0 ]]; then
        roots=("$@")
    else
        roots=(
            "$HOME/Projects"
            "$HOME/Code"
            "$HOME/Work"
            "$HOME/Desktop"
            "$HOME/Documents"
        )
    fi

    info "Searching for Git repositories..."

    repos=$(
        for root in "${roots[@]}"; do
            [[ -d "$root" ]] || continue

            find "$root" \
                -type d \
                \( -name node_modules -o -name .Trash -o -name Library \) -prune -o \
                -type d -name ".git" -print
        done | while read -r gitdir; do
            repo="${gitdir%/.git}"

            size=$(du -sh "$repo" 2>/dev/null | cut -f1)
            date=$(git -C "$repo" log -1 --date=short --format="%ad" 2>/dev/null || echo "-")
            remote=$(git -C "$repo" remote get-url origin 2>/dev/null || echo "No remote")

            printf "%-10s %-12s %-45s %s\n" "$size" "$date" "$repo" "$remote"
        done
    )

    [[ -z "$repos" ]] && {
        warn "No Git repositories found."
        exit 0
    }

    selected=$(
        echo "$repos" |
        fzf --multi \
            --ansi \
            --header="TAB = select multiple | ENTER = confirm" \
            --prompt="Local Repositories > " \
            --preview='git -C {3} log --oneline --decorate -5 2>/dev/null || echo "No commits"' \
            --preview-window=right:60%
    )

    [[ -z "$selected" ]] && exit 0

    echo
    warn "Repositories selected:"
    echo "$selected" | awk '{print " - " $3}'

    confirm_delete || {
        warn "Cancelled."
        exit 0
    }

    echo "$selected" | while read -r line; do
        repo=$(echo "$line" | awk '{print $3}')
        rm -rf "$repo"
        success "Deleted: $repo"
    done
}

#######################################
# GitHub Repository Cleaner
#######################################

github_clean() {

    require_cmd gh
    require_cmd fzf

    gh auth status >/dev/null 2>&1 || {
        error "GitHub CLI is not authenticated."
        echo "Run: gh auth login"
        exit 1
    }

    filter="${1:-}"

    info "Fetching GitHub repositories..."

    if [[ "$filter" == "--private" ]]; then
        repos=$(gh repo list --limit 1000 --visibility private \
            --json nameWithOwner,pushedAt \
            --jq '.[] | "\(.nameWithOwner)\tPRIVATE\t\(.pushedAt[0:10])"')
    else
        repos=$(gh repo list --limit 1000 \
            --json nameWithOwner,isPrivate,pushedAt \
            --jq '.[] | "\(.nameWithOwner)\t\(.isPrivate)\t\(.pushedAt[0:10])"')
    fi

    [[ -z "$repos" ]] && {
        warn "No repositories found."
        exit 0
    }

    selected=$(
        echo "$repos" |
        fzf --multi \
            --header="TAB = select multiple | ENTER = confirm" \
            --prompt="GitHub Repositories > " \
            --preview='gh repo view {1} --web=false'
    )

    [[ -z "$selected" ]] && exit 0

    echo
    warn "Repositories selected:"
    echo "$selected" | cut -f1

    confirm_delete || {
        warn "Cancelled."
        exit 0
    }

    echo "$selected" | while IFS=$'\t' read -r repo _; do
        gh repo delete "$repo" --yes
        success "Deleted GitHub repository: $repo"
    done
}

#######################################
# Entry Point
#######################################

case "${1:-}" in
    local)
        shift
        local_clean "$@"
        ;;

    github)
        shift
        github_clean "$@"
        ;;

    -v|--version)
        echo "git-clean v${VERSION}"
        ;;

    -h|--help|"")
        usage
        ;;

    *)
        error "Unknown command: $1"
        echo
        usage
        exit 1
        ;;
esac