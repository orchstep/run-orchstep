#!/usr/bin/env bash
# OrchStep runner — used by the run-orchstep composite action.
# Defines pure functions plus a main entrypoint. No top-level `set -e` so it
# can be sourced by bats; main() enables strict mode itself.

parse_vars() {
  local line
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" != *=* ]]; then
      echo "ERROR: invalid var line '${line}' (expected KEY=VALUE)" >&2
      return 1
    fi
    printf '%s\n' "--var" "$line"
  done
}

build_command() {
  local cmd="$1" workflow="$2" task="${3:-}"
  case "$cmd" in
    run)
      printf '%s\n' "run" "--file" "$workflow"
      [[ -n "$task" ]] && printf '%s\n' "$task"
      ;;
    lint|list-tasks)
      printf '%s\n' "$cmd" "$workflow"
      ;;
    *)
      echo "ERROR: unsupported command '${cmd}' (expected run, lint, or list-tasks)" >&2
      return 1
      ;;
  esac
  return 0
}

main() {
  set -euo pipefail
  echo "main not yet implemented" >&2
  return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
