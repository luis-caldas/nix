{ lib, ... }:
let

  # My main config
  my = import ./config.nix;

  # My functions
  mfunc = import ./functions/func.nix;

  # Home manager
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
  };

  # Generate the hardware folder location
  hardware-folder = ./systems + ("/" + my.path) + "/hardware";

in
{

  # Linker for all submodules

  # System specific hardware configuration
  imports = [ (hardware-folder + "/hardware-configuration.nix") ]
  ++
  # All the system modules
  [
    ./common/system/boot.nix
    ./common/system/packages.nix
    ./common/system/security.nix
    ./common/system/services.nix
    ./common/system/system.nix
  ] ++ 
  # Home user inclusion
  [
    (import "${home-manager}/nixos")
  ] ++
  # User config that does not use home manager
  [
    # User data such as password and name
    ./common/user/user.nix
    # The ecosystem I use
    ./common/user/ecosystem.nix
  ] ++
  # Check whether we should import the graphical tools
  mfunc.useDefault my.config.graphical [
    # Install Xorg if graphics are on
    ./common/system/video/video.nix
    # Install preferred system wide gui applications
    ./common/system/video/packages.nix
    # Add the video hardware configuration as well
    (hardware-folder + "/hardware-configuration-video.nix")
  ] [];

  # Import the files needed for the home-manager package 
  home-manager.users."${my.config.user.name}" = { ... }:
  {

    imports = [
      # Non graphical packages I use
      ./common/user/hm-packages.nix
    ] ++
    # Visual imports for home-manager
    mfunc.useDefault my.config.graphical [
      # The visual ecosystem use
      ./common/user/video/hm-ecosystem.nix
      # Extra custom gui packages
      ./common/user/video/hm-packages.nix
    ] [];

  };

}
