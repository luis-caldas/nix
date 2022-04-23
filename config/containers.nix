{ my, pkgs, ... }:
let
  allContainers = {

    # Python Scrape container
    pythonScrape = let
      logFileScript = "/met-weathers-cron.log";
      logFileCron = "/cron-tab.log";
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
      buildingScript = pkgs.writeScriptBin "building" ''
        #!${pkgs.bash}/bin/bash
        "${pkgs.coreutils}/bin/mkdir" -p /var/spool/cron/crontabs /var/run /tmp
        "${pkgs.coreutils}/bin/touch" "${logFileScript}" "${logFileCron}"
        "${pkgs.coreutils}/bin/echo" 'root:x:0:0:root:/root:/bin/bash' > /etc/passwd
        "${pkgs.coreutils}/bin/cp" "${cronFile}/cron" /var/spool/cron/crontabs/root
      '';
      initScript = pkgs.writeScriptBin "start" ''
        #!${pkgs.bash}/bin/bash
        "${pkgs.coreutils}/bin/printenv" | "${pkgs.gnugrep}/bin/grep" "SMTP\|SSL" > /etc/environment
        "${pkgs.busybox}/bin/crond" -f -l 0 -L /cron.log &
        "${pkgs.coreutils}/bin/tail" -fq "${logFileScript}" "${logFileCron}"
      '';
      projectFull = pkgs.runCommand "add-folder" { project = builtins.fetchGit {
        url = "https://github.com/luis-caldas/get-weathers";
        ref = "master";
      };} ''
        mkdir -p "''${out}"
        cp -a "''${project}" "''${out}/main/"
      '';
    in pkgs.dockerTools.buildImage {
      name = "local/python-scrape";
      tag = "latest";
      contents = with pkgs; [
        bash bashInteractive busybox coreutils gnugrep findutils moreutils procps
        cron openssl cacert packagedPython
        initScript mainExec cronFile projectFull
      ];
      runAsRoot = "${buildingScript}/bin/building";
      config = {
        Env = [
          "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        ];
        Cmd = [
          "${pkgs.bash}/bin/bash" "${initScript}/bin/start"
        ];
      };
    };


  };
in allContainers