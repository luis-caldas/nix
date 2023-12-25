{ lib, config, ... }:

lib.mkIf config.mine.bluetooth

{

  # Allow bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

}
