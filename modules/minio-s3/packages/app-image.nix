{
  pkgs,
  name,
  version,
  baseImage ? null,
}: let
  _name = "${name}-app-image";
  tag = version;
in {
  name = _name;
  inherit version tag;
  stream = pkgs.dockerTools.streamLayeredImage {
    name = _name;
    inherit tag;
    fromImage = baseImage;
    config = {
      # ! TODO Entrypoint = [ "docker-entrypoint.sh" ];
      # ! TODO Cmd = [ "postgres" ];
      # ExposedPorts = {
      #   # ! TODO "5432/tcp" = {};
      # };
      # Volumes = {
      #   # ! TODO "/var/lib/postgresql/data" = {};
      # };
    };
  };
}

