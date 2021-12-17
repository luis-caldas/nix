args@{ lib, config, pkgs, utils, stdenv, ... }:
let

  # My main config
  my = import ./config.nix { inherit lib pkgs; iso = false; };

  # Import the linker after configurations have been loaded
  linker = import ./linker.nix ( { inherit my; } // args );

  # Use other specializations
  otherLinkers = lib.listToAttrs (map (eachName:
  let
    firstLetter = (builtins.substring 0 1 eachName);
    capitalizedName = (lib.toUpper firstLetter) + (lib.removePrefix firstLetter eachName);
  in
    {
      name = eachName;
      value = {
        inheritParentConfig = false;
        configuration = {
          boot.loader.grub.configurationName = capitalizedName;
          imports = [ (import ./linker.nix ( { my = my.extra."${eachName}"; } // args )) ]; };
      };
    })
  (builtins.attrNames my.extra));

in {

  # Add the system import list
  imports = [ linker ];

  # Add the specializations
  specialisation = otherLinkers;

}
