{ config, ... }:
{

  # Drivers to install on the system
  boot.extraModulePackages = with config.boot.kernelPackages; [

      # Wifi
      rtl8821cu

      # Controllers
      hid-nintendo

      # Video loopback
      v4l2loopback

  ];

  # Set initial kernel module settings
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
  '';

}
