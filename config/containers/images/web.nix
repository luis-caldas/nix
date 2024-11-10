{ baseImage, information, pkgs, ... }:

#######
# Web #
#######

# Function to create a website containers

# Once run the function will return a working container with the website

{
  name ? null,  # The image name
  url ? null,
  port ? 8080
}: let

  # Create the image name depending on the given name
  baseName = "${information.repo}/web";
  newName = if name == null then
    baseName
  else
    "${baseName}-${name}";

  # Set project root folder
  projectFolder = "/web";

  # Project from git if present
  gitProject = builtins.fetchGit url;

in pkgs.dockerTools.buildImage {

  # Naming
  name = newName;
  created = information.when;

  # Use the base image
  fromImage = baseImage;

  # Needed packages
  copyToRoot = with pkgs; [
    # HTTP Server
    nodePackages.http-server
  ];

  # Build the project with this script
  runAsRoot = ''
    #!${pkgs.bash}/bin/bash
  '' +
  # Check if we should just create the folder or clone the project
  (if url == null then ''

    # Create the project folder
    mkdir -p "${projectFolder}"

  '' else ''

    # Copy the git project
    cp -r "${gitProject}" "${projectFolder}"

  '');

  # The start command
  config.Cmd = [
    "${pkgs.nodePackages.http-server}/bin/http-server" "${projectFolder}" "-p" "${builtins.toString port}" "-i" "--log-ip" "-r" "--no-dotfiles"
  ];

}