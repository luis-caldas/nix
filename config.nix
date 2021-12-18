{ lib, iso, ... }:
let

  # Default path for the chosen system that was set on a file
  systemName = lib.replaceStrings ["\n" " "] ["" ""] (builtins.readFile ./system);

  # Check if it is a iso and set the correct path then
  realName = if iso then
    "iso"
  else
    systemName;

  # Generate the net id from the system name
  netId = builtins.substring 0 8 (builtins.hashString "sha512" realName);

  # Recursively update config list with default
  overlayDefault = filePath:
    lib.recursiveUpdate
      (builtins.fromJSON (
         builtins.readFile (./config + "/default.json"))
      )
      (builtins.fromJSON (
         builtins.readFile filePath)
      );

  # Import the chosen config file
  configObj = overlayDefault (./config + ("/" + realName) + "/config.json");

  # Import the browser config
  chromiumObj = builtins.fromJSON (builtins.readFile (./config + "/chromium.json"));

  # Replace name function
  replaceName = projectName: (lib.replaceStrings [ "my" ] [ "" ] projectName);

  # Create fetch project function
  fetchProject =
    projectName:
      let
        githubUrlBuilder = userString: repoString:
        let
          protocol = "https";
          domain = "github.com";
        in
          protocol + "://" + domain + "/" + userString + "/" + repoString;
      in
        builtins.fetchGit (githubUrlBuilder "luis-caldas" projectName);

  # Link all my projects to the config
  listProjects = [
    "myconky"
    "mythemes"
    "myfonts"
    "mycursors"
    "myicons"
    "mywallpapers"
    "myshell"
    "myvim"
  ];
  someProjects = builtins.listToAttrs (map (
    eachProject: { name = (replaceName eachProject); value = (fetchProject eachProject); }
  ) listProjects);

  # Ovewrite desktop project with derivated subfolders
  desktopProject = let
    myProject = "mydesktop";
    fixedName = replaceName myProject;
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

  # Create part of the last object
  objectPart = {
    id = netId;
    path = realName;
    config = configObj;
    chromium = chromiumObj;
    projects = someProjects // desktopProject;
  };

  # Import extra configurations if any
  extraConfigs = let
    configFolder = ./config + ("/" + realName);
    filePrefix = "config-";
    fileSuffix = ".json";
    folderContents = builtins.readDir configFolder;
    nameList = lib.remove null (lib.mapAttrsToList (
      name: value:
        if ((lib.hasPrefix filePrefix name) &&
            (lib.hasSuffix fileSuffix name)
           ) then
          lib.removePrefix filePrefix (lib.removeSuffix fileSuffix name)
        else
          null
      ) folderContents);
  in
    lib.listToAttrs (map (
      eachName: {
        name = eachName;
        value = overlayDefault (configFolder + ("/" + filePrefix + eachName + fileSuffix));
      }
    ) nameList);

in (objectPart // { extra = extraConfigs; })
