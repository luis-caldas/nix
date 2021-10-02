{ pkgs, ... }:
{

  # Needed xserver configs for kodi
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.autoLogin.enable = true;
  services.xserver.displayManager.lightdm.autoLogin.user = "kodi";
  services.xserver.displayManager.lightdm.greeter.enable = false;

  # Enable kodi
  services.xserver.desktopManager.kodi.enable = true;

  # Kodi with packages
  services.xserver.desktopManager.kodi.package = pkgs.kodi.withPackages (p: with p; [
    inputstream-rtmp inputstreamhelper inputstream-adaptive inputstream-ffmpegdirect
    six kodi-six idna urllib3 chardet certifi requests myconnpy dateutil
    pvr-iptvsimple pvr-hts pvr-hdhomerun
    youtube netflix
    a4ksubtitles
    pdfreader
    osmc-skin
    joystick steam-launcher
  ]);

}
