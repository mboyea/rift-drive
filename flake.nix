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
        # deploy = pkgs.lib.run {
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
        scripts-run-alias = pkgs.writeShellScriptBin "run" ''
          TARGET_SCRIPT=''${1:-help}
          ROOT_DIR=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null)
          ROOT_DIR=''${ROOT_DIR:-$(pwd)}
          SCRIPT_PATH="$ROOT_DIR/scripts/$TARGET_SCRIPT.sh"
          LOCAL_CACHE_DIR="$ROOT_DIR/.direnv/scripts-run-cache"
          LOCAL_CACHE_PATH="$LOCAL_CACHE_DIR/$TARGET_SCRIPT"
          SHELL_CACHE_PATH=$(command -v "${pname}-$TARGET_SCRIPT-${version}" 2>/dev/null)
          if [[ -f "$SCRIPT_PATH" ]]; then
            SCRIPT_TIME=$(stat -c %Y "$SCRIPT_PATH")
            LOCAL_CACHE_TIME=$(stat -c %Y "$LOCAL_CACHE_PATH" 2>/dev/null || echo 0)
            if [[ -L "$LOCAL_CACHE_PATH" ]] && (( "$LOCAL_CACHE_TIME" >= "$SCRIPT_TIME" )); then
              exec "$(readlink -f "$LOCAL_CACHE_PATH")" "''${@:2}"
            else
              SHELL_CACHE_TIME=$(nix path-info --json "$SHELL_CACHE_PATH" | jq '.[].registrationTime')
              if [[ -n "$SHELL_CACHE_PATH" ]] && (( "$SHELL_CACHE_TIME" >= "$SCRIPT_TIME" )); then
                mkdir -p "$LOCAL_CACHE_DIR"
		ln -sf "$SHELL_CACHE_PATH" "$LOCAL_CACHE_PATH"
                exec "$SHELL_CACHE_PATH" "''${@:2}"
              fi
            fi
          fi
          if BUILD_PATH=$(nix build .#"$TARGET_SCRIPT" --no-link --print-out-paths); then
            BIN_PATH=$(find "$BUILD_PATH/bin" -type f -executable | head -n 1)
            mkdir -p "$LOCAL_CACHE_DIR"
            ln -sf "$BIN_PATH" "$LOCAL_CACHE_PATH"
            exec "$BIN_PATH" "''${@:2}"
          else
            exit $?
          fi
        '';
        packages-cache = pkgs.symlinkJoin { name = "${pname}-${version}-scripts"; paths = builtins.attrValues packages; };
      in {
        default = pkgs.mkShell {
          inputsFrom = pkgs.lib.mapAttrsToList (n: v: v.devShells.default) modules;
          packages = [
            scripts-run-alias # run <script> (cache-enabled)
            packages-cache    # bring scripts into the shell for scripts-run-alias enable run-alias to derive scripts without re-evaluation (fast!)
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
