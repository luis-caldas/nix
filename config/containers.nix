{ my, pkgs, ... }:
let

  # Useful functions for creating containers
  functions = {

    # Function for adding files or directories to a container
    add = itemsList: let
      createEach = tupleIn: let
        originalPath = builtins.head tupleIn;
        destinationPath = pkgs.lib.last tupleIn;
      in ''
        base_dir="$("${pkgs.coreutils}/bin/dirname" "${destinationPath}")"
        "${pkgs.coreutils}/bin/mkdir" -p "$base_dir"
        "${pkgs.coreutils}/bin/rm" -r "${destinationPath}"
        "${pkgs.coreutils}/bin/cp" -r "${originalPath}" "${destinationPath}"
      '';
      fullScript = builtins.map createEach itemsList;
    in pkgs.writeScriptBin "build" ''
      #!${pkgs.bash}/bin/bash
      ${pkgs.lib.concatStrings fullScript}
    '';

    # Function to create directories
    create = itemsList: let
      fullScript = builtins.map (
        eachItem: ''
          "${pkgs.coreutils}/bin/mkdir" -p "${eachItem}"
        ''
      ) itemsList;
    in pkgs.writeScriptBin "build" ''
      #!${pkgs.bash}/bin/bash
      ${pkgs.lib.concatStrings fullScript}
    '';

    # Function to create directories
    touch = itemsList: let
      fullScript = builtins.map (
        eachItem: ''
          base_dir="$("${pkgs.coreutils}/bin/dirname" "${eachItem}")"
          "${pkgs.coreutils}/bin/mkdir" -p "$base_dir"
          "${pkgs.coreutils}/bin/touch" "${eachItem}"
        ''
      ) itemsList;
    in pkgs.writeScriptBin "build" ''
      #!${pkgs.bash}/bin/bash
      ${pkgs.lib.concatStrings fullScript}
    '';

  };

  # Container object
  allContainers = let

    # Base nixos with default tools
    baseImage = pkgs.dockerTools.buildImage {
      name = "local/base";
      tag = "latest";
      contents = with pkgs; [
        bash bashInteractive
        tree
        busybox coreutils
        curl wget
        gnugrep findutils moreutils util-linux
        cron openssl cacert
      ];
      config = {
        Env = [
          "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        ];
      };
    };

  in {

    # Python Scrape container
    pythonScrape = let

      # Default log files
      logFileScript = "/log/exec.log";
      logFileCron = "/log/cron.log";

      # Main application
      projectFull = pkgs.runCommand "add-folder" { project = builtins.fetchGit {
        url = "https://github.com/luis-caldas/get-weathers";
        ref = "master";
      };} ''
        mkdir -p "''${out}"
        cp -a "''${project}" "''${out}/main/"
      '';
      packagedPython = pkgs.python3.withPackages (pack: with pack; [
        fpdf requests
        beautifulsoup4
      ]);
      mainExec = pkgs.writeScriptBin "main" ''
        #!${pkgs.bash}/bin/bash
        cd "${projectFull}/main"
        "${packagedPython}/bin/python3" "main.py"
      '';
      cronFile = pkgs.writeTextFile {
        name = "cron"; destination = "/cron"; text = ''
          */1 * * * * "${mainExec}/bin/main" >> "${logFileScript}" 2>&1
        '';
      };

      # Build script for the image
      buildScript = let
        createBuild = functions.create [ "/var/spool/cron/crontabs" "/var/run" "/tmp" ];
        touchBuild = functions.touch [ logFileScript logFileCron ];
        addBuild = functions.add [[ "${cronFile}/cron" "/var/spool/cron/crontabs/root" ]];
      in pkgs.writeScriptBin "build" ''
        #!${pkgs.bash}/bin/bash
        "${createBuild}/bin/build"
        "${touchBuild}/bin/build"
        "${pkgs.coreutils}/bin/echo" 'root:x:0:0:root:/root:/bin/bash' > /etc/passwd
        "${addBuild}/bin/build"
      '';

      # Initialization script for the container
      initScript = pkgs.writeScriptBin "start" ''
        #!${pkgs.bash}/bin/bash

        # Variable that contains all the processes
        processes=()

        # Catch SIGTERMs
        _term() {
          for each_pid in ''${processes[@]}; do
            "${pkgs.util-linux}/bin/kill" -TERM "$each_pid" 2>/dev/null
          done
        }
        trap _term SIGTERM

        # Import ENVs to proper path
        "${pkgs.coreutils}/bin/printenv" | "${pkgs.gnugrep}/bin/grep" "SMTP\|SSL" > /etc/environment

        # Start cron process
        "${pkgs.busybox}/bin/crond" -f -l 0 -L /cron.log &
        processes+=("$!")

        # Tail log file
        "${pkgs.coreutils}/bin/tail" -fq "${logFileScript}" "${logFileCron}" &
        processes+=("$!")

        # Wait for all processes
        for pid in ''${processes[@]}; do
            wait "$pid"
        done
      '';

    in pkgs.dockerTools.buildImage {
      name = "local/python-scrape";
      tag = "latest";
      fromImage = baseImage;
      contents = [ initScript ];
      runAsRoot = "${buildScript}/bin/build";
      config = {
        Cmd = [
          "${pkgs.bash}/bin/bash" "${initScript}/bin/start"
        ];
      };
    };

    # Asterisk image
    asterisk = let
      asteriskPkg = pkgs.asterisk;
      buildPath = "${my.projects.containers}/build/asterisk/app";
      buildScript = let
        createBuild = functions.create [ "/run/asterisk" ];
        addBuild = functions.add [
          [ "${buildPath}/songs" "/usr/share/asterisk/songs" ]
          [ "${buildPath}/conf" "/etc/asterisk" ]
          [ "${buildPath}/phoneprov" "/var/lib/asterisk/phoneprov" ]
        ];
      in pkgs.writeScriptBin "build" ''
        #!${pkgs.bash}/bin/bash
        "${createBuild}/bin/build"
        "${addBuild}/bin/build"
      '';
    in pkgs.dockerTools.buildImage {
      name = "local/asterisk";
      tag = "latest";
      fromImage = baseImage;
      runAsRoot = "${buildScript}/bin/build";
      contents = with pkgs; [
        asteriskPkg
        perl sox mpg123
      ];
      config = {
        Cmd = [
          "${asteriskPkg}/bin/asterisk" "-C" "/etc/asterisk/asterisk.conf" "-T" "-p" "-vvv" "-f"
        ];
      };
    };

    # DNS updater image
    udns = let

      # Default log files
      logFileScript = "/log/exec.log";
      logFileCron = "/log/cron.log";

      # Default application
      mainExec = pkgs.writeScriptBin "main" ''
        #!${pkgs.bash}/bin/bash
        "${my.projects.containers}/build/update-dns/update_dns.sh"
      '';
      cronFile = pkgs.writeTextFile {
        name = "cron"; destination = "/cron"; text = ''
          */5 * * * * "${mainExec}/bin/main" >> "${logFileScript}" 2>&1
        '';
      };

      # Build script for the image
      buildScript = let
        createBuild = functions.create [
          "/var/cache/dns_updater" "/var/spool/cron/crontabs" "/var/run" "/tmp"
        ];
        touchBuild = functions.touch [ logFileScript logFileCron ];
        addBuild = functions.add [[ "${cronFile}/cron" "/var/spool/cron/crontabs/root" ]];
      in pkgs.writeScriptBin "build" ''
        #!${pkgs.bash}/bin/bash
        "${createBuild}/bin/build"
        "${touchBuild}/bin/build"
        "${pkgs.coreutils}/bin/echo" 'root:x:0:0:root:/root:/bin/bash' > /etc/passwd
        "${addBuild}/bin/build"
      '';

      # Initialization script for the container
      initScript = pkgs.writeScriptBin "start" ''
        #!${pkgs.bash}/bin/bash

        # Variable that contains all the processes
        processes=()

        # Catch SIGTERMs
        _term() {
          for each_pid in ''${processes[@]}; do
            "${pkgs.util-linux}/bin/kill" -TERM "$each_pid" 2>/dev/null
          done
        }
        trap _term SIGTERM

        # Import ENVs to proper path
        "${pkgs.coreutils}/bin/printenv" | "${pkgs.gnugrep}/bin/grep" "KEY\|SSL" > /etc/environment

        # Start cron process
        "${pkgs.busybox}/bin/crond" -f -l 0 -L /cron.log &
        processes+=("$!")

        # Tail log file
        "${pkgs.coreutils}/bin/tail" -fq "${logFileScript}" "${logFileCron}" &
        processes+=("$!")

        # Wait for all processes
        for pid in ''${processes[@]}; do
            wait "$pid"
        done
      '';

    in pkgs.dockerTools.buildImage {
      name = "local/udns";
      tag = "latest";
      fromImage = baseImage;
      contents = [ initScript ];
      runAsRoot = "${buildScript}/bin/build";
      config = {
        Cmd = [
          "${pkgs.bash}/bin/bash" "${initScript}/bin/start"
        ];
      };
    };

  };
in allContainers
