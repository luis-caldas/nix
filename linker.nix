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
  hardware-folder = ./config + ("/" + my.path);

in
{

  # Linker for all submodules

  # System specific hardware configuration
  imports = [ (hardware-folder + "/hardware.nix") ]
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
  mfunc.useDefault my.config.graphical.enable ([
    # Install Xorg if graphics are on
    ./common/system/video/video.nix
    # Install preferred system wide gui applications
    ./common/system/video/packages.nix
  # Check if there is touchpad and graphical support
  ] ++ mfunc.useDefault my.config.graphical.touchpad [
    ./common/system/video/touchpad.nix
  ] []) [] ++ 
  # Check if audio is supported
  mfunc.useDefault my.config.audio [ ./common/system/audio.nix ] [] ++
  # Check if bluetooth is supported 
  mfunc.useDefault my.config.bluetooth (
    [ ./common/system/bluetooth.nix ] ++ 
    # Bluetooth and video are enabled
    mfunc.useDefault my.config.graphical.enable 
      [ ./common/system/video/bluetooth.nix ] []
  ) [];

  # Import the files needed for the home-manager package 
  home-manager.users."${my.config.user.name}" = { ... }:
  {

    imports = [
      # Non graphical packages I use
      ./common/user/hm-packages.nix
    ] ++
    # Visual imports for home-manager
    mfunc.useDefault my.config.graphical.enable [
      # The visual ecosystem use
      ./common/user/video/hm-ecosystem.nix
      # Extra custom gui packages
      ./common/user/video/hm-packages.nix
      # Window manager configs
      ./common/user/video/hm-window-managers.nix
    ] [] ++ 
    mfunc.useDefault my.config.bluetooth [ 
      ./common/user/video/hm-bluetooth.nix 
    ] [];

  };

}
