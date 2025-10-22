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
      devShells = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            awscli2
            minio
          ];
        };
      };
    }
  );
}
