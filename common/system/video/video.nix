{ my, mfunc, config, pkgs, ... }:
{

  # Allow xorg and the whole lot
  services.xserver.enable = true;
  services.xserver.autorun = false;

  # Use startx command to start wm
  services.xserver.displayManager.startx.enable = true;

  # Set graphics drivers
  services.xserver.videoDrivers = my.config.graphical.drivers;

  # Set program to change backlight
  programs.light.enable = true;

  # Add 32 bit support
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages32 = with pkgs; [
      intel-ocl
      rocm-opencl-icd
      rocm-opencl-runtime
      pkgsi686Linux.libva
    ];
    # Select custom version of mesa drivers
    #package = pkgs.mesa.drivers;
  };

}
