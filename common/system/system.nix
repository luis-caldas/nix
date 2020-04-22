{ ... }:
let
  configgo = import ../../config.nix;
in
{

  # Needed for ZFS to work
  networking.hostId = configgo.net.id;

  # Set the hostname
  networking.hostName = configgo.system.hostname; # Define your hostname.

  # Force the use of DHCP on the proper interface
  networking.useDHCP = false;
  networking.interfaces."${configgo.net.interface.main}".useDHCP = true;

  # My timezone
  time.timeZone = configgo.system.timezone;

}
