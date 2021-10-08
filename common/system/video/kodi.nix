{ pkgs, ... }:
{

  # Needed xserver configs for kodi
  services.xserver.enable = true;

  # Use sddm as autologin displaymanager because it supports relogin
  services.xserver.displayManager = {
    lightdm.enable = false;
    sddm = {
      enable = true;
      autoLogin.relogin = true;
    };
    autoLogin.enable = true;
    autoLogin.user = "kodi";
  };

  # Packages to be installed
  environment.systemPackages = with pkgs; [ retroarch ];

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
    steam-launcher
  ]);

}
