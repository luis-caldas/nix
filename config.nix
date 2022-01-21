{ pkgs, lib, iso, ... }:
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
      let
        owner = "luis-caldas";
      in
        pkgs.fetchFromGitHub rec { inherit owner; inherit (projectData) repo rev sha256; name = replaceName repo; };

  # Link all my projects to the config
  listSomeProjects = {
    "myconky"      = { rev = "1b494d50c2bd789250841dcc54aaf733ebc84550"; sha256 = "06arv0a3i1q1ya5i38y55qc0zs96v7mqkkr5ha6aih6xj92yj6cx"; };
    "mycursors"    = { rev = "42b16a3d8b2af5b45ca57df3e4e0c07bd5cd19e9"; sha256 = "10nzdpdvp4pwz3w2z980v137yzdj8qwhkr2fwz46vram9400xfv7"; };
    "myfonts"      = { rev = "3623109a3f342622db3f9a42bf906b898777abe2"; sha256 = "1rlb6wf5i4vvcc4m29796kr18zxi9040x21in0kf4kppmzxliy94"; };
    "myicons"      = { rev = "fd4692ed166aab23865a45ee154bf23cadb843e9"; sha256 = "017pqsqhln6hjs2ini4f9fabf7smj628dyavr2w7566vv13hqni6"; };
    "myshell"      = { rev = "3ef9ca1b06141eda5f25a65293e9c319c81ba286"; sha256 = "0md3sg8s9a1gxb49c08x243b3l7galz8qalp7ibx28ghfgx6cy0p"; };
    "mythemes"     = { rev = "e55cec84f30af58e2aa36af3145167167cc9fce4"; sha256 = "1kfwqwpai0yk2i4xq5zgvfy7s5gxbvy5ckqsq3ai6ppz5f4pb2is"; };
    "myvim"        = { rev = "4469988257a52021d98486d9bc053f582f28b97e"; sha256 = "0g30vjzqmhb7i0kcz8nrgbhw5xx4lfh6fn0hspdd7dcx7x10qfc1"; };
    "mywallpapers" = { rev = "4c9dcbe6f58a123dacb7bc9d10f95761efb4e642"; sha256 = "0j5dym6a10xxqxd6mpqsssbc3wd77hkv29yf6agh6wg7yfjck5rk"; };
  };
  someProjects = builtins.listToAttrs (map (
    eachProjectName: {
      name = replaceName eachProjectName;
      value = fetchProject {
        repo = eachProjectName;
        inherit (listSomeProjects."${eachProjectName}") rev sha256;
      };
    }
  ) (builtins.attrNames listSomeProjects));

  # Ovewrite desktop project with derivated subfolders
  desktopProject = let
    myProject = {
      repo = "mydesktop";
      rev = "0452a87a9b5d34739d95fce29a7525b886a7e6a3";
      sha256 = "0racf0jag763v9p6lm3y7x4fpxbpx9k1w9wjbb62b5fs3y4x1qqw";
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
    verboseString = "building for " + realName + " with ID " + netId;
  in
    builtins.trace verboseString netId;

in
{
  id = traceId;
  path = realName;
  config = configObj;
  chromium = chromiumObj;
  projects = someProjects // desktopProject;
}
