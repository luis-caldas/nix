{ pkgs, lib, config, ... }:
let

  # Default path for the chosen system that was set on a file
  systemName = lib.replaceStrings ["\n" " "] ["" ""] (builtins.readFile ../system);
  # Generate the net id from the system name
  systemId = builtins.substring 0 8 (builtins.hashString "sha512" systemName);

  # Get the system version
  systemVersion = config.system.nixos.release;

  # The owner name
  ownerName = "luis-caldas";

  # Create list for allowed architectures and equivalent strings
  archReference = {
    x64 = "x86_64";
    x86 = "i686";
    arm = "aarch64";
  };

  # Get the system architecture and throw error if not supported
  systemArch = let
    linuxSuffix = "-linux";
    arch = lib.removeSuffix linuxSuffix pkgs.stdenv.system;
  in
    if builtins.elem arch (builtins.attrValues archReference) then
      arch
    else
      throw "Unsupported architecture ${arch}";

  # Import the browser config
  chromiumPolicies = builtins.fromJSON (builtins.readFile (../config/browser + "/chromium.json"));

  # Extract only the needed projects
  myProjects = let

    # The list of the projects and hashes
    allProjects = builtins.fromJSON (builtins.readFile (../config/projects + "/hashes.json"));
    # The list of project names
    allProjectNames = builtins.fromJSON (builtins.readFile (../config/projects + "/list.json"));

  in builtins.listToAttrs (map (
    eachProjectName: let

      # Remove the my from the name to make it easier
      fixedName = lib.replaceStrings [ "my" ] [ "" ] eachProjectName;

    in {
      name = fixedName;
      value = pkgs.fetchFromGithub {
        owner = ownerName;
        repo = eachProjectName;
        rev = allProjects."${eachProjectName}".commit;
        sha256 = allProjects."${eachProjectName}".sha256;
      };
    }

  ) allProjectNames);

  # Build the system path
  systemPath = ../systems + ("/" + systemName);
  # Save the name of the default file
  defaultSystemFile = "default.nix";
  # Save all the extra files in the directory
  extraSpecialisations = let
    # All directory structures
    dirStructures = builtins.readDir systemPath;
    # All file structures
    fileStructures = lib.attrsets.filterAttrs (name: value: value == "regular") dirStructures;
    # All the file names
    filesListAll = builtins.attrNames fileStructures;
    # Files list
    filesList = lib.lists.remove defaultSystemFile filesListAll;
  in
    filesList;

  # Show some verbose
  printId = let
    verboseString = "building for ${systemName} @ ${systemArch} - ${systemVersion} - ${systemId}";
  in
    builtins.trace verboseString systemId;

in {

  # Import all the default options
  imports = [

    # Defaults
    ../config/defaults.nix

    # Functions
    ../lib/functions.nix

    # Import the default system file
    (systemPath + ("/" + defaultSystemFile))

  ];

  # Add all the configuration to an overlay
  nixpkgs.overlays = [

    # The overlay
    (final: prev: {

      # The new attribute with all the new information
      reference = {

        # System Id
        id = printId;

        # System architecture and reference
        arch = systemArch;
        arches = archReference;

        # Browser policies
        browser = chromiumPolicies;

        # My projects
        projects = myProjects;

        # Extra file paths
        extras = extraSpecialisations;

      };

    })

  ];

}
