{ pkgs, lib, config, iso, ... }:
let

  # Default path for the chosen system that was set on a file
  systemName = lib.replaceStrings ["\n" " "] ["" ""] (builtins.readFile ./system);
  # Generate the net id from the system name
  systemId = builtins.substring 0 8 (builtins.hashString "sha512" systemName);

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
  in
    if builtins.elem arch (builtins.attrValues archReference) then
      lib.removeSuffix linuxSuffix pkgs.stdenv.system
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
        owner = owner-name;
        repo = eachProjectName;
        rev = allProjectsGitHub."${eachProjectName}".commit;
        sha256 = allProjectsGitHub."${eachProjectName}".sha256;
      };
    }

  ) allProjectNames);

  # Show some verbose
  printId = let
    verboseString = "building for ${systemName} @ ${systemArch} - ${config.system.nixos.release} - ${systemId}";
  in
    builtins.trace verboseString netId;

in {

  # Import all the default options
  imports = [

    # Defaults
    ../config/defaults.nix

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

        # My projects
        projects = myProjects;

        # Browser policies
        browser = chromiumPolicies;

      };

    })

  ];

}
