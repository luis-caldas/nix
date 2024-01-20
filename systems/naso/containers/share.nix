{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.share.name}".name = networks.share.name;

       #######
  ### # SAMBA # ###
       #######

  services."${names.share}".service = {

    # Image
    image = "dperson/samba:latest";

    # Name
    container_name = names.share;

    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      USERID = config.mine.user.uid;
      GROUPID = config.mine.user.gid;
    };
    env_file = [ "/data/local/containers/media/samba.env" ];

    # Volumes
    volumes = [
      "/data/storr/media:/media"
      "/data/local/containers/media/ps2:/ps2"
      "/data/storr/media/games/roms/ps2/dvd:/ps2/DVD:ro"
      "/data/storr/media/games/roms/ps2/cd:/ps2/CD:ro"
      "/data/storr/media/games/roms/ps2/art:/ps2/ART:ro"
    ];

    # Networking
    ports = [
      "137:137/udp"
      "138:138/udp"
      "139:139/tcp"
      "445:445/tcp"
    ];

    # Command
    command = lib.strings.concatStringsSep " " ([
      "-g" "\"log level = 2\"" # Global config
      "-n" # NMBF
      "-r" # Remove recycle bin
      "-S" # Disable minimum SMB2
      "-s" "\"media;/media;yes;no;no;all;;;Share for media files\"" # Share config
      "-s" "\"ps2;/ps2;yes;no;yes;all;;;PS2 Games\""
      "-w" "WORKGROUP" # Default workgroup
      "-W" # Wide link support
    ]);

    # Networking
    networks = [ networks.share.name ];

  };

       #######
  ### # Shout # ###
       #######

  services."${names.shout}".service = {
    # Image
    image = "aovestdipaperino/wsdd2";
    # Name
    container_name = names.shout;
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      HOSTNAME = config.mine.system.hostname;
    };
    # Networking
    network_mode = "host";  # Multicast support
  };

}