{ pkgs, ... }:
{

  # Drivers to install on the system
  environment.systemPackages = with pkgs.linuxPackages; [

      # Wifi
      rtl8821cu

  ];

}
