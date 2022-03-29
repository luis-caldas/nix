{ pkgs, ... }:
{

  # Store audio cards states
  sound.enable = true;

  # Enable pulseaudio and all the supported codecs
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    extraModules = [ pkgs.pulseaudio-modules-bt ];
    package = pkgs.pulseaudioFull;
  };

  # Allow packages to compile with pulseaudio support
  nixpkgs.config.pulseaudio = true;

  # Set graphics drivers
  services.xserver.videoDrivers = [ "intel" ];

  # Add 32 bit support and other acceleration packages
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages32 = with pkgs; [
      intel-ocl
      vaapiIntel
      rocm-opencl-icd
      rocm-opencl-runtime
      pkgsi686Linux.libva
    ];
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

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
    setupCommands = ''
      "${pkgs.xorg.xset}/bin/xset" -dpms
      "${pkgs.xorg.xset}/bin/xset" s off
    '';
  };

  # Create the kodi user and add it to the audio gruop
  users.users.kodi = {
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
  ]);

}
