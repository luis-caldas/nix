{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Set up the network
  networks."${networks.turn}".name = networks.turn;

       ######
  ### # TURN # ###
       #####

  services."${names.turn}".service = let

    # The ports for TURN
    turnPorts = rec {
      min = 30000; max = 30500;
      defaultTCP = 80; defaultUDP = defaultTCP;
    };

    # Create the turn configuration
    turnConfiguration = pkgs.writeText "turn-config" (builtins.toJSON {
      eturnal = {
        # Secret
        secret = lib.strings.fileContents /data/containers/turn/pass;
        # Bind configuration
        listen = [
          { ip = "::"; port = turnPorts.defaultTCP; transport = "tcp"; enable_turn = true; }
          { ip = "::"; port = turnPorts.defaultUDP; transport = "udp"; enable_turn = true; }
        ];
        # Port range
        relay_min_port = turnPorts.min;
        relay_max_port = turnPorts.max;
        # Blacklist
        blacklist_peers = [
          "recommended"
        ];
        # Expire temporary credentials
        strict_expiry = false;
        # Log
        log_level = "info";
        log_dir = "stdout";
        # Modules
        modules = {
          mod_log_stun = {};
        };
      };
    });

  in {
    # Image
    image = "ghcr.io/processone/eturnal:latest";
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
    };
    # Volumes
    volumes = [
      "${turnConfiguration}:/etc/eturnal.yml:ro"
    ];
    # Networking
    ports = let
      stringPortRange = "${builtins.toString turnPorts.min}-${builtins.toString turnPorts.max}";
    in [
      "${builtins.toString turnPorts.defaultTCP}:${builtins.toString turnPorts.defaultTCP}/tcp"
      "${builtins.toString turnPorts.defaultUDP}:${builtins.toString turnPorts.defaultUDP}/udp"
      "${stringPortRange}:${stringPortRange}/udp"
    ];
    dns = pkgs.networks.dns;
    networks = [ networks.turn ];
  };

}