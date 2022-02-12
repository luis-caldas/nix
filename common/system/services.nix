{ my, mfunc, lib, pkgs, mpkgs, ... }:
{

  # SSH
  services.openssh = {
    enable = my.config.services.ssh;
    # Enable X11 forwarding if graphical is enabled
    forwardX11 = my.config.services.ssh && my.config.graphical.enable;
  };

  # Docker for my servers
  virtualisation.docker.enable = my.config.services.docker;

  # libvirt config
  virtualisation.libvirtd = mfunc.useDefault my.config.services.virt.enable {
    enable = true;
    onBoot = "start";
    onShutdown = "shutdown";
    qemu.ovmf = {
      enable = true;
      package = pkgs.OVMFFull;
    };
    qemu.swtpm.enable = my.config.services.virt.swtpm;
  } {};

  # Netdata monitor for servers and such
  services.netdata.enable = my.config.services.monitor;

  # PCSC
  services.pcscd = {
    enable = true;
    plugins = [ pkgs.acsccid ];
  };

  # Overrides
  nixpkgs.config.packageOverrides = pkgs: {
    # Add custom image to OVMF UEFI
    OVMFFull = pkgs.OVMFFull.overrideAttrs (attrs: {
        name = attrs.name + "-custom-logo";
        postPatch = (if (builtins.hasAttr "postPatch" attrs) then attrs.postPatch else "") + ''
          "${pkgs.ffmpeg}/bin/ffmpeg" -i "${my.projects.wallpapers}/papes/dpm-navy-small.png" -pix_fmt rgb24 -y -vf scale=256:-1 "./MdeModulePkg/Logo/Logo.bmp"
        '';
    });
    fprintd = mpkgs.fprintd-clients;
    # Fix Intel OCL URL
    intel-ocl = pkgs.intel-ocl.overrideAttrs (oldAttrs: {
      src = pkgs.fetchzip {
        url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/11396/SRB5.0_linux64.zip";
        sha256 = "0qbp63l74s0i80ysh9ya8x7r79xkddbbz4378nms9i7a0kprg9p2";
        stripRoot = false;
      };
    });
  };

  # Fingerprint
  services.fprintd.enable = my.config.services.fingerprint;
  services.open-fprintd.enable = my.config.services.fingerprint;
  services.python-validity.enable = my.config.services.fingerprint;

  # Software defined radio
  hardware.rtl-sdr.enable = true;
  services.udev.packages = [ pkgs.rtl-sdr ];

  # Enable logiops service (logitech MX mice)
  services.logiops.enable = my.config.graphical.enable;

  # Printing
  services.printing = mfunc.useDefault my.config.services.printing {
    enable = true;
    drivers = with pkgs; [
        cups-zj-58
        brlaser
        gutenprint
      ] ++
      (mfunc.useDefault my.config.x86_64 [
        gutenprintBin
        brgenml1lpr
        brgenml1cupswrapper
      ] []);
    browsedConf = "
      CreateIPPPrinterQueues All
      CreateIPPPrinterQueues driverless
    ";
  } {};

  # Scanning
  hardware.sane = mfunc.useDefault my.config.services.printing {
    enable = true;
    extraBackends = with pkgs; [
      sane-airscan
    ];
  } {};

  # Printer applets
  programs.system-config-printer.enable =
    my.config.graphical.enable && my.config.services.printing;

  # Avahi for printer discovery
  services.avahi = mfunc.useDefault my.config.services.printing {
    enable = true;
    nssmdns = true;
  } {};

  # My own systemd services
  systemd.services = {

    # Auto start stuff
    starter = {
      script = lib.concatStrings (map (s: s + "\n") my.config.services.startup.start);
      wantedBy = [ "multi-user.target" ];
    };

    # Create and permit files
    createer = {
      script = lib.concatStrings (
        map (
          s:
          "touch ${s}" + "\n" +
          "chown :${my.config.system.filer} ${s}" + "\n" +
          "chmod g+rw ${s}" + "\n"
        )
        my.config.services.startup.create
      );
      wantedBy = [ "multi-user.target" ];
    };

    # Files permissions
    filer = {
      script = lib.concatStrings (
        map (
          s:
          "chown :${my.config.system.filer} ${s}" + "\n" +
          "chmod g+rw ${s}" + "\n"
        )
        my.config.services.startup.permit
      );
      wantedBy = [ "multi-user.target" ];
    };

  } // (mfunc.useDefault my.config.boot.top
  # Add gotop on TTY8 if wanted
  ({
    gotopper = {
      after = [ "getty.target" ];
      serviceConfig = {
        ExecStart = [ "${pkgs.gotop}/bin/gotop" ];
        Type = "idle";
        Restart = "always";
        RestartSec = "0";
        StandardInput = "tty";
        StandardOutput = "tty";
        TTYPath = "/dev/tty7";
        TTYReset = "yes";
        TTYVHangup = "yes";
        TTYVTDisallocate = "yes";
        IgnoreSIGPIPE = "no";
        SendSIGHUP = "yes";
        ExecStartPost = "${pkgs.kbd}/bin/chvt 7";
      };
      wantedBy = [ "multi-user.target" ];
    };
  }) {});

}
