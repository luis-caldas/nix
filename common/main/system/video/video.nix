{ pkgs, lib, config, ... }:

lib.mkIf config.mine.graphics.enable

{

  # Display manager
  services.displayManager = {
    defaultSession = "gnome";
    # Autologin
    autoLogin = {
      enable = true;
      user = config.mine.user.name;
    };
  };

  # Desktop manager
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Fix mutter
  environment.sessionVariables = {
    MUTTER_DEBUG_KMS_THREAD_TYPE = "user";
  };
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Enable plymouth
  boot.plymouth = let
    font = pkgs.reference.more.fonts.file;
  in rec {
    enable = true;
    theme = "main_custom";
    themePackages = let
      inputText = lib.strings.toUpper (lib.lists.last (lib.splitString "-" pkgs.reference.owner));
    in [ (pkgs.custom.plymouth-mine theme font inputText) ];
    inherit font;
  };

  # Fix ZFS password prompts
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

  # Hide kernel text output
  boot = {
    kernelParams = [ "quiet" "splash" ];
    consoleLogLevel = 0;
  };

  # Set GNOME packages to install
  services.gnome = {
    games.enable = false;
    gnome-keyring.enable = true;
    core-shell.enable = true;
    core-apps.enable = false;
    core-os-services.enable = true;
    core-developer-tools.enable = true;
  };

  # Automatically unlock GNOME keyring
  security.pam.services.gdm.enableGnomeKeyring = true;

  # Add 32 bit support and acceleration packages
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
      libvdpau-va-gl
      libva-vdpau-driver
    ];
  } else {});

}
