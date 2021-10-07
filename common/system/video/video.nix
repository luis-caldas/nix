{ my, mfunc, config, pkgs, ... }:
{

  # Set graphics drivers
  services.xserver.videoDrivers = my.config.graphical.drivers;

  # Add 32 bit support and other acceleration packages
  hardware.opengl = {
    enable = true;
    # Select custom version of mesa drivers
    #package = pkgs.mesa.drivers;
  } //
  mfunc.useDefault my.config.x86_64 {
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
  } {};

}
