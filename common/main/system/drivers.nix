{ config, pkgs, lib, ... }:
{

  # Drivers to install on the system
  boot.extraModulePackages = with config.boot.kernelPackages; [

    # Wifi
    rtw88

    # Video loopback
    v4l2loopback

  ];

  # Firmware to install on the system
  hardware.firmware = with pkgs; lib.mkBefore [];

}
