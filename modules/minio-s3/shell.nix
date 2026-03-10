{
  pkgs ? import <nixpkgs> {},
}: pkgs.mkShell {
  packages = [
    pkgs.minio-client # mc
    pkgs.podman       # podman cli
    pkgs.jq           # parse output of mc --json or podman inspect
    pkgs.awscli2      # s3 compatibility testing
    pkgs.openssl      # cert/handshake debugging
  ];
}

