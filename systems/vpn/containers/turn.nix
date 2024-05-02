{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Set up the network
  networks."${networks.turn.name}".name = networks.turn.name;

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
        # Bind configuration
        listen = [
          { ip = "::"; port = turnPorts.defaultTCP; transport = "tcp"; }
          { ip = "::"; port = turnPorts.defaultUDP; transport = "udp"; }
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
    # Name
    container_name = names.turn;
    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      UID = config.mine.user.uid;
      GID = config.mine.user.gid;
      ETURNAL_RELAY_MIN_PORT = turnPorts.min;
      ETURNAL_RELAY_MAX_PORT = turnPorts.max;
      STUN_SERVICE = false;
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
    networks = [ networks.turn.name ];
  };

}