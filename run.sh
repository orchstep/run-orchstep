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

  local cmd="${INPUT_COMMAND:-run}"
  local workflow="${INPUT_WORKFLOW:?workflow input is required}"
  local task="${INPUT_TASK:-}"
  local workdir="${INPUT_WORKING_DIRECTORY:-${GITHUB_WORKSPACE:-.}}"

  cd "$workdir"

  local argv=()
  mapfile -t argv < <(build_command "$cmd" "$workflow" "$task")

  if [[ -n "${INPUT_VARS:-}" ]]; then
    local var_args=()
    mapfile -t var_args < <(printf '%s\n' "$INPUT_VARS" | parse_vars)
    argv+=("${var_args[@]}")
  fi
  if [[ -n "${INPUT_VARS_FILE:-}" ]]; then
    argv+=("--vars-file" "$INPUT_VARS_FILE")
  fi
  if [[ -n "${INPUT_ENV:-}" ]]; then
    argv+=("--env" "$INPUT_ENV")
  fi
  if [[ -n "${INPUT_EXTRA_ARGS:-}" ]]; then
    local extra=()
    # shellcheck disable=SC2206
    extra=(${INPUT_EXTRA_ARGS})
    argv+=("${extra[@]}")
  fi

  local out_file
  out_file="$(mktemp)"
  local code=0
  set +e
  orchstep "${argv[@]}" 2>&1 | tee "$out_file"
  code="${PIPESTATUS[0]}"
  set -e

  {
    echo "exit-code=${code}"
    echo "summary<<__ORCHSTEP_EOF__"
    head -50 "$out_file"
    echo "__ORCHSTEP_EOF__"
  } >> "${GITHUB_OUTPUT:-/dev/stdout}"

  {
    echo "### OrchStep \`${cmd}\` — \`${workflow}\`"
    echo ''
    echo '```'
    head -100 "$out_file"
    echo '```'
  } >> "${GITHUB_STEP_SUMMARY:-/dev/stdout}"

  rm -f "$out_file"

  if [[ "${INPUT_FAIL_ON_ERROR:-true}" == "true" && "$code" -ne 0 ]]; then
    exit "$code"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
