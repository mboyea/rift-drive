{ pkgs }: let
  toCamelCase = str: let
    parts = pkgs.lib.splitString "-" str;
    upperFirst = word: (pkgs.lib.toUpper (builtins.substring 0 1 word)) + (builtins.substring 1 (builtins.stringLength word) word);
  in if (builtins.length parts) < 2
    then str
    else let
      first = pkgs.lib.head parts;
      rest = map upperFirst (pkgs.lib.tail parts);
    in builtins.concatStringsSep "" ([first] ++ rest);
in {
  packages = pkgs.lib.mapAttrs'
    (fileName: _: let
      baseName = pkgs.lib.removeSuffix ".nix" fileName;
      camelName = toCamelCase baseName;
      importedFile = import (./. + "/${fileName}");
      args = if builtins.isFunction importedFile 
        then builtins.functionArgs importedFile 
        else {};
      value = if args ? pkgs
        then (overrides: importedFile (({
          inherit pkgs;
          stdenv = pkgs.stdenv;
        } // (builtins.intersectAttrs args pkgs)) // overrides))
        else importedFile;
    in pkgs.lib.nameValuePair camelName value)
    (pkgs.lib.filterAttrs (name: type: 
      type == "regular" && pkgs.lib.hasSuffix ".nix" name && name != "default.nix"
    ) (builtins.readDir ./.));
}

