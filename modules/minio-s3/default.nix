{
  pkgs ? import <nixpkgs> {},
}: let
  name = "minio-s3";
  version = "0.0.0";
in rec {
  packages = {
    appImage = pkgs.callPackage ./packages/app-image.nix {
      inherit name version;
    };
    container = pkgs.callPackage ./packages/container.nix {
      image = packages.appImage;
    };
  };
  devShells.default = import ./shell.nix { inherit pkgs; };
}

