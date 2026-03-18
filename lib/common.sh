#!/usr/bin/env bash

set_output() {
  local name="$1"
  local value="${2-}"

  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf '%s=%s\n' "$name" "$value" >>"$GITHUB_OUTPUT"
  fi
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

is_truthy() {
  case "${1,,}" in
    true | 1 | yes | y | on)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

require_non_empty() {
  local value="$1"
  local message="$2"

  if [[ -z "$value" ]]; then
    error "$message"
    return 1
  fi
}
