{ pkgs, lib, config, ... }:

lib.mkIf config.mine.graphics.enable

{

  # Display Manager
  services.displayManager = {
    defaultSession = "gnome";
    # Autologin
    autoLogin = {
      enable = true;
      user = config.mine.user.name;
    };
  };

  # Desktop Manager
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    # desktopManager.gnome.debug = true;
  };

  # Fix mutter
  environment.sessionVariables = {
    MUTTER_DEBUG_KMS_THREAD_TYPE = "user";
  };
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Enable plymouth
  boot.plymouth = {
    enable = true;
    theme = "bgrt";
    font = "${pkgs.roboto}/share/fonts/truetype/Roboto-Regular.ttf";
  };

  # Fix for ZFS password asking
  boot.initrd = {
    systemd.enable = true;
    verbose = false;
  };

  # Hide boot
  boot.loader = {
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
    core-apps.enable = false;
    core-os-services.enable = true;
    core-developer-tools.enable = true;
  };

  # Automatically unlock gnome keyring
  security.pam.services.gdm.enableGnomeKeyring = true;

  # Add 32 bit support and other acceleration packages
  hardware.graphics = {
    enable = true;
  } //
  # Check architectures and set proper packages
  (if (!pkgs.stdenv.hostPlatform.isAarch) then rec {
    enable32Bit = true;
    # Packages for video acceleration
    extraPackages32 = with pkgs; [
      pkgsi686Linux.libva
    ] ++ extraPackages;
    extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
    ];
  } else {});

}
