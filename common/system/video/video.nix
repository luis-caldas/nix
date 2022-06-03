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
  mfunc.useDefault ((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) {
    driSupport32Bit = true;
    extraPackages32 = with pkgs; [
      intel-ocl
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      pkgsi686Linux.libva
      rocm-opencl-icd
      rocm-opencl-runtime
    ];
    extraPackages = with pkgs; [
      intel-ocl
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      rocm-opencl-icd
      rocm-opencl-runtime
    ];
  } {};

}
