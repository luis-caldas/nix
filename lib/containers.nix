{ pkgs, lib, config, ... }@args:
let

  allFunctions = {

    # Converts all the environment items to strings
    fixEnvironment = builtins.mapAttrs (name: value: builtins.toString value);

    # Import container files from a directory
    projects = path: shared: let
      # All the possible imports
      extension = "nix";
      possible = pkgs.functions.listFileNamesExtensionExcluded path [ "default" ] extension;
      # The permanent configurations to all services
      permanent = {
        restart = "unless-stopped";
      };
    in builtins.listToAttrs (
      # Map all the files to new format
      map (each: {
        # Name of
        name = each;
        # The set
        value = {
          # Set the service name also
          serviceName = each;
          # Import the settings from specific file
          settings = let
            # The imported document
            imported = import (path + "/${each}.${extension}") (args // { inherit shared; });
            # Add the permanent options to each service
            sortedServices = builtins.mapAttrs
              (name: value: let
                # Join the service with the permanent info
                newServiceInfo = { service = value.service // permanent; };
              in
                value // newServiceInfo
              ) imported.services;
            # Create the new object with the new services
            realImported = imported // { services = sortedServices; };
          in (builtins.trace realImported.services.dns.service (builtins.trace imported.services.dns.service realImported));
        };
      }) possible
    );

    # Create list of dependencies for systemd services
    createDependencies = dependencies: let
      # Service extension
      serviceExtension = "service";
      # List of list of services
      nestedServices = lib.attrsets.mapAttrsToList
        (name: value:
          (map
            (each: { "${each}".requires = [ "${name}.${serviceExtension}" ]; } )
          value)
        )
        dependencies;
      # Bring all services to the top
      allServices = lib.attrsets.mergeAttrsList (builtins.concatLists nestedServices);
    in allServices;

    # Create reverse proxy for https on the given container configuration
    createProxy = info: let
      # Container internal paths for keys and certificates
      certPath = "/etc/ssl/custom/default.crt";
      keyPath = "/etc/ssl/custom/default.key";
      # The main configuration
      nginxConfig = pkgs.writeText "custom-nginx-config" ''
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
            ${lib.attrsets.attrByPath [ "extraConfig" ] "" info}
            error_page 497 https://$host:$server_port$request_uri;
        }
      '';
    in {
      # Image
      image = "nginx:latest";
      # Volumes
      volumes = [
        "${nginxConfig}:/etc/nginx/conf.d/default.conf:ro"
        "${info.ssl.key}:${keyPath}:ro"
        "${info.ssl.cert}:${certPath}:ro"
      ];
      # Networking
      ports = [ "${info.port}:${info.port}/tcp" ];
    };

  };

in {

  # Overlay for all the functions
  nixpkgs.overlays = [

    # The overlay
    (final: prev: let

      # Name of the attribute we are getting into
      attrName = "functions";

      # Our current functions
      current.container = allFunctions;

    in {

      # The functions
      "${attrName}" = if builtins.hasAttr attrName prev then (prev."${attrName}" // current) else current;

    })

  ];

}