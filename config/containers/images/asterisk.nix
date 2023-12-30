{ baseImage, pkgs, ... }:

############
# Asterisk #
############

# Asterisk telephony software

let

  # Chose the main package (version) to use
  asteriskPackage = pkgs.asterisk;

  # The path of the original files
  originalFiles = "${pkgs.reference.projects.containers}/build/asterisk/app";

in pkgs.dockerTools.buildImage {

  # Naming
  name = "local/asterisk";
  tag = "latest";

  # Base image
  fromImage = baseImage;

  # Construction script
  runAsRoot = ''
    #!${pkgs.bash}/bin/bash

    # Making sure default folders exist
    mkdir -p /etc /run /usr

    # Needed to exist directories
    mkdir -p /run/asterisk

    # Create the needed folders
    mkdir -p "/usr/lib/asterisk" \
             "/usr/share/asterisk"

    # Copy all the needed files
    cp -r "${originalFiles}/conf" "/etc/asterisk"
    cp -r "${originalFiles}/songs" "/usr/share/asterisk/songs"

    # Copy asterisk files to the proper folders
    cp -r "${asteriskPackage}/lib/asterisk/modules" "/usr/lib/asterisk/modules"
    cp -r "${asteriskPackage}/bin/." "/usr/sbin"

  '';

  # Needed packages
  copyToRoot = with pkgs; [

    # Asterisk
    asteriskPackage

    # For libraries and scripts
    perl sox mpg123

    # Email
    msmtp

  ];

  # Command line for startup
  config.Cmd = [
    "${asteriskPackage}/bin/asterisk"
    "-C" "/etc/asterisk/asterisk.conf"
    "-T" "-p" "-vvvvv" "-ddddd" "-f"
  ];

}