{ my, mfunc, config, pkgs, ... }:
{

  # Set the display manager and window manager
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Enable plymouth
  boot.plymouth.enable = true;

  # Set gnome packages to install
  services.gnome = {
    games.enable = false;
    core-shell.enable = true;
    core-utilities.enable = false;
    core-os-services.enable = true;
    core-developer-tools.enable = true;
  };

  # Auto login for the desktop environment
  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = my.config.user.name;
  };
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Set graphics drivers
  services.xserver.videoDrivers = my.config.graphical.drivers;

  # Add 32 bit support and other acceleration packages
  hardware.opengl = {
    enable = true;
    # Select custom version of mesa drivers
    #package = pkgs.mesa.drivers;
  } //
  mfunc.useDefault ((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) rec {
    driSupport32Bit = true;
    extraPackages32 = with pkgs; [
      pkgsi686Linux.libva
    ] ++ extraPackages;
    extraPackages = with pkgs; [
      intel-ocl
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      rocm-opencl-icd
      rocm-opencl-runtime
    ];
  } {};

}
