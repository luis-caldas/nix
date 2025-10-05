{ ... }:
{

  # Blacklisted kernel modules
  boot.blacklistedKernelModules = [
    # For NFC
    "pn533" "pn533_usb" "nfc"
  ];

  # Add needed udev rules
  # The uaccess tags dont work above priority 73, extra rules are 99
  services.udev = {
    extraRules = ''

      # ZFS scheduler fix
      ACTION=="add|change", KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*", ENV{ID_FS_TYPE}=="zfs_member", ATTR{../queue/scheduler}="none"

      # Custom temperature sensor permissions
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="e025", MODE="0660", GROUP="plugdev"

      # Add group permissions to vfio
      SUBSYSTEM=="vfio", MODE="0660", GROUP="kvm"

      # Override tty group to use plugdev and create a static symlink to my serial usb
      SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", SYMLINK+="ttyRECOVER", MODE="0660", GROUP="plugdev"

      # XGecu programmer
      SUBSYSTEM=="usb", ATTR{idVendor}=="a466", ATTR{idProduct}=="0a53", GROUP="plugdev", MODE="0660"

      # Hantek DSO-6022BL
      SUBSYSTEM=="usb", ACTION=="add", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="04b4", ATTRS{idProduct}=="602a", GROUP="plugdev", MODE="0660"
      SUBSYSTEM=="usb", ACTION=="add", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="04b5", ATTRS{idProduct}=="602a", GROUP="plugdev", MODE="0660"
      SUBSYSTEM=="usb", ACTION=="add", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="0925", ATTRS{idProduct}=="3881", GROUP="plugdev", MODE="0660"

      # Keychron
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", MODE="0660", GROUP="input"

      # Nintendo
      SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="3000", GROUP="plugdev", MODE="0660"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0955", ATTRS{idProduct}=="7321", GROUP="plugdev", MODE="0660"

    '';
  };

  # Fix extra remote codes on g20
  services.udev.extraHwdb = ''
    evdev:input:*v4842p0001*
      KEYBOARD_KEY_c0041=enter
      KEYBOARD_KEY_c00cf=search
  '';

  # Software defined radio
  hardware.rtl-sdr.enable = true;
  hardware.hackrf.enable = true;

  # Enable firmware
  hardware.enableRedistributableFirmware = true;

}