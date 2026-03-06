{
  description = "Rift Drive CLI";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }: let
    name = "rift-drive";
    version = "0.0.0";
    flakeUtils = flake-utils;
  in flakeUtils.lib.eachDefaultSystem (
    system: let
      pkgs = (import nixpkgs { inherit system; }).extend (final: prev: {
        utils = (import "${self}/utils" { pkgs = final; }).packages;
      });
    in rec {
      legacyPackages = pkgs;
      packages = {
        help = pkgs.utils.run {
           name = "${name}-help-${version}";
           target = ./scripts/help.sh;
        };
      };
      apps = {
        help = flakeUtils.lib.mkApp { drv = packages.help; };
        default = apps.help;
      };
      devShells = let
        run-alias = pkgs.writeShellScriptBin "run" ''
          TARGET_SCRIPT=''${1:-help}
          BIN_NAME="${name}-$TARGET_SCRIPT-${version}"
          if command -v "$BIN_NAME" >/dev/null 2>&1; then
            exec "$BIN_NAME" "''${@:2}"
          else
            exec nix run .#"$TARGET_SCRIPT" -- "''${@:2}"
          fi
        '';
        bin-scripts = pkgs.symlinkJoin { name = "${name}-${version}-scripts"; paths = builtins.attrValues packages; };
      in {
        default = pkgs.mkShell {
          packages = [
            run-alias                 # run <script>
            bin-scripts               # enable run-alias to derive scripts without re-evaluation (fast!)
            pkgs.nix-prefetch-docker  # dockerTools.pullImage < nix-prefetch-docker --quiet --image-name _ --image-tag _ --image-digest _
          ];
          shellHook = ''
            # load .env
            ENV_FILE=".env" source ./scripts/load-env.sh
            # suppress warning about dirty git for nix commands
            export NIX_CONFIG="warn-dirty = false"
            echo -e "\033[1;32mSUCCESSFULLY LOADED DEVSHELL FOR ${name}-${version}\033[0m"
          '';
        };
      };
    }
  );
}
