{ lib, config, ... }:
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
  dynamicSpecialization = lib.mkIf (config.mine.graphics.enable || !config.mine.kernel.text) textConfig;

in
{

  # Custom grub entry with text mode boot
  specialisation = dynamicSpecialization;

  # Main boot configuration
  boot = {

    # Disable kernel messages at boot
    consoleLogLevel = 0;

    # Set the kernel package to hardened
    kernelPackages = pkgs.linuxKernel.packages.linux_hardened;

    # Add params
    kernelParams = [] ++
    # Add the default ones
    defaultKernelParams ++
    # Add my own params
    config.mine.kernel.params ++
    # Check if we need to disable graphics
    (if (!config.mine.graphics.enable && config.mine.kernel.text) then textKernelParams else []);

  };

}
