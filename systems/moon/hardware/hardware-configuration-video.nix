{ pkgs, ... }:
{

  services.xserver.config = pkgs.lib.mkOverride 50 (builtins.readFile ./xorg.conf);
  services.xserver.videoDrivers = ["amdgpu"];

}
