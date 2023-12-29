{ pkgs, lib, config, ... }:
let

  # Create all the functions that will be available to use
  allFunctions = {

    # Adds networks to the container backend
    addNetworks = (networks: let
      # Docker binary
      docker = config.virtualisation.oci-containers.backend;
      dockerBin = "${pkgs."${docker}"}/bin/${docker}";
      # Name prefix for service
      prefix = "container-network-start";
      # Prefix for the interface name
      prefixInterface = "br";
    in
      # Whole activation script
      builtins.listToAttrs (
        lib.attrsets.mapAttrsToList (networkName: { range, interface ? "" }: let
            # Name for the interface
            interfaceName = if interface != "" then interface else "${prefixInterface}-${networkName}";
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
    fixEnvironment = builtins.mapAttrs (name: value: builtins.toString value);

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


  };

in {

  # The functions to the overlay
  nixpkgs.overlays = [

    # The overlay
    (final: prev: {

      # All the functions
      container.functions = allFunctions;

    })

  ];

}