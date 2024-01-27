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

  # Get the system architecture and throw error if not supported
  systemArch = with pkgs.stdenv.hostPlatform; let
    # Test the supported systems
    supportedSystems = [
      # Test if x86
      isx86
      # Test if arm
      isAarch
    ];
    # Check if valid entry in the list
    valid = builtins.elem true supportedSystems;
  in if valid then
    parsed.cpu.arch
  else
    throw "The CPU architecture ${parsed.cpu.arch} is not supported";

  # Import all the extra configurations present
  extraConfigurations = let

    # Constants
    configurationsFolder = ../config/extra;
    extensions = ".json";

    # Get all the files in the directory with the extension
    allFiles = lib.attrsets.filterAttrs
      (name: value: value == "regular" && lib.strings.hasSuffix extensions name)
      (builtins.readDir configurationsFolder);

    # Read all the files to a big set
    allFilesContents = lib.attrsets.mapAttrs'
      (name: value:
        lib.attrsets.nameValuePair
        (lib.strings.removeSuffix extensions name)
        (builtins.fromJSON (builtins.readFile (configurationsFolder + ("/" + name))))
      )
      allFiles;

  in
    allFilesContents;

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
      value = pkgs.fetchFromGitHub {
        name = fixedName;
        owner = ownerName;
        repo = eachProjectName;
        rev = allProjects."${eachProjectName}".commit;
        sha256 = allProjects."${eachProjectName}".sha256;
      };
    }

  ) allProjectNames.projects);

  # Build the system path
  systemPath = ../systems + ("/" + systemName);
  # Save the name of the default file
  defaultSystemFile = "default.nix";

  # Create the verbose string
  verboseString = "building for ${systemName} @ ${systemArch} - ${systemVersion} - ${systemId}";

in {

  # Import all the default options
  imports = [

    # Defaults
    ../config/defaults.nix

    # Functions
    ../lib

    # Containers
    ../config/containers

    # Networking Information
    ../config/networks.nix

    # Extra packages and options
    ../pkgs

    # Import the default system file
    (systemPath + ("/" + defaultSystemFile))

  ];

  # Add all the configuration to an overlay
  nixpkgs.overlays = [

    # The overlay
    (final: prev: {

      # The new attribute with all the new information
      reference = builtins.trace verboseString {

        # System Id
        id = systemId;

        # Extra configurations that are easier to set with specific files
        more = extraConfigurations;

        # My projects
        projects = myProjects;

      };

    })

  ];

}
