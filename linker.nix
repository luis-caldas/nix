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

  # All the specific system hardware imports
  imports = map (x: ./hardware + ("/" + configgo.hardware.folder) + ("/" + x)) [ "boot.nix" "disks.nix" "cpu.nix" ]
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
    ./common/user/user.nix
    ./common/user/home.nix
  ] ++
  # Check whether we should import the graphical tools
  mfunc.useDefault configgo.graphical [
    # Add the hardware configuration as well
    (./hardware + ("/" + configgo.hardware.folder) + "/video/video.nix")
    # Normal user graphical config
    ./common/user/display/xorg.nix
  ] [];

  # Import the files needed for the home-manager package 
  home-manager.users."${configgo.user.name}" = { ... }:
  {

    imports = [
      ./common/user/packages.nix
    ] ++
    # Visual imports for home-manager
    mfunc.useDefault configgo.graphical [
      ./common/user/display/home.nix
      ./common/user/display/video.nix
      ./common/user/display/packages.nix
    ] [];

  };

}
