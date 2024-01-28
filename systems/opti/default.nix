{ pkgs, lib, ... }:
{

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "radeon" ] ;
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  ########
  # Mine #
  ########

  mine = {
    minimal = true;
    boot.grub = true;
    kernel.text = false;
    user.admin = false;
    system.hostname = "opti";
    services.ssh = true;
  };

  #########
  # Audio #
  #########

  # Store audio cards states
  sound.enable = true;

  # Disable pulseaudio
  hardware.pulseaudio.enable = false;

  # Pipewire config
  services.pipewire = {
    # Enable pipewire
    enable = true;
    wireplumber.enable = true;
    # Enable other audio systems support
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Allow packages to compile with pulseaudio support
  nixpkgs.config.pulseaudio = true;

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

  ########
  # Kodi #
  ########

  # Create the kodi user and add it to the audio gruop
  users.users.kodi = {
    isNormalUser = true;
    extraGroups = [ "audio" ];
  };

  # Use sddm as autologin displaymanager because it supports relogin
  services.xserver.displayManager = {
    lightdm.enable = false;
    sddm = {
      enable = true;
      autoLogin.relogin = true;
    };
    autoLogin.enable = true;
    autoLogin.user = "kodi";
    # Also disable screen timeout
    setupCommands = ''
      "${pkgs.xorg.xset}/bin/xset" -dpms
      "${pkgs.xorg.xset}/bin/xset" s off
    '';
  };

  # Fixing the certifi certificate
  home-manager.users.kodi = { config, ... }: {
    home.files = {
      ".kodi/addons/script.module.certifi/lib/certifi/cacert.pem".source = config.lib.file.mkOutOfStoreSymlink "/etc/ssl/certs/ca-bundle.crt";
    };
  };

  # Enable xserver
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "radeon" ];
  services.xserver.desktopManager.kodi.enable = true;

  # Enable kodi
  services.xserver.desktopManager.kodi.package = pkgs.kodi.withPackages (givenPackages: with givenPackages; [

    # Video processing
    inputstream-rtmp inputstreamhelper inputstream-adaptive inputstream-ffmpegdirect

    # Tools for addons
    six kodi-six idna urllib3 chardet certifi requests myconnpy dateutil

    # IPTV tools
    pvr-iptvsimple pvr-hts pvr-hdhomerun

    # Apps
    youtube netflix jellyfin

    # Helper apps
    a4ksubtitles
    pdfreader

  ]);

  ############
  # Plymouth #
  ############

  # Use plymouth theme
  boot.plymouth = let
    theme-name = "kodi-animated-logo";
    plymouth-theme = pkgs.stdenv.mkDerivation rec {
      pname = theme-name;
      version = "0.0.1";
      src = pkgs.fetchFromGitHub {
        owner = "solbero";
        repo = "plymouth-theme-kodi-animated-logo";
        rev = "f16d51632ef5d0182821749901af04bbe2efdfd6";
        sha256 = "sha256-e0ps9Fwdcc9iFK8JDRSayamTfAQIbzC+CoN0Yokv7kY=";
      };
      installPhase = ''
        mkdir -p $out/share/plymouth/themes/
        cp -r plymouth-theme-kodi-animated-logo/usr/share/plymouth/themes/kodi-animated-logo $out/share/plymouth/themes/.
        cat plymouth-theme-kodi-animated-logo/usr/share/plymouth/themes/kodi-animated-logo/kodi-animated-logo.plymouth | sed "s@\/usr\/@$out\/@" > $out/share/plymouth/themes/${pname}/${pname}.plymouth
      '';
    };
  in {
    enable = true;
    theme = theme-name;
    themePackages = [ plymouth-theme ];
  };

  ##########
  # System #
  ##########

  fileSystems."/" =
    { device = "light/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/40FB-1D4B";
      fsType = "vfat";
    };

  fileSystems."/tmp" =
    { device = "light/tmp";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "light/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "light/nix";
      fsType = "zfs";
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  system.stateVersion = "23.05";

}
