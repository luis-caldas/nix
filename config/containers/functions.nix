{ pkgs, lib, config, ... }:
let

  # Create all the functions that will be available to use
  allFunctions = {

    # Converts all the environment items to strings
    fixEnvironment = builtins.mapAttrs (name: value: builtins.toString value);

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

  # The functions to the overlay
  nixpkgs.overlays = [

    # The overlay
    (final: prev: {

      # All the functions
      containerFunctions = allFunctions;

    })

  ];

}