{ lib, ... }:
{

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  ########
  # Mine #
  ########

  mine = {
    minimal = true;
    boot.grub = true;
    user.admin = false;
    system.hostname = "opti";
    services.ssh = true;
  };

  ########
  # Kodi #
  ########

  # Store audio cards states
  sound.enable = true;

  # Enable pulseaudio and all the supported codecs
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
  };

  # Allow packages to compile with pulseaudio support
  nixpkgs.config.pulseaudio = true;

  # Set graphics drivers
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

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
    # Also disable screen timeout
    setupCommands = ''
      "${pkgs.xorg.xset}/bin/xset" -dpms
      "${pkgs.xorg.xset}/bin/xset" s off
    '';
  };

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

  # Create the kodi user and add it to the audio gruop
  users.users.kodi = {
    isNormalUser = true;
    extraGroups = [ "audio" ];
  };

  # Enable kodi
  services.xserver.desktopManager.kodi.enable = true;

  # Kodi with packages
  services.xserver.desktopManager.kodi.package = pkgs.kodi.withPackages (p: with p; [
    inputstream-rtmp inputstreamhelper inputstream-adaptive inputstream-ffmpegdirect
    six kodi-six idna urllib3 chardet certifi requests myconnpy dateutil
    pvr-iptvsimple pvr-hts pvr-hdhomerun
    youtube netflix jellyfin
    a4ksubtitles
    pdfreader
  ]);

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
