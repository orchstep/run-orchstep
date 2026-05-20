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
