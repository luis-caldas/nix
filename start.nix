args@{ lib, config, pkgs, utils, stdenv, options, ... }:
let

  # Function for capitalizing name
  capitalizeFirst = eachName: let
    firstLetter = (builtins.substring 0 1 eachName);
  in
    (lib.toUpper firstLetter) + (lib.removePrefix firstLetter eachName);

  # My main config
  my = import ./config.nix { inherit lib; iso = false; };

  # My functions
  mfunc = import ./functions/func.nix { inherit lib; };

  # Home manager
  home-manager-project = let
    # Extract this version from nixpkgs
    versionList = lib.splitString "." lib.version;
    versionConcatenated = (
      builtins.elemAt versionList 0 +
      "." +
      builtins.elemAt versionList 1
    );
    # System Version
    version = versionConcatenated;
  in builtins.fetchGit {
    url = "https://github.com/rycee/home-manager";
    ref = "release-" + version;
  };
  home-manager = import "${home-manager-project}/nixos" args;
  home-manager-modules = import "${home-manager-project}/modules" { inherit pkgs lib; configuration = {}; };

  # Unstable packages
  upkgs = import
    (builtins.fetchGit "https://github.com/nixos/nixpkgs")
    { config = config.nixpkgs.config; };

  # My packages
  mpkgs = import ./pkgs/pkgs.nix { inherit pkgs upkgs; };
  mopts = import ./pkgs/options.nix (args // { inherit pkgs mpkgs upkgs; });

  # Create dict with wanted attrs
  wantedAttrs = { inherit mfunc upkgs mpkgs home-manager-modules; };

  # Function that create linker builders
  createLinker = myVar:
    import ./linker.nix (args // myVar // { oattrs = wantedAttrs; } );

  # Import the linker after configurations have been loaded
  linkerMain = createLinker { my = ( my // { name = capitalizeFirst my.path; }); };

  # Use other specializations
  otherLinkers = lib.listToAttrs (map (eachName:
  let
    capitalizedName = capitalizeFirst eachName;
    newMyVar = my // { config = my.extra."${eachName}"; name = capitalizedName; extra = null; };
    globalImport = createLinker { my = newMyVar; };
  in
    {
      name = eachName;
      value = {
        inheritParentConfig = false;
        configuration = {
          boot.loader.grub.configurationName = capitalizedName;
        } // globalImport;
      };
    })
  (builtins.attrNames my.extra));

in {

  # Add the specializations
  specialisation = builtins.trace otherLinkers otherLinkers;

} // linkerMain
