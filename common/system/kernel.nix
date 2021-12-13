{ my, mfunc, pkgs, ... }:
let

  # Default kernel params
  defaultKernelParams = [ "zfs_force=1" "nohibernate" ];

  # Params to set the kernel to text mode
  textKernelParams = [ "vga=normal" "nomodeset" ];

  # Config for text based system
  textConfig = {
    text.configuration = {
      boot.loader.grub.configurationName = "Text";
      boot.kernelParams = defaultKernelParams ++ textKernelParams;
    };
  };

  # Set the specialisation if needed
  dynamicSpecialization = mfunc.useDefault (!my.config.graphical.enable && my.config.kernel.text) {} textConfig;

in
{

  # Custom grub entry with text mode boot
  specialisation = dynamicSpecialization;

  # Main boot configuration
  boot = {

    # Disable pesky kernel messages at boot
    consoleLogLevel = 0;

    # Force kernel support for zfs and add user params
    kernelParams = defaultKernelParams ++ my.config.kernel.params ++
    mfunc.useDefault (!my.config.graphical.enable && my.config.kernel.text) textKernelParams [];

    # Blacklisted kernel modules
    # For RTL-SDR
    blacklistedKernelModules = [ "dvb_usb_rtl28xxu" ] ++
    # For NFC
    [ "pn533" "pn533_usb" "nfc" ];

  };

}
