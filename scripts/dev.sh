#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# print an error message
echo_error() {
  echo "Error:" "$@" 1>&2
}

# if the listed commands aren't found, exit with an error message
test_commands() {
  local flags=$-
  local exit=false
  if [[ $flags =~ e ]]; then set +e; fi # disable exit on error
  # for each argument
  while [[ $# -gt 0 ]]; do
    # check that command is defined
    if [ ! -x "$(command -v "$1")" ]; then
      echo_error "The required program \"$1\" is not installed"
      exit=true
    fi
    shift
  done
  if [[ $flags =~ e ]]; then set -e; fi # re-enable exit on error
  if $exit; then exit 1; fi
}

# if the listed env variables aren't found, exit with an error message
test_env_variables() {
  local flags=$-
  local exit=false
  if [[ $flags =~ u ]]; then set +u; fi # disable exit on undefined variables
  # for each argument
  while [[ $# -gt 0 ]]; do
    # check that env variable is defined
    if [ -z "${!1}" ]; then
      echo_error "The required environment variable \"$1\" is not defined"
      exit=true
    fi
    shift
  done
  if [[ $flags =~ u ]]; then set -u; fi # re-enable exit on undefined variables
  if $exit; then exit 1; fi
}

process_ids=()
# kill each process in process_ids
kill_processes() {
  local flags=$-
  if [[ $flags =~ e ]]; then set +e; fi # disable exit on error
  # send kill signal to each process
  for process_id in "${process_ids[@]}"; do
    kill -9 -- "-$process_id" > /dev/null 2>&1
  done
  # wait for each process to exit
  for process_id in "${process_ids[@]}"; do
    wait "$process_id" 2>/dev/null
  done
  if [[ $flags =~ e ]]; then set -e; fi # re-enable exit on error
}

: "${SF_START_MODE:=}"
: "${DB_START_MODE:=}"
: "${NFS_START_MODE:=}"
: "${WEB_START_MODE:=}"
read -r -a SF_ARGS <<< "${SF_ARGS[*]:-${SF_ARGS:-}}"
read -r -a DB_ARGS <<< "${DB_ARGS[*]:-${DB_ARGS:-}}"
read -r -a NFS_ARGS <<< "${NFS_ARGS[*]:-${NFS_ARGS:-}}"
read -r -a WEB_ARGS <<< "${WEB_ARGS[*]:-${WEB_ARGS:-}}"
# determine the functions to run from arguments
interpret_args() {
  local last_target=
  # if no arguments passed, use default arguments
  if [[ $# -le 0 ]]; then
    set -- all
  fi
  # start each target specified by arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      all)
        last_target=ALL
        shift
        set -- _ sf db nfs web allargs "$@"
      ;;
      allargs)
        last_target=ALL
      ;;
      sf|seafile)
        last_target=SF
        : "${SF_START_MODE:=debug}"
      ;;
      db|database)
        last_target=DB
        : "${DB_START_MODE:=debug}"
      ;;
      nfs|networkfilesystem)
        last_target=NFS
        : "${NFS_START_MODE:=debug}"
      ;;
      web|webserver)
        last_target=WEB
        : "${WEB_START_MODE:=debug}"
      ;;
      *)
        if [[ -z "$last_target" ]]; then
          # if no target set, print error
          echo_error "The argument \"$1\" is not recognized"
          exit 1
        elif [[ "${last_target:-}" == "ALL" ]]; then
          # apply arg to all targets
          arg="$1"
          shift
          set -- _ sf "$arg" db "$arg" nfs "$arg" web "$arg" allargs "$@"
        else
          # apply to last target
          if (shopt -s nocasematch; [[ "$1" =~ ^(slim|debug)$ ]]); then
            # apply start mode
            local -n __ref_mode="${last_target^^}_START_MODE"
            __ref_mode="${1,,}"
          else
            # apply arg
            local -n __ref_target="${last_target^^}_ARGS"
            __ref_target+=("$1")
          fi
        fi
      ;;
    esac
    shift
  done
}

# TODO setup: run dev [--debug|--slim] YELLOWWARN[!] Running in slim mode (distroless). No shell access available.
# entrypoint of the script
main() {
  # load values from the secrets file
  : "${START_ENV_FILE:=".env"}"
  if [ -r "./load-env.sh" ]; then
    # shellcheck disable=SC1091 source=/dev/null
    ENV_FILE="$START_ENV_FILE" source ./load-env.sh
  fi
  # load values from CLI
  interpret_args "$@"
  
  # # set default values
  # set -a
  # : "${POSTGRES_WEBSERVER_USERNAME:="webserver"}"
  # : "${POSTGRES_ANALYTICS_USERNAME:="analytics"}"
  # : "${POSTGRES_DATABASE_MAIN:="main"}"
  # : "${POSTGRES_NETLOC:="localhost"}"
  # : "${POSTGRES_PORT:="5432"}"
  # set +a
  # interpret_args "$@"
  # trap kill_processes EXIT
  # # start apps
  # if "$do_start_database"; then
  #   script_start_database "${script_args[@]}"
  # fi
  # if "$do_start_analytics"; then
  #   # TODO script_start_analytics "${script_args[@]}"
  #   :
  # fi
  # if "$do_start_webserver"; then
  #   script_start_webserver "${script_args[@]}"
  # fi
  # # wait for any background job to terminate
  # wait -n
}

main "$@"

