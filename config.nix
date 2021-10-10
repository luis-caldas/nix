{ lib, iso, ... }:
let

  # Default path for the chosen system that was set on a file
  path-file = lib.replaceStrings ["\n" " "] ["" ""] (builtins.readFile ./system);

  # Check if it is a iso and set the correct path then
  system-path = if iso then
    "iso"
  else
    path-file;

  # Import the chosen config file
  config-obj = lib.recursiveUpdate
    (builtins.fromJSON (
       builtins.readFile (./config + "/default.json"))
    )
    (builtins.fromJSON (
       builtins.readFile (./config + ("/" + system-path) + "/config.json"))
    );

  # Import the browser config
  chromium-obj = builtins.fromJSON (builtins.readFile (./config + "/chromium.json"));

  # Link all my projects to the config
  listProjects = [
    "mydesktop"
    "myconky"
    "mythemes"
    "myfonts"
    "mycursors"
    "myicons"
    "mywallpapers"
    "myshell"
    "myvim"
  ];
  projects-obj = builtins.listToAttrs (
    map (
      projectName:
      let
        newProjectName = (lib.replaceStrings [ "my" ] [ "" ] projectName);
        githubUrlBuilder = userString: repoString:
        let
          protocol = "https";
          domain = "github.com";
        in
          protocol + "://" + domain + "/" + userString + "/" + repoString;
      in {
        name = newProjectName;
        value = builtins.fetchGit (githubUrlBuilder "luis-caldas" projectName);
      }
    ) listProjects
  );

in
{
  path = system-path;
  config = config-obj;
  chromium = chromium-obj;
  projects = projects-obj;
}
