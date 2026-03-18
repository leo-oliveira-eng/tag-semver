#!/usr/bin/env bash

read_pr_field() {
  local jq_expression="$1"
  jq --raw-output "$jq_expression" "$GITHUB_EVENT_PATH"
}

is_allowed_branch() {
  local branch="$1"
  local allowed_csv="$2"
  local candidate=""
  local -a branches=()

  IFS=',' read -r -a branches <<<"$allowed_csv"
  for candidate in "${branches[@]}"; do
    candidate="$(trim "$candidate")"
    [[ -n "$candidate" ]] || continue

    if [[ "$candidate" == "$branch" ]]; then
      return 0
    fi
  done

  return 1
}

github_get_pr_labels() {
  local pr_number="$1"
  gh pr view "$pr_number" --json labels --jq '.labels[].name'
}
