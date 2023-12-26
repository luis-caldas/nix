{ config, ... }:
{

  # Drivers to install on the system
  boot.extraModulePackages = with config.boot.kernelPackages; [

      # Wifi
      rtl8821cu

      # Video loopback
      v4l2loopback

  ];

}