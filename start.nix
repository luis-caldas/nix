args@{ lib, config, pkgs, utils, stdenv, ... }:
let

  # My main config
  my = import ./config.nix { inherit lib; iso = false; };

  # Import the linker after configurations have been loaded
  linker = import ./linker.nix ( args // { inherit my; } );

  # Use other specializations
  otherLinkers = lib.listToAttrs (map (eachName:
  let
    firstLetter = (builtins.substring 0 1 eachName);
    capitalizedName = (lib.toUpper firstLetter) + (lib.removePrefix firstLetter eachName);
    newMyVar = my // { config = my.extra."${eachName}"; extra = {}; };
    builtArgs = (args // { my = newMyVar; });
    globalImport = import ./linker.nix builtArgs;
  in
    {
      name = eachName;
      value = {
        inheritParentConfig = false;
        configuration = {
          boot.loader.grub.configurationName = capitalizedName;
          imports = [ globalImport ];
        };
      };
    })
  (builtins.attrNames my.extra));

in {

  # Add the system import list
  imports = [ linker ];

  # Add the specializations
  specialisation = otherLinkers;

}
