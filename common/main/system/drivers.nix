{ config, pkgs, lib, ... }:
{

  boot.extraModulePackages = with config.boot.kernelPackages;
    lib.optionals (!config.mine.minimal) [
      # WiFi
      rtw88
    ] ++ lib.optionals config.mine.graphics.enable [
      # Video loopback
      v4l2loopback
    ];

  hardware.firmware = with pkgs; lib.mkBefore [];

}
