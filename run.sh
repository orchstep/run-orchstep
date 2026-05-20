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

  cd "$workdir" || { echo "ERROR: working-directory '$workdir' not found" >&2; exit 1; }

  local cmd_raw
  if ! cmd_raw="$(build_command "$cmd" "$workflow" "$task")"; then
    exit 1
  fi
  # bash 3.2 (macOS runners) lacks `mapfile`; use a portable read loop.
  local argv=()
  local line
  while IFS= read -r line; do argv+=("$line"); done <<< "$cmd_raw"

  if [[ -n "${INPUT_VARS:-}" ]]; then
    local var_raw
    if ! var_raw="$(printf '%s\n' "$INPUT_VARS" | parse_vars)"; then
      exit 1
    fi
    if [[ -n "$var_raw" ]]; then
      local var_args=()
      local var_line
      while IFS= read -r var_line; do var_args+=("$var_line"); done <<< "$var_raw"
      argv+=("${var_args[@]}")
    fi
  fi
  if [[ -n "${INPUT_VARS_FILE:-}" ]]; then
    argv+=("--vars-file" "$INPUT_VARS_FILE")
  fi
  if [[ -n "${INPUT_ENV:-}" ]]; then
    argv+=("--env" "$INPUT_ENV")
  fi
  if [[ -n "${INPUT_EXTRA_ARGS:-}" ]]; then
    local extra=()
    set -f
    # shellcheck disable=SC2206
    extra=(${INPUT_EXTRA_ARGS})
    set +f
    argv+=("${extra[@]}")
  fi

  # out_file is intentionally a global so the EXIT trap can still see it
  # after main() returns (function locals go out of scope at that point).
  out_file="$(mktemp)"
  trap 'rm -f "${out_file:-}"' EXIT
  local code=0
  set +e
  orchstep "${argv[@]}" 2>&1 | tee "$out_file"
  code="${PIPESTATUS[0]}"
  set -e

  local total_lines
  total_lines="$(wc -l < "$out_file")"

  {
    echo "exit-code=${code}"
    echo "summary<<__ORCHSTEP_EOF__"
    head -50 "$out_file"
    [[ "$total_lines" -gt 50 ]] && echo "... (output truncated)"
    echo "__ORCHSTEP_EOF__"
  } >> "${GITHUB_OUTPUT:-/dev/stdout}"

  {
    echo "### OrchStep \`${cmd}\` — \`${workflow}\`"
    echo ''
    echo '```'
    head -100 "$out_file"
    [[ "$total_lines" -gt 100 ]] && echo "... (output truncated)"
    echo '```'
  } >> "${GITHUB_STEP_SUMMARY:-/dev/stdout}"

  local fail_on_error="${INPUT_FAIL_ON_ERROR:-true}"
  # bash 3.2 (macOS runners) lacks `${var,,}`; lowercase via tr.
  local fail_lower
  fail_lower=$(printf '%s' "$fail_on_error" | tr '[:upper:]' '[:lower:]')
  if [[ "$fail_lower" != "false" && "$code" -ne 0 ]]; then
    exit "$code"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
