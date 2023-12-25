{ my, mfunc, pkgs, ... }:
let

  # Default kernel params
  defaultKernelParams = [ "zfs_force=1" ];

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
  dynamicSpecialization = mkIf my.config.graphical.enable textConfig;

in
{

  # Custom grub entry with text mode boot
  specialisation = dynamicSpecialization;

  # Main boot configuration
  boot = {

    # Disable kernel messages at boot
    consoleLogLevel = 0;

    # Force kernel support for zfs and add user params
    kernelParams = defaultKernelParams ++ my.config.kernel.params ++
    # Check if we need to disable graphics
    (if (!my.config.graphical.enable) then textKernelParams else []);

  };

}
