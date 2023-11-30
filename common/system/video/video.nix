{ my, mfunc, config, pkgs, lib, ... }:
{

  # Set the Display Manager and Window Manager
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Enable plymouth
  boot.plymouth = {
    enable = true;
    themePackages = [ pkgs.adi1090x-plymouth-themes ];
    theme = "spinner_alt";
    font = "${pkgs.courier-prime}/share/fonts/truetype/CourierPrime-Regular.ttf";
  };

  # Fix for ZFS password asking
  boot.initrd = {
    systemd.enable = true;
    verbose = false;
  };

  # Hide boot
  boot.loader = {
    timeout = 1;
    grub = {
      extraConfig = ''
        set timeout_style=hidden
      '';
      splashImage = null;
    };
  };

  # Make kernel not show any text
  boot = {
    kernelParams = [ "quiet" "splash" ];
    consoleLogLevel = 0;
  };

  # Set gnome packages to install
  services.gnome = {
    games.enable = false;
    gnome-keyring.enable = true;
    core-shell.enable = true;
    core-utilities.enable = false;
    core-os-services.enable = true;
    core-developer-tools.enable = true;
  };

  # Automatically unlock gnome keyring
  security.pam.services.gdm.enableGnomeKeyring = true;

  # Auto login for the desktop environment
  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = my.config.user.name;
  };

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
