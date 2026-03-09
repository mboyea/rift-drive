{
  pkgs,
}: let
  pkgs = (import ../lib).extend pkgs;
in pkgs.lib.mapAttrs'
  (n: v: let
    name = pkgs.lib.toCamelCase n;
    value = import (./. + "/${n}") { inherit pkgs; };
  in pkgs.lib.nameValuePair name value)
  (pkgs.lib.filterAttrs (n: v: v == "directory") (builtins.readDir ./.))

