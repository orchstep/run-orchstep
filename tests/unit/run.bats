#!/usr/bin/env bats

setup() {
  source "${BATS_TEST_DIRNAME}/../../run.sh"
}

@test "parse_vars emits a --var token pair per line" {
  run bash -c 'source '"${BATS_TEST_DIRNAME}"'/../../run.sh; printf "env=prod\nreplicas=3\n" | parse_vars'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "--var" ]
  [ "${lines[1]}" = "env=prod" ]
  [ "${lines[2]}" = "--var" ]
  [ "${lines[3]}" = "replicas=3" ]
}

@test "parse_vars skips blank lines and comments" {
  run bash -c 'source '"${BATS_TEST_DIRNAME}"'/../../run.sh; printf "\n# a comment\nenv=prod\n" | parse_vars'
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[1]}" = "env=prod" ]
}

@test "parse_vars fails on a line without an equals sign" {
  run bash -c 'source '"${BATS_TEST_DIRNAME}"'/../../run.sh; printf "notavar\n" | parse_vars'
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid var line"* ]]
}

@test "build_command for run puts the workflow behind --file" {
  run build_command run deploy.yml
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "run" ]
  [ "${lines[1]}" = "--file" ]
  [ "${lines[2]}" = "deploy.yml" ]
}

@test "build_command for run appends the task as a positional arg" {
  run build_command run deploy.yml release
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "run" ]
  [ "${lines[1]}" = "--file" ]
  [ "${lines[2]}" = "deploy.yml" ]
  [ "${lines[3]}" = "release" ]
}

@test "build_command for lint puts the workflow as a positional arg" {
  run build_command lint deploy.yml
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "lint" ]
  [ "${lines[1]}" = "deploy.yml" ]
}

@test "build_command for list-tasks puts the workflow as a positional arg" {
  run build_command list-tasks deploy.yml
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "list-tasks" ]
  [ "${lines[1]}" = "deploy.yml" ]
}

@test "build_command fails for an unsupported command" {
  run build_command frobnicate deploy.yml
  [ "$status" -eq 1 ]
  [[ "$output" == *"unsupported command"* ]]
}

@test "main runs the CLI and writes exit-code 0 on success" {
  local tmp; tmp="$(mktemp -d)"
  cp "${BATS_TEST_DIRNAME}/../fixtures/fake-orchstep.sh" "${tmp}/orchstep"
  chmod +x "${tmp}/orchstep"
  echo "tasks:" > "${tmp}/wf.yml"
  PATH="${tmp}:${PATH}" \
  INPUT_COMMAND="run" \
  INPUT_WORKFLOW="wf.yml" \
  INPUT_WORKING_DIRECTORY="${tmp}" \
  INPUT_FAIL_ON_ERROR="true" \
  GITHUB_OUTPUT="${tmp}/out" \
  GITHUB_STEP_SUMMARY="${tmp}/summary" \
    run bash "${BATS_TEST_DIRNAME}/../../run.sh"
  [ "$status" -eq 0 ]
  grep -q "exit-code=0" "${tmp}/out"
  rm -rf "$tmp"
}

@test "main with fail-on-error=false exits 0 but records the nonzero exit-code" {
  local tmp; tmp="$(mktemp -d)"
  cp "${BATS_TEST_DIRNAME}/../fixtures/fake-orchstep.sh" "${tmp}/orchstep"
  chmod +x "${tmp}/orchstep"
  echo "tasks:" > "${tmp}/wf.yml"
  PATH="${tmp}:${PATH}" \
  FAKE_EXIT="3" \
  INPUT_COMMAND="run" \
  INPUT_WORKFLOW="wf.yml" \
  INPUT_WORKING_DIRECTORY="${tmp}" \
  INPUT_FAIL_ON_ERROR="false" \
  GITHUB_OUTPUT="${tmp}/out" \
  GITHUB_STEP_SUMMARY="${tmp}/summary" \
    run bash "${BATS_TEST_DIRNAME}/../../run.sh"
  [ "$status" -eq 0 ]
  grep -q "exit-code=3" "${tmp}/out"
  rm -rf "$tmp"
}

@test "main with fail-on-error=true propagates a nonzero exit code" {
  local tmp; tmp="$(mktemp -d)"
  cp "${BATS_TEST_DIRNAME}/../fixtures/fake-orchstep.sh" "${tmp}/orchstep"
  chmod +x "${tmp}/orchstep"
  echo "tasks:" > "${tmp}/wf.yml"
  PATH="${tmp}:${PATH}" \
  FAKE_EXIT="3" \
  INPUT_COMMAND="run" \
  INPUT_WORKFLOW="wf.yml" \
  INPUT_WORKING_DIRECTORY="${tmp}" \
  INPUT_FAIL_ON_ERROR="true" \
  GITHUB_OUTPUT="${tmp}/out" \
  GITHUB_STEP_SUMMARY="${tmp}/summary" \
    run bash "${BATS_TEST_DIRNAME}/../../run.sh"
  [ "$status" -eq 3 ]
  rm -rf "$tmp"
}
