{ my, lib, pkgs, ... }:
{

  # Allow non free software
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # Needed for ZFS to work
  networking.hostId = my.id;

  # Enable Gnome Virtual Filesystem to browse shares
  services.gvfs.enable = true;

  # Add zfs scrubbing
  services.zfs.autoScrub.enable = true;

  # Add needed udev rules
  services.udev = {
    extraRules = ''
      # ZFS scheduler fix
      ACTION=="add|change", KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*", ENV{ID_FS_TYPE}=="zfs_member", ATTR{../queue/scheduler}="none"
      # Custom temperature sensor permissions
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="e025", MODE="0666"
      # Add group permissions to vfio
      SUBSYSTEM=="vfio", MODE="0660", GROUP="kvm"
      # Override tty group to use plugdev and create a static symlink to my serial usb
      SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", SYMLINK+="ttyRECOVER", MODE="0660", GROUP="plugdev"
    '';
  };

  # Fix extra remote codes on g20
  services.udev.extraHwdb = ''
    evdev:input:*v4842p0001*
      KEYBOARD_KEY_c0041=enter
      KEYBOARD_KEY_c00cf=search
  '';

  # Enable trimming when possible
  services.zfs.trim.enable = true;

  # Set the hostname
  networking.hostName = my.config.system.hostname; # Define your hostname.

  # Force the use of DHCP on the proper interface
  networking.useDHCP = false;

  # Use networkmanager
  networking.networkmanager.enable = true;

  # Use custom mac for cable
  networking.networkmanager.ethernet.macAddress = my.config.net.mac.cable;
  networking.networkmanager.wifi.macAddress = my.config.net.mac.wifi;

  # Disable ipv6
  networking.enableIPv6 = false;

  # Firewall configuration
  networking.firewall.enable = my.config.net.firewall.enable;
  networking.firewall.allowPing = my.config.net.firewall.ping;

  # Add my custom certificate authority
  security.pki.certificateFiles = [ "${my.projects.pub}/ssl/ca.pem" ];
  environment.sessionVariables = {
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    SYSTEM_CERTIFICATE_PATH = "/etc/ssl/certs/ca-bundle.crt";
  };

  # My timezone
  time.timeZone = my.config.system.timezone;

  # Set locale
  i18n.defaultLocale = my.config.system.locale;

  # Set default keyboard and their consoles
  services.xserver.layout = my.config.system.layout;
  console.useXkbConfig = true;

  # Enable ZRam if set
  zramSwap.enable = my.config.zram;
  zramSwap.memoryPercent = 50;

  # Set hardware switches
  services.logind.lidSwitch = "lock";
  services.logind.lidSwitchDocked = "lock";
  services.logind.lidSwitchExternalPower = "lock";
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
    HandleSuspendKey=ignore
    HandleHibernateKey=ignore
  '';

}
