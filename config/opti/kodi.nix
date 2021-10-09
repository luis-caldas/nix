{ pkgs, ... }:
{

  # Outside imports
  imports = [
    ../../common/system/audio.nix
    ../../common/system/video/video.nix
    ../../common/system/video/packages.nix
  ];

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

  # Create the kodi user and add it to the audio gruop
  kodi = {
    isNormalUser = true;
    extraGroups = [ "audio" ];
  };

  # Allow system wide pulseaudio for multiple users
  hardware.pulseaudio.systemWide = true;

  # Packages to be installed
  environment.systemPackages = with pkgs; [ retroarch ];

  # Enable retroarch cores
  nixpkgs.config.retroarch = {
    enableFceumm = true;
    enableSnes9x = true;
    enableMgba = true;
    enableMupen64Plus = true;
  };

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
