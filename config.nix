{ pkgs, lib, iso, ... }:
let

  # Default path for the chosen system that was set on a file
  systemName = lib.replaceStrings ["\n" " "] ["" ""] (builtins.readFile ./system);

  # Owner name
  owner = "luis-caldas";

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
      pkgs.fetchFromGitHub rec { inherit owner; inherit (projectData) repo rev sha256; name = replaceName repo; };

  # Link all my projects to the config
  listSomeProjects = {
    "myconky"      = { rev = "449efb4b888f6843ea3fe6507e96a2ae720e7159"; sha256 = "1gsnq6g34f7gv43gqv8iw8kc52m3y70s2zbf7lnq4ds2zj1ijmhq"; };
    "mycursors"    = { rev = "42b16a3d8b2af5b45ca57df3e4e0c07bd5cd19e9"; sha256 = "10nzdpdvp4pwz3w2z980v137yzdj8qwhkr2fwz46vram9400xfv7"; };
    "myfonts"      = { rev = "b2536dff328409cd7b42422cfbdadb92dba28bdc"; sha256 = "0vbgxzyimp90d0izwg4s3g4f6dl1d8c2chb869s2fynp9z2jfrf0"; };
    "myicons"      = { rev = "fd4692ed166aab23865a45ee154bf23cadb843e9"; sha256 = "017pqsqhln6hjs2ini4f9fabf7smj628dyavr2w7566vv13hqni6"; };
    "myshell"      = { rev = "bfa4f93f7f0fff7bdb56fea3c6baf778f7bdb924"; sha256 = "1maaskw7rv7ks11inhi5viih6gkyr2p0d08mvvn9jkbjnaxnp17y"; };
    "mythemes"     = { rev = "e55cec84f30af58e2aa36af3145167167cc9fce4"; sha256 = "1kfwqwpai0yk2i4xq5zgvfy7s5gxbvy5ckqsq3ai6ppz5f4pb2is"; };
    "myvim"        = { rev = "4469988257a52021d98486d9bc053f582f28b97e"; sha256 = "0g30vjzqmhb7i0kcz8nrgbhw5xx4lfh6fn0hspdd7dcx7x10qfc1"; };
    "mywallpapers" = { rev = "42fb2fe79306bf3be52027ea740d53fa19e838af"; sha256 = "10ywkzpigkqk8a040hifqkkndc9cf3sjrdzw8f5lh6v05vbfl2fd"; };
    "mycontainers" = { rev = "09af6d18ca3686bef587921e4f6d03e53883b5c2"; sha256 = "0bgaq8pihnvhpy3jnfw4kfffg86ils8r0w2aybkpsnz2jdv9i2mv"; };
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
      rev = "fdbe0bcb653368e42a82fc3b21c2fd5e27769a27";
      sha256 = "16f4f3dj7cnbw3xfhg9hnzdzfmn6fai2x52p33hc9pacmva0idrm";
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

  # Create the entire object
  mySome = {
    id = traceId;
    path = realName;
    config = configObj;
    chromium = chromiumObj;
    projects = someProjects // desktopProject;
    containers = containerObj;
  };

  # Get container configs
  containerObj = import (./config + ("/containers.nix")) { inherit pkgs; my = mySome; };

  # Add the containers to the entire list
  myAll = mySome // { containers = containerObj; };

in myAll
