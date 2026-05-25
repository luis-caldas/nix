{ lib, config, ... }:

lib.mkIf config.mine.bluetooth

{

  # Allow Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Battery level
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

}
