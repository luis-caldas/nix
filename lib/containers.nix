{ pkgs, lib, config, ... }@args:
let

  allFunctions = rec {

    # Max retries for a container to be restarted
    maxRetries = 32;

    # Keyword that will be simplified for the parents namin
    # When used with dynamic naming
    simplifier = "app";

    # Default separator for the container naming
    containerNameSeparator = "-";

    # Converts all the environment items to strings
    fixEnvironment = builtins.mapAttrs (name: value: builtins.toString value);

    # Get last with separator
    getLastDash = inputString:
      lib.lists.last (lib.strings.splitString containerNameSeparator inputString);

    # Add a custom init to the configuration
    addCustomInit = originalObject: let
      extra = { init = true; };
    in originalObject // {
      out.service =
        if builtins.hasAttr "out" originalObject then
          originalObject.out.service // extra
        else
          extra;
    };

    # Import container files from a directory
    projects = path: shared: let
      # All the possible imports
      extension = "nix";
      possible = pkgs.functions.listFileNamesExtensionExcluded path [ "default" ] extension;
      # The permanent configurations to all services
      permanent = {
        restart = "on-failure:${builtins.toString maxRetries}";
      };
      # Configuration to be done if container is locally built
      # or not
      rawConfig = {
        local = { init = true; };
        remote = { pull_policy = "always"; };
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
                newServiceInfo = {
                  service = value.service // permanent // {
                    # Also manually set the container name
                    container_name = name;
                  };
                };
                # Check if there is a need to add the pull policy
                newRaw =
                  if builtins.hasAttr "build" value then {
                    out.service = rawConfig.local;
                  } else {
                    out.service = rawConfig.remote;
                  };
              in
                value // newServiceInfo // newRaw
              ) imported.services;
            # Create the new object with the new services
            realImported = imported // { services = sortedServices; };
          in realImported;
        };
      }) possible
    );

    # Extract net network dependencies so that we can build the systemd
    # dependencies after
    # ! The network name must match the project name (file name)
    extractDependencies = arionProjects:
      # Join all the data to the wanted format
      lib.attrsets.zipAttrs (builtins.concatLists
        # Iterate the data and filter the false entries
        (builtins.filter (each: each != false) (lib.attrsets.mapAttrsToList (name: value:
          # Check if the entry has networks
          if builtins.hasAttr "networks" value.settings then
            # If so we can iterate over it, and filter the wanted results
            builtins.filter (each: each != false) (lib.attrsets.mapAttrsToList (network: content:
              # If we found an external network we can add it to the data
              if (builtins.hasAttr "external" content) && (content.external == true) then
                { "${name}" = network; }
              else
                false
            ) value.settings.networks)
          else
            false
        ) arionProjects))
      );

    # Create list of dependencies for systemd services
    createDependencies = dependencies: let
      # Data to be added
      serviceData = {
        unitConfig = {
          StartLimitBurst = 8;
          StartLimitInterval = "infinity";
        };
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 8;
          RestartSteps = 4;
          RestartMaxDelaySec = 128;
        };
      };
      # Service extension
      serviceExtension = "service";
      # Extract the network dependencies
      networkDependencies = extractDependencies dependencies;
      # Add all the needed information to the services
      updatedServices = lib.attrsets.mapAttrsToList (name: value:
        {
          "${name}" = serviceData //
          (if (builtins.hasAttr name networkDependencies) then {
            requires = map (netName: "${netName}.${serviceExtension}")
              networkDependencies."${name}";
          } else {});
        }) dependencies;
    in lib.attrsets.mergeAttrsList updatedServices;

    # Fix attr names
    createNames = { dataIn, previousPath ? [] }: let
      # Return variable when an error occurs
      errorReturn = "unknown";
      # Helper to cut simplifier
      cutSimplifier = previousNames: finalName: let
        # Fix the list
        fixedPrevious =
          if (lib.lists.last previousNames) == simplifier then
            lib.lists.sublist 0 ((builtins.length previousNames) - 1) previousNames
          else
            previousNames;
        # Check if the name is to be fixed
        extraName =
          if finalName == simplifier then [] else [ finalName ];
      in
        lib.strings.concatStringsSep containerNameSeparator (fixedPrevious ++ extraName);
    in
      # Iterate the attrset input
      lib.attrsets.concatMapAttrs (name: value: let
        # Fix the previous path
        oldPath = previousPath ++ [ name ];
      in
        # If is an attrset
        if (builtins.typeOf value) == "set" then
          # Send it to the start again
          # But keep the reference
          {
            "${name}" = createNames {
              dataIn = value;
              previousPath = oldPath;
            };
          }
        # If we receive a list
        else if (builtins.typeOf value) == "list" then
          # Check to see if we need to expand the simplifier
          if name == simplifier then
            # Iterate the items and make them individual
            builtins.listToAttrs (map (each: {
              name = each;
              value = cutSimplifier oldPath each;
            }) value)
          else
            # Iterate the items and create the proper data
            {
              "${name}" =
                builtins.listToAttrs (map (each: {
                  name = each;
                  value = cutSimplifier oldPath each;
                }) value);
            }
        # If we dont know what we received
        else
          # Throw error because we should not be here
          errorReturn
      ) dataIn;

    # Create the names for the networks
    createNetworkNames = inputList:
      builtins.listToAttrs (map (each: {
        name = each;
        value = each;
      }) inputList);

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