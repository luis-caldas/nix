{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = pkgs.functions.container.populateNetworks [
    networks.share
  ];

       #######
  ### # SAMBA # ###
       #######

  services."${names.samba}".service = {

    # Image
    image = "dperson/samba:latest";

    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      TZ = config.mine.system.timezone;
      USERID = config.mine.user.uid;
      GROUPID = config.mine.user.gid;
    };
    env_file = [ "/data/local/containers/media/samba.env" ];

    # Volumes
    volumes = [
      "/data/chunk/media:/media"
      "/data/local/containers/media/ps2:/ps2"
      "/data/chunk/media/games/roms/ps2/dvd:/ps2/DVD:ro"
      "/data/chunk/media/games/roms/ps2/cd:/ps2/CD:ro"
      "/data/chunk/media/games/roms/ps2/art:/ps2/ART:ro"
      "/data/chunk/media/games/roms:/roms:ro"
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
      "-s" "\"roms;/roms;yes;no;yes;all;;;All ROMs\""
      "-w" "WORKGROUP" # Default workgroup
      "-W" # Wide link support
    ]);

    # Networking
    networks = [ networks.share ];

  };

       #######
  ### # Shout # ###
       #######

  services."${names.shout}".service = {
    # Image
    image = "aovestdipaperino/wsdd2";
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      HOSTNAME = config.mine.system.hostname;
    };
    # Networking
    network_mode = "host";  # Multicast support
  };

}