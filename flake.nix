{
  description = "Rift Drive CLI";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }: let
    pname = "rift-drive";
    version = "0.0.0";
    utils = flake-utils;
    _lib = import ./lib;
    _modules = import ./modules;
  in {
    lib = _lib;
    modules = _modules;
  } // utils.lib.eachDefaultSystem (
    system: let
      pkgs = _lib.extend (import nixpkgs { inherit system; });
      modules = _modules { inherit pkgs; };
    in rec {
      legacyPackages = pkgs;
      packages = {
        # deploy = pkgs.lib.run {################   run deploy [--stage|--prod]
        #   name = "${pname}-deploy-${version}";
        #   target = ./scripts/deploy.sh;
        # };
        dev = pkgs.lib.run {
          name = "${pname}-dev-${version}";
          target = ./scripts/dev.sh;
        };
        help = pkgs.lib.run {
           name = "${pname}-help-${version}";
           target = ./scripts/help.sh;
        };
      };
      apps = {
        help = utils.lib.mkApp { drv = packages.help; };
        default = apps.help;
      };
      devShells = let
        run-scripts-alias = pkgs.writeShellScriptBin "run" ''
          TARGET_SCRIPT=''${1:-help}
          ROOT_DIR=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null)
          ROOT_DIR=''${ROOT_DIR:-$(pwd)}
          SCRIPT_PATH="$ROOT_DIR/scripts/$TARGET_SCRIPT.sh"
          MARKER_DIR="$ROOT_DIR/.direnv/run-scripts-cache"
          MARKER_PATH="$MARKER_DIR/$TARGET_SCRIPT.ok"
          CACHE_BIN=$(command -v "${pname}-$TARGET_SCRIPT-${version}" 2>/dev/null)
          if [[ -z "$CACHE_BIN" || ! -f "$SCRIPT_PATH" || ! -f "$MARKER_PATH" || "$SCRIPT_PATH" -nt "$MARKER_PATH" ]]; then
            echo "cache miss"
            mkdir -p "$MARKER_DIR"
            
            if nix run .#"$TARGET_SCRIPT" -- "''${@:2}"; then
              touch "$MARKER_PATH"
            else
              exit $?
            fi
          else
            echo "cache hit"
            exec "$CACHE_BIN" "''${@:2}"
          fi
        '';
        bin-scripts = pkgs.symlinkJoin { name = "${pname}-${version}-scripts"; paths = builtins.attrValues packages; };
      in {
        default = pkgs.mkShell {
          inputsFrom = pkgs.lib.mapAttrsToList (n: v: v.devShells.default) modules;
          packages = [
            run-scripts-alias   # run <script> (cache-enabled)
            bin-scripts # enable run-alias to derive scripts without re-evaluation (fast!)
          ];
          shellHook = ''
            # load .env
            ENV_FILE=".env" source ./scripts/load-env.sh
            # suppress warning about dirty git for nix commands
            export NIX_CONFIG="warn-dirty = false"
            # print success message
            echo -e "\033[1;32mSUCCESSFULLY LOADED DEVSHELL FOR ${pname}-${version}\033[0m"
          '';
        };
      };
    }
  );
}
