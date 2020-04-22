{ ... }:
let
  my = import ../../config.nix;
in
{

  # Needed for ZFS to work
  networking.hostId = my.config.net.id;

  # Set the hostname
  networking.hostName = my.config.system.hostname; # Define your hostname.

  # Force the use of DHCP on the proper interface
  networking.useDHCP = false;
  networking.interfaces."${my.config.net.interface.main}".useDHCP = true;

  # My timezone
  time.timeZone = my.config.system.timezone;

}
