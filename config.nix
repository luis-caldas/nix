{ pkgs, lib, config, iso, ... }:
let

  # Default path for the chosen system that was set on a file
  systemName = lib.replaceStrings ["\n" " "] ["" ""] (builtins.readFile ./system);

  # Extract this version from nixpkgs
  versionList = lib.splitString "." lib.version;
  versionConcatenated = (
    builtins.elemAt versionList 0 +
    "." +
    builtins.elemAt versionList 1
  );

  # System Version
  version = versionConcatenated;

  # Get the state version from the systems options
  state = config.system.stateVersion;

  # Create list for allowed architectures
  archReference = {
    "x64" = "x86_64";
    "x86" = "i686";
    "arm" = "aarch64";
  };
  allowedArchitectures = builtins.attrValues archReference;

  # Check for system architecture
  sysArch = let
    sysFull = pkgs.stdenv.system;
    linuxSuffix = "-linux";
    arch = lib.removeSuffix linuxSuffix sysFull;
  in
    if builtins.elem arch allowedArchitectures then
      arch
    else
      throw "Unsupported architecture ${arch}";

  # Owner name
  owner = "luis-caldas";

  # Check if it is a iso and set the correct path then
  realName = if iso then
    "iso"
  else
    systemName;

  # Generate the net id from the system name
  netId = builtins.substring 0 8 (builtins.hashString "sha512" realName);

  # Name for the filer group
  filer = "filer";

  # Import the chosen config file
  configObj = lib.recursiveUpdate
    (builtins.fromJSON (
       builtins.readFile (./config + "/default.json"))
    )
    (builtins.fromJSON (
       builtins.readFile (./config + ("/" + realName) + "/config.json"))
    );

  # Import the browser config
  chromiumObj = builtins.fromJSON (builtins.readFile (./config + "/chromium.json"));

  # Replace name function
  replaceName = projectName: (lib.replaceStrings [ "my" ] [ "" ] projectName);

  # Create fetch project function
  fetchProject =
    projectData:
      pkgs.fetchFromGitHub rec { inherit owner; inherit (projectData) repo rev sha256; name = replaceName repo; };

  # Load list of all projects
  allProjectsGitHub = builtins.fromJSON (builtins.readFile (./config + "/projects.json"));

  # Link all my projects to the config
  listSomeProjects = builtins.fromJSON (builtins.readFile (./config + "/my.json"));

  # Extract only the needed projects
  someProjects = builtins.listToAttrs (map (
    eachProjectName: {
      name = replaceName eachProjectName;
      value = fetchProject {
        repo = eachProjectName;
        rev = allProjectsGitHub."${eachProjectName}".commit;
        sha256 = allProjectsGitHub."${eachProjectName}".sha256;
      };
    }
  ) listSomeProjects.projects);

  # Ovewrite desktop project with derivated subfolders
  desktopProject = let
    myProject = rec {
      repo = "mydesktop";
      rev = allProjectsGitHub."${repo}".commit;
      sha256 = allProjectsGitHub."${repo}".sha256;
    };
    fixedName = replaceName myProject.repo;
    fetchedProject = fetchProject myProject;
    subFolders = lib.remove null (lib.mapAttrsToList (
      name: value:
        if ((value == "directory") && ((builtins.substring 0 1 name) != ".")) then
          name
        else
          null
      ) (builtins.readDir fetchedProject));
  in
  {
    "${fixedName}" = builtins.listToAttrs (map (
      eachFolder:
      {
        name = eachFolder;
        value = "${fetchedProject}/${eachFolder}";
      }
    ) subFolders);
  };

  # Show some verbose
  traceId = let
    verboseString = "building for ${realName} @ ${sysArch} - ${version} - ${netId}";
  in
    builtins.trace verboseString netId;

  # Create the entire object
  mySome = {
    id = traceId;
    arch = sysArch;
    path = realName;
    filer = filer;
    config = configObj;
    state = state;
    version = version;
    chromium = chromiumObj;
    reference = archReference;
    projects = someProjects // desktopProject;
    containers = containerObj;
  };

  # Get container configs
  containerObj = import (./config + ("/containers.nix")) { inherit pkgs config; my = mySome; };

  # Add the containers to the entire list
  myAll = mySome // { containers = containerObj; };

in myAll
