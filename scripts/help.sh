#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

echo "This is the Rift Drive Command Line Interface."
echo
echo "Usage:"
echo "  nix run"
echo "  └ Alias for \"nix run .#help\""
echo "  nix run .#script [args...]"
echo "  └ Run a script"
echo "  nix develop"
echo "  └ Start a subshell with the project dependencies installed"
echo
echo "Scripts:"
echo "  help  | Print usage information for the Rift Drive CLI"
echo

