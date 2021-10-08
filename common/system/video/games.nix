{ ... }:
{

  # Enable retroarch cores
  nixpkgs.config.retroarch = {
    enableFceumm = true;
    enableSnes9x = true;
    enableMgba = true;
    enableMupen64Plus = true;
  };

}
