{
  pkgs,
  name,
  version,
  baseImage ? null,
  includeDevTools ? false,
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
    contents = [
      pkgs.minio
    ] ++ (pkgs.lib.optionals includeDevTools [
      pkgs.bashInteractive
      coreutils
      curl
      procps
    ]);
    config = {
      Entrypoint = [ "${pkgs.lib.getExe pkgs.minio}" "server" ];
      Cmd = [ "/data" "--console-address" ":9001" ];
      ExposedPorts = {
        "9000/tcp" = {}; 
        "9001/tcp" = {}; 
      };
      Env = [
        "MINIO_ROOT_USER=admin"
        "MINIO_ROOT_PASSWORD=password"
        "PATH=/bin" 
      ];
      Volumes = {
        "/data" = {};
      };
    };
  };
}

