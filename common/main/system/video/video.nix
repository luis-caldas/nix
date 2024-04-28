{ pkgs, lib, config, ... }:

lib.mkIf config.mine.graphics.enable

{

  # Set the Display Manager and Window Manager
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    displayManager.defaultSession = "gnome";
    desktopManager.gnome.enable = true;
    desktopManager.gnome.debug = true;
  };

  # Fix mutter
  environment.sessionVariables = {
    MUTTER_DEBUG_KMS_THREAD_TYPE = "user";
  };
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Enable plymouth
  boot.plymouth = let

    # The default theme
    defaultTheme = "main_custom";

    # Create custom plymouth theme
    customPlymouth = pkgs.stdenv.mkDerivation rec {
      pname = defaultTheme;
      version = "0.0.1";
      src = pkgs.reference.projects.boot-animation;
      nativeBuildInputs = [
        (pkgs.python3.withPackages (packages: with packages; [ wand ]))
      ];
      buildPhase = ''
        # Compile the theme
        python scaler.py plymouth
      '';
      installPhase = ''
        # Create the output folder
        mkdir -p $out/share/plymouth/themes/
        # Copy everything
        cp -r dist/plymouth $out/share/plymouth/themes/${defaultTheme}
      '';
    };

  in {
    enable = true;
    themePackages = [ customPlymouth ];
    theme = "main_custom";
    font = "${pkgs.courier-prime}/share/fonts/truetype/CourierPrime-Regular.ttf";
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
    core-utilities.enable = false;
    core-os-services.enable = true;
    core-developer-tools.enable = true;
  };

  # Automatically unlock gnome keyring
  security.pam.services.gdm.enableGnomeKeyring = true;

  # Auto login for the desktop environment
  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = config.mine.user.name;
  };

  # Add 32 bit support and other acceleration packages
  hardware.opengl = {
    enable = true;
  } //
  # Check architectures and set proper packages
  (if (!pkgs.stdenv.hostPlatform.isAarch) then rec {
    driSupport32Bit = true;
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
