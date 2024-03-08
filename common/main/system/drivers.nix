{ config, ... }:
{

  # Drivers to install on the system
  boot.extraModulePackages = with config.boot.kernelPackages; [

      # Wifi
      rtw88

      # Video loopback
      v4l2loopback

  ];

}
