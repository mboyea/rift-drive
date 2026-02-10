#!/usr/bin/env bash
# Note: This script is intended to be SOURCED, not executed.

test_env() {
  # disable exit on undefined variable use
  set +u
  # for each env variable
  while [[ $# -gt 0 ]]; do
    # check that env variable is defined
    if [ -z "${!1}" ]; then
      echo_error The required environment variable "$1" is not defined
      exit 1
    fi
    shift
  done
  # enable exit on undefined variable use
  set -u
}

go_to_top_level_directory() {
  # if git is not installed, return
  if ! [ -x "$(command -v git)" ]; then
    return
  fi
  # if current directory is not a git directory, return
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    return
  fi
  # go to top-level of git directory
  base_dir="$(git rev-parse --show-toplevel)"
  cd "$base_dir"
}

load_env_file() {
  go_to_top_level_directory
  # if file isn't readable, return
  if [ ! -r "$ENV_FILE" ]; then
    return
  fi
  # load .env file
  set -a
  # shellcheck disable=SC1091 source=/dev/null
  source "$ENV_FILE"
  set +a
}

: ${ENV_FILE:=".env"}
test_env ENV_FILE
load_env_file

