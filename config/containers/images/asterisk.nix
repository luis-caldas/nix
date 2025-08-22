{ baseImage, information, pkgs, ... }:

############
# Asterisk #
############

# Asterisk telephony software

let

  # Chose the main package (version) to use
  asteriskPackage = pkgs.asterisk;

  # The path of the original files
  originalFiles = "${pkgs.reference.projects.containers}/build/asterisk/app";

  # Create the execution script
  executionScript = pkgs.writeScript "starter" ''
    #!${pkgs.bash}/bin/bash

    # Iterate over each file and link it
    for path in /usr/share/asterisk/conf/*; do

      file="$(basename "$path")"

      # If not already present
      if [ ! -f "/etc/asterisk/$file" ]; then

        # Check if user provided
        if [ -f "/conf/$file" ]; then
          ln -s "/conf/$file" "/etc/asterisk/."
        else
          ln -s "$path" "/etc/asterisk/."
        fi

      fi

    done

    # Start service
    "asterisk" "-C" "/etc/asterisk/asterisk.conf" "-T" "-p" "-vvvvv" "-ddddd" "-f"

  '';

  # Asterisk paths
  defaultConfig = pkgs.writeText "asterisk.conf" ''
    [directories]
        astetcdir => /etc/asterisk
        astmoddir => /usr/lib/asterisk/modules
        astvarlibdir => /var/lib/asterisk
        astdbdir => /var/lib/asterisk
        astkeydir => /var/lib/asterisk
        astdatadir => /var/lib/asterisk
        astagidir => /var/lib/asterisk/agi-bin
        astspooldir => /var/spool/asterisk
        astrundir => /var/run/asterisk
        astlogdir => /var/log/asterisk
        astsbindir => /usr/sbin

    [options]
        documentation_language = en_US
  '';

in pkgs.dockerTools.buildImage {

  # Naming
  name = "${information.repo}/asterisk";
  created = information.when;

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

    # Move original files
    mkdir -p "/usr/share/asterisk"
    mv "/etc/asterisk" "/usr/share/asterisk/conf"

    # Change default config
    mkdir -p "/etc/asterisk"
    cp "${defaultConfig}" "/etc/asterisk/asterisk.conf"

    # Copy all the needed files
    cp -a "${originalFiles}/songs" "/usr/share/asterisk/songs"

    # Copy asterisk files to the proper folders
    cp -a "${asteriskPackage}/lib/asterisk/modules" "/usr/lib/asterisk/modules"
    cp -a "${asteriskPackage}/bin/." "/usr/sbin"

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
  config.Cmd = [ "${executionScript}" ];

}