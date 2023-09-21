{ my, pkgs, config, ... }:
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

    # DNS proxy for DoT
    dns = let
      # Decide name
      baseName = "local/dns";
      # Get path to the config file
      configPathOg = "${my.projects.containers}/build/dns/dns.toml";
      # Set path to config file
      configPath = "/dns.toml";
      # Build script for the image
      buildScript = pkgs.writeScriptBin "build" (''
        "${pkgs.coreutils}/bin/cp" -r "${configPathOg}" "${configPath}"
      '');
    in pkgs.dockerTools.buildImage {
      name = "local/dns";
      tag = "latest";
      fromImage = baseImage;
      copyToRoot = with pkgs; [ dnscrypt-proxy2 ];
      runAsRoot = "${buildScript}/bin/build";
      config.Cmd = with pkgs; [
        "${dnscrypt-proxy2}/bin/dnscrypt-proxy" "-config" "${configPath}"
      ];
    };

  };

  # Helpful functions for the containers
  allData = {

    # All the images created here
    images = allContainers;

    # Functions to help manage containers
    functions = rec {

      # Adds networks to the container backend
      addNetworks = (networks: let
        # Docker binary
        docker = config.virtualisation.oci-containers.backend;
        dockerBin = "${pkgs.${docker}}/bin/${docker}";
        # Name prefix for service
        prefix = "container-network-start";
        # Prefix for the interface name
        prefixInterface = "br";
      in
        # Whole activation script
        builtins.listToAttrs (
          pkgs.lib.mapAttrsToList (networkName: { range, interface ? "" }: let
              # Name for the interface
              interfaceName = if interface != "" then "${prefixInterface}-${interface}" else networkName;
            in {
            name = "${prefix}-${networkName}";
            value = {
              description = "Create the needed networks for containers";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig.Type = "oneshot";
              script = ''
                check="$("${dockerBin}" network ls | grep "${networkName}" || true)"
                if [ -n "$check" ]; then
                  echo "${networkName} already exists in docker"
                  subnet_path=".[0].IPAM.Config[0].Subnet"
                  get_subnet="$(${dockerBin} network inspect "${networkName}" | "${pkgs.jq}/bin/jq" -r "$subnet_path")"
                  if [ "$get_subnet" == "${range}" ]; then
                    echo "${range} is the same, doing nothing"
                    exit 0
                  else
                    list_containers="$("${dockerBin}" network inspect -f '{{range .Containers}}{{.Name}} {{end}}' "${networkName}")"
                    for each_container in $list_containers; do
                      "${dockerBin}" network disconnect -f "${networkName}" "$each_container"
                    done
                    "${dockerBin}" network rm -f "${networkName}"
                    echo "Disconnected containers from ${networkName} and deleted it"
                  fi
                fi
                "${dockerBin}" network create "${networkName}" --opt com.docker.network.bridge.name="${interfaceName}" --driver bridge --subnet "${range}"
                echo "Created network ${networkName} with ${range} subnet"
                exit 0
              '';
            };
          })
          networks
        )
      );

      # Converts all the environment items to strings
      fixEnv = pkgs.lib.mapAttrs (name: value: builtins.toString value);

      # Create a HTTP to HTTPS redirector
      createRedirector = let
        httpPort = "80";
        httpsPort = "443";
        nginxConfig = pkgs.writeText "http-redirector" ''
          server {
              listen ${httpPort};
              server_name _;
              return 301 https://$host$request_uri;
          }
        '';
      in {
        image = "nginx:latest";
        ports = [ "${httpPort}:${httpPort}/tcp" ];
        volumes = [ "${nginxConfig}:/etc/nginx/conf.d/default.conf:ro" ];
      };

      # Create reverse proxy for https on the given container configuration
      createProxy = info: let
        certPath = "/etc/ssl/custom/default.crt";
        keyPath = "/etc/ssl/custom/default.key";
        extraConfig = let nameNow = "extraConfig"; in if builtins.hasAttr nameNow info then info."${nameNow}" else "";
        nginxConfig = pkgs.writeText "${info.name}-nginx-config" ''
          server {
              listen ${info.port} ssl http2;
              server_name _;
              ssl_certificate ${certPath};
              ssl_certificate_key ${keyPath};
              add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload";
              location / {
                  proxy_set_header Host $host:$server_port;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Port $server_port;
                  proxy_set_header X-Forwarded-Scheme $scheme;
                  proxy_set_header X-Forwarded-Proto $scheme;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_pass http://${info.net.ip}:${info.net.port};
              }
              ${extraConfig}
              error_page 497 https://$host:$server_port$request_uri;
          }
        '';
      in {
        image = "nginx:latest";
        dependsOn = [ "${info.name}" ];
        ports = [ "${info.port}:${info.port}/tcp" ];
        volumes = [
          "${nginxConfig}:/etc/nginx/conf.d/default.conf:ro"
          "${info.ssl.key}:${keyPath}:ro"
          "${info.ssl.cert}:${certPath}:ro"
        ];
        extraOptions = let
          extra = "extraOptions";
        in [ "--network=${info.net.name}" ] ++
          (if builtins.hasAttr extra info then info."${extra}" else []);
      };

      # Returns both containers configuration
      addProxy = info: config: {
        # Proxy create
        "${info.name}-proxy" = createProxy info;
        # Original now tied to proxy
        "${info.name}" = let
          mergeIfPossible = originalAttrSet: attrName: newList:
            if builtins.hasAttr attrName originalAttrSet then
              { "${attrName}" = originalAttrSet."${attrName}" ++ newList; }
            else
              { "${attrName}" = newList; };
        in config //
          mergeIfPossible config "extraOptions" [ "--network=${info.net.name}" "--ip=${info.net.ip}" ];

      };

    };

  };

in allData
