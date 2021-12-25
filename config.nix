{ pkgs, lib, iso, ... }:
let

  # Default path for the chosen system that was set on a file
  system-name = lib.replaceStrings ["\n" " "] ["" ""] (builtins.readFile ./system);

  # Check if it is a iso and set the correct path then
  real-name = if iso then
    "iso"
  else
    system-name;

  # Generate the net id from the system name
  net-id = builtins.substring 0 8 (builtins.hashString "sha512" real-name);

  # Import the chosen config file
  config-obj = lib.recursiveUpdate
    (builtins.fromJSON (
       builtins.readFile (./config + "/default.json"))
    )
    (builtins.fromJSON (
       builtins.readFile (./config + ("/" + real-name) + "/config.json"))
    );

  # Import the browser config
  chromium-obj = builtins.fromJSON (builtins.readFile (./config + "/chromium.json"));

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

in
{
  id = net-id;
  path = real-name;
  config = config-obj;
  chromium = chromium-obj;
  projects = someProjects // desktopProject;
}
