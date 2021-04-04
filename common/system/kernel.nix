{ pkgs, ... }:
{

  # Use custom kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

}
