{ my, mfunc, lib, pkgs, mpkgs, ... }:
{

  # SSH
  services.openssh = {
    enable = my.config.services.ssh;
    # Enable X11 forwarding if graphical is enabled
    forwardX11 = my.config.services.ssh && my.config.graphical.enable;
    permitRootLogin = lib.mkForce "no";
  };

  # Enable avahi
  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  # Setup proxychains
  programs.proxychains = {
    enable = true;
    localnet = "127.0.0.0/255.0.0.0";
    quietMode = false;
    proxyDNS = true;
    proxies = {
      tor = {
        type = "socks5";
        host = "127.0.0.1";
        port = 9050;
      };
      local = {
        type = "socks5";
        host = "127.0.0.1";
        port = 30085;
      };
    };
  };

  # Vitualisation
  virtualisation.docker.enable = my.config.services.docker;

  # Set default backend
  virtualisation.oci-containers.backend = "docker";

  # libvirt config
  virtualisation.libvirtd = mfunc.useDefault my.config.services.virt.enable {
    enable = true;
    onBoot = "start";
    onShutdown = "shutdown";
    qemu.ovmf = {
      enable = true;
      packages = [ pkgs.OVMFFull.fd ];
    };
    qemu.swtpm.enable = my.config.services.virt.swtpm;
  } {};

  # Netdata monitor for servers and such
  services.netdata = mfunc.useDefault my.config.services.monitor {
    enable = true;
    extraPluginPaths = let
      myPlugins = pkgs.stdenv.mkDerivation rec {
        pname = "my-netdata-plugins";
        version = "0.0.1";
        dontUnpack = true;
        dontInstall = true;
        buildInputs = [ pkgs.makeWrapper ];
        buildPhase = ''
          mkdir -p "$out"
          cp "${my.projects.desktop.netdata}"/plugins/*.plugin "$out"/.
          for i in $out/*; do
            wrapProgram "$i" \
              --set PATH ${lib.makeBinPath (with pkgs; [
                nut iw apcupsd libreswan
                bash
                coreutils findutils
                unixtools.xxd
                gawk curl
                gnused gnugrep
              ])}
          done
        '';
      };
    in [ "${myPlugins}" ];
    config = {
      global = {
        "memory mode" = "dbengine";
        "page cache size" = 256;
        "dbengine multihost disk space" = 2048;
        "error log" = "stderr";
      };
    };
  } {};

  # PCSC
  services.pcscd = {
    enable = true;
    plugins = [ pkgs.acsccid ];
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
      (mfunc.useDefault (my.arch == my.reference.x64) [
        gutenprintBin
      ] []) ++
      (mfunc.useDefault ((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) [
        brgenml1lpr
        brgenml1cupswrapper
      ] []);
    browsing = true;
    browsedConf = "
      BrowseDNSSDSubTypes _cups,_print
      BrowseLocalProtocols All
      BrowseRemoteProtocols All
      BrowseProtocols All
      CreateIPPPrinterQueues All
      CreateIPPPrinterQueues driverless
    ";
    logLevel = "debug";
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
