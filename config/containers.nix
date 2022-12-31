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
        [ -e "${destinationPath}" ] && "${pkgs.coreutils}/bin/rm" -r "${destinationPath}"
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
    baseImage = let
      buildScript = pkgs.writeScriptBin "build" ''
        #!${pkgs.bash}/bin/bash
        ${pkgs.coreutils}/bin/mkdir /tmp
        ${pkgs.coreutils}/bin/ln -s /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
      '';
    in pkgs.dockerTools.buildImage {
      name = "local/base";
      tag = "latest";
      runAsRoot = "${buildScript}/bin/build";
      copyToRoot = with pkgs; [
        tini
        bash bashInteractive
        vim
        tree
        busybox coreutils
        curl wget
        gnugrep findutils moreutils util-linux
        cron openssl cacert
      ];
      config.Env = [ "TZ=${my.config.system.timezone}" "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
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
        # Import ENVs to proper path
        "${pkgs.coreutils}/bin/printenv" | "${pkgs.gnugrep}/bin/grep" "SMTP\|SSL" > /etc/environment
        # Start cron process
        "${pkgs.busybox}/bin/crond" -f -l 0 -L /cron.log &
        # Tail log file
        "${pkgs.coreutils}/bin/tail" -fq "${logFileScript}" "${logFileCron}" &
        # Wait for all processes
        wait
      '';

    in pkgs.dockerTools.buildImage {
      name = "local/python-scrape";
      tag = "latest";
      fromImage = baseImage;
      copyToRoot = [ initScript ];
      runAsRoot = "${buildScript}/bin/build";
      config.Cmd = [ "${pkgs.tini}/bin/tini" "${initScript}/bin/start" ];
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
          [ "${asteriskPkg}/lib/asterisk/modules" "/usr/lib/asterisk/modules" ]
          [ "${asteriskPkg}/bin" "/usr/sbin" ]
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
      copyToRoot = with pkgs; [
        asteriskPkg
        perl sox mpg123
        msmtp
      ];
      config.Cmd = [ "${asteriskPkg}/bin/asterisk" "-C" "/etc/asterisk/asterisk.conf" "-T" "-p" "-vvvvv" "-ddddd" "-f" ];
    };

    # DNS updater image
    udns = let
      # Default log files
      logFileScript = "/log/exec.log";
      logFileCron = "/log/cron.log";
      # Default application
      mainExec = pkgs.writeScriptBin "main" ''
        #!${pkgs.bash}/bin/bash
        "${pkgs.bash}/bin/bash" "${my.projects.containers}/build/update-dns/update_dns.sh"
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
        # Import ENVs to proper path
        "${pkgs.coreutils}/bin/printenv" | "${pkgs.gnugrep}/bin/grep" "KEY\|SSL" > /etc/environment
        # Start cron process
        "${pkgs.busybox}/bin/crond" -f -l 0 -L /cron.log &
        # Tail log file
        "${pkgs.coreutils}/bin/tail" -fq "${logFileScript}" "${logFileCron}" &
        # Wait for all processes
        wait
      '';
    in pkgs.dockerTools.buildImage {
      name = "local/udns";
      tag = "latest";
      fromImage = baseImage;
      copyToRoot = [ initScript ];
      runAsRoot = "${buildScript}/bin/build";
      config.Cmd = [ "${pkgs.tini}/bin/tini" "${initScript}/bin/start" ];
    };

    # Static website with given url
    web = { name ? null, url ? null }: let
      # Decide name
      baseName = "local/web";
      givenName = if name == null then baseName else "${baseName}-${name}";
      # Get website
      website = if url == null then null else builtins.fetchGit { inherit url; ref = "master"; };
      # Set root folder
      rootFolder = "/web";
      # Build script for the image
      buildScript = let
        createBuild = functions.create [ rootFolder ];
      in pkgs.writeScriptBin "build" (''
        #!${pkgs.bash}/bin/bash
      '' + (if website == null then ''
        "${createBuild}/bin/build"
      '' else ''
        "${pkgs.coreutils}/bin/cp" -r "${website}" "${rootFolder}"
      ''));
    in pkgs.dockerTools.buildImage {
      name = givenName;
      tag = "latest";
      fromImage = baseImage;
      copyToRoot = with pkgs; [ nodePackages.http-server ];
      runAsRoot = "${buildScript}/bin/build";
      config.Cmd = [
        "${pkgs.nodePackages.http-server}/bin/http-server" "${rootFolder}"
        "-p" "8080" "-i" "--log-ip" "-r" "--no-dotfiles"
      ];
    };

  };
in allContainers
