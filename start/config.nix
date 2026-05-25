{ pkgs, lib, config, ... }:
let

  # Default path for the chosen system file
  systemName = lib.replaceStrings ["\n" " "] ["" ""] (builtins.readFile ../system);
  # Generate the network ID from the system name
  systemId = builtins.substring 0 8 (builtins.hashString "sha512" systemName);

  # Get the system version
  systemVersion = config.system.nixos.release;

  # The owner name
  ownerName = "luis-caldas";

  # Get the unstable nixpkgs
  unstablePkgs = import
    (builtins.fetchTarball { url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz"; })
    {
      inherit (pkgs.stdenv.hostPlatform) system;
      config = config.nixpkgs.config;
    };

  # Get the system architecture and throw an error if it is not supported
  systemArch = with pkgs.stdenv.hostPlatform; let
    # Test the supported systems
    supportedSystems = [
      # Test if x86
      isx86
      # Test if arm
      isAarch
    ];
    # Check whether the entry is valid
    valid = builtins.elem true supportedSystems;
  in if valid then
    parsed.cpu.arch
  else
    throw "The CPU architecture ${parsed.cpu.arch} is not supported";

  # Import all extra configuration files
  extraConfigurations = let

    # Constants
    configurationsFolder = ../config/extra;
    extensions = ".json";

    # Get all the files in the directory with the extension
    allFiles = lib.attrsets.filterAttrs
      (name: value: value == "regular" && lib.strings.hasSuffix extensions name)
      (builtins.readDir configurationsFolder);

    # Read all files into a large attribute set
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

    # List of projects and hashes
    allProjects = builtins.fromJSON (builtins.readFile (../config/projects + "/hashes.json"));
    # List of project names
    allProjectNames = builtins.fromJSON (builtins.readFile (../config/projects + "/list.json"));

  in builtins.listToAttrs (map (
    eachProjectName: let

      # Remove only a leading "my" from the name
      fixedName =
        if lib.strings.hasPrefix "my" eachProjectName then
          lib.strings.removePrefix "my" eachProjectName
        else
          eachProjectName;

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

  # My own keys
  keys = let
    all = pkgs.fetchurl {
      url = "https://github.com/${ownerName}.keys";
      hash = "sha256-wlZp/obXRKqMlt0WfLNYZZgT2OSPeDTpmR4NE6eVHK8=";
    };
  in
    builtins.filter (k: k != "")
      (lib.splitString "\n" (builtins.readFile all));

  # Font configurations
  fonts = rec {
    package = pkgs.courier-prime;
    file = "${package}/share/fonts/truetype/CourierPrime-Bold.ttf";
    name = "Courier Prime";
  };

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

    # Networking information
    ../config/networks.nix

    # Extra packages and options
    ../pkgs

    # Import the default system file
    (systemPath + ("/" + defaultSystemFile))

  ];

  # Set the default hostname
  mine.system.hostname = lib.mkDefault systemName;

  # Show the build message
  warnings = [ verboseString ];

  # Add all the configuration to an overlay
  nixpkgs.overlays = [

    # The overlay
    (final: prev: {

      # New attribute containing the generated information
      reference = {

        # System ID
        id = systemId;

        # Extra configurations that are easier to set with specific files
        more = extraConfigurations // { inherit fonts; };

        # My projects
        projects = myProjects;

        # Owner name
        owner = ownerName;

        # Keys
        inherit keys;

      };

      # Unstable packages
      unstable = unstablePkgs;

    })

  ];

}
