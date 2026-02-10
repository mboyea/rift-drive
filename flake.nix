{
  description = "Rift Drive CLI";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }: let
    name = "rift-drive";
    version = "0.0.0";
    utils = flake-utils;
  in utils.lib.eachDefaultSystem (
    system: let
      pkgs = import nixpkgs { inherit system; };
    in rec {
      packages = {
        help = pkgs.callPackage ./utils/run.nix {
           name = "${name}-help-${version}";
           target = ./scripts/help.sh;
        };
      };
      apps = {
        help = utils.lib.mkApp { drv = packages.help; };
        default = apps.help;
      };
      devShells = let
        run-alias = pkgs.writeShellScriptBin "run" ''
          script_name="$1" && shift
          exec nix run .#"$script_name" -- "$@"
        '';
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            run-alias
            awscli2
            minio
          ];
          shellHook = ''
            # suppress warning about dirty git for nix commands
            export NIX_CONFIG="warn-dirty = false"
          '';
        };
      };
    }
  );
}
