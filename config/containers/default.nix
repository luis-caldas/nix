{ pkgs, lib, config, ... }:
let

  # All my custom built containers in nix format
#  allContainers = let
#
#
#  in {

#    # Asterisk image
#    asterisk = let
#      asteriskPkg = pkgs.asterisk;
#      buildPath = "${pkgs.reference.projects.containers}/build/asterisk/app";
#      buildScript = let
#        createBuild = functions.create [ "/run/asterisk" ];
#        addBuild = functions.add [
#          [ "${buildPath}/songs" "/usr/share/asterisk/songs" ]
#          [ "${buildPath}/conf" "/etc/asterisk" ]
#          [ "${buildPath}/phoneprov" "/var/lib/asterisk/phoneprov" ]
#          [ "${asteriskPkg}/lib/asterisk/modules" "/usr/lib/asterisk/modules" ]
#          [ "${asteriskPkg}/bin" "/usr/sbin" ]
#        ];
#      in pkgs.writeScriptBin "build" ''
#        #!${pkgs.bash}/bin/bash
#        "${createBuild}/bin/build"
#        "${addBuild}/bin/build"
#      '';
#    in pkgs.dockerTools.buildImage {
#      name = "local/asterisk";
#      tag = "latest";
#      fromImage = baseImage;
#      runAsRoot = "${buildScript}/bin/build";
#      copyToRoot = with pkgs; [
#        asteriskPkg
#        perl sox mpg123
#        msmtp
#      ];
#      config.Cmd = [ "${asteriskPkg}/bin/asterisk" "-C" "/etc/asterisk/asterisk.conf" "-T" "-p" "-vvvvv" "-ddddd" "-f" ];
#    };
#
#    # Static website with given url
#    web = { name ? null, url ? null }: let
#      # Decide name
#      baseName = "local/web";
#      givenName = if name == null then baseName else "${baseName}-${name}";
#      # Get website
#      website = if url == null then null else builtins.fetchGit { inherit url; ref = "master"; };
#      # Set root folder
#      rootFolder = "/web";
#      # Build script for the image
#      buildScript = let
#        createBuild = functions.create [ rootFolder ];
#      in pkgs.writeScriptBin "build" (''
#        #!${pkgs.bash}/bin/bash
#      '' + (if website == null then ''
#        "${createBuild}/bin/build"
#      '' else ''
#        "${pkgs.coreutils}/bin/cp" -r "${website}" "${rootFolder}"
#      ''));
#    in pkgs.dockerTools.buildImage {
#      name = givenName;
#      tag = "latest";
#      fromImage = baseImage;
#      copyToRoot = with pkgs; [ nodePackages.http-server ];
#      runAsRoot = "${buildScript}/bin/build";
#      config.Cmd = [
#        "${pkgs.nodePackages.http-server}/bin/http-server" "${rootFolder}"
#        "-p" "8080" "-i" "--log-ip" "-r" "--no-dotfiles"
#      ];
#    };
#
#    # DNS updater image
#    udns = let
#      # Default log files
#      logFileScript = "/log/exec.log";
#      logFileCron = "/log/cron.log";
#      # Default application
#      mainExec = pkgs.writeScriptBin "main" ''
#        #!${pkgs.bash}/bin/bash
#        "${pkgs.bash}/bin/bash" "${pkgs.reference.projects.containers}/build/update-dns/update_dns.sh"
#      '';
#      cronFile = pkgs.writeTextFile {
#        name = "cron"; destination = "/cron"; text = ''
#          */5 * * * * "${mainExec}/bin/main" >> "${logFileScript}" 2>&1
#        '';
#      };
#      # Build script for the image
#      buildScript = let
#        createBuild = functions.create [
#          "/var/cache/dns_updater" "/var/spool/cron/crontabs" "/var/run" "/tmp"
#        ];
#        touchBuild = functions.touch [ logFileScript logFileCron ];
#        addBuild = functions.add [[ "${cronFile}/cron" "/var/spool/cron/crontabs/root" ]];
#      in pkgs.writeScriptBin "build" ''
#        #!${pkgs.bash}/bin/bash
#        "${createBuild}/bin/build"
#        "${touchBuild}/bin/build"
#        "${pkgs.coreutils}/bin/echo" 'root:x:0:0:root:/root:/bin/bash' > /etc/passwd
#        "${addBuild}/bin/build"
#      '';
#      # Initialization script for the container
#      initScript = pkgs.writeScriptBin "start" ''
#        #!${pkgs.bash}/bin/bash
#        # Import ENVs to proper path
#        "${pkgs.coreutils}/bin/printenv" | "${pkgs.gnugrep}/bin/grep" "KEY\|SSL" > /etc/environment
#        # Start cron process
#        "${pkgs.busybox}/bin/crond" -f -l 0 -L /cron.log &
#        # Tail log file
#        "${pkgs.coreutils}/bin/tail" -fq "${logFileScript}" "${logFileCron}" &
#        # Wait for all processes
#        wait
#      '';
#    in pkgs.dockerTools.buildImage {
#      name = "local/udns";
#      tag = "latest";
#      fromImage = baseImage;
#      copyToRoot = [ initScript ];
#      runAsRoot = "${buildScript}/bin/build";
#      config.Cmd = [ "${pkgs.tini}/bin/tini" "${initScript}/bin/start" ];
#    };



#  };

  # A base image for all the custom images that will be built on top of it
  baseImage = pkgs.dockerTools.buildImage {

    # Names
    name = "local/base";
    tag = "latest";

    # Packages needed for the image
    copyToRoot = with pkgs; [
      tini
      bash bashInteractive
      tree
      busybox coreutils
      curl wget
      gnugrep findutils moreutils util-linux
      cron openssl cacert
    ];

    # Script to run at the start as root
    runAsRoot = ''
      #!${pkgs.bash}/bin/bash
      mkdir -p /tmp
      ln -s /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
    '';

    # Environment variables for the image
    config.Env = [
      "TZ=${config.mine.system.timezone}"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];

  };

  # Path to all the images
  imagesPath = ./images;

  # Create a list with all the image files for each container
  allImages = builtins.attrNames (
    lib.attrsets.filterAttrs (name: value: value == "regular") (builtins.readDir imagesPath)
  );

in {

  imports = [

    # Import all the relative functions
    ./functions.nix

  ];

  # The functions to the overlay
  nixpkgs.overlays = [

    # The overlay
    (final: prev: {

      # All the images
      container.images = builtins.listToAttrs (map (eachFile: {
        name = lib.strings.removeSuffix ".nix" eachFile;
        value = import (imagesPath + ("/" + eachFile)) { inherit baseImage pkgs; };
      }) allImages);

    })

  ];

}
