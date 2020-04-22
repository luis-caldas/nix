{ lib, ... }:
let

  # My main config
  configgo = import ./config.nix;

  # My functions
  mfunc = import ./functions/func.nix;

  # Home manager
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    ref = "release-" + configgo.version;
  };

in
{

  # Linker for all submodules

  # System specific hardware configuration
  imports = [ (./hardware + ("/" + configgo.hardware.folder) + "/hardware-configuration.nix") ]
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
  mfunc.useDefault configgo.graphical [
    # Install Xorg if graphics are on
    ./common/system/video/video.nix
    # Install preferred system wide gui applications
    ./common/system/video/packages.nix
    # Add the video hardware configuration as well
    (./hardware + ("/" + configgo.hardware.folder) + "/hardware-configuration-video.nix")
  ] [];

  # Import the files needed for the home-manager package 
  home-manager.users."${configgo.user.name}" = { ... }:
  {

    imports = [
      # Non graphical packages I use
      ./common/user/hm-packages.nix
    ] ++
    # Visual imports for home-manager
    mfunc.useDefault configgo.graphical [
      # The visual ecosystem use
      ./common/user/video/hm-ecosystem.nix
      # Extra custom gui packages
      ./common/user/video/hm-packages.nix
    ] [];

  };

}
