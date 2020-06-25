args@{ lib, config, pkgs, utils, ... }:
let

  # My main config
  my = import ./config.nix { lib = lib; } ;

  # My functions
  mfunc = import ./functions/func.nix { lib = lib; };

  # Home manager
  home-manager = builtins.fetchGit "https://github.com/rycee/home-manager.git";

  # Unstable packages
  upkgs = import
    (builtins.fetchGit "https://github.com/nixos/nixpkgs")
    { config = config.nixpkgs.config; };

  # User repos
  nur = import (builtins.fetchGit "https://github.com/nix-community/NUR") { inherit pkgs; };

  # Generate the hardware folder location
  hardware-folder = ./config + ("/" + my.path);

  # Function for importing with all arguments
  impall = path: argolis: (import path (argolis // {
    my = my;
    mfunc = mfunc;
    upkgs = upkgs;
    nur = nur;
  }));

  # System specific hardware configuration
  un-imports-list = [ (hardware-folder + "/hardware.nix") ]
  ++
  # All the system modules
  [
    ./common/system/boot.nix
    ./common/system/packages.nix
    ./common/system/security.nix
    ./common/system/services.nix
    ./common/system/system.nix
  ] ++
  # Home manager
  [
    "${home-manager}/nixos"
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

  # Home manager importing list
  un-home-manager-imports-list = [
    # Non graphical packages I use
    ./common/user/hm-packages.nix
  ] ++
  # Visual imports for home-manager
  mfunc.useDefault my.config.graphical.enable ([
    # The visual ecosystem use
    ./common/user/video/hm-ecosystem.nix
    # Extra custom gui packages
    ./common/user/video/hm-packages.nix
    # Window manager configs
    ./common/user/video/hm-window-managers.nix
    # Games
  ] ++ mfunc.useDefault my.config.games [
    ./common/user/video/hm-games.nix
  ] []) [] ++
  mfunc.useDefault my.config.bluetooth [
    ./common/user/video/hm-bluetooth.nix
  ] [];

in {

  # Add the system import list
  imports = map (x: impall x args) un-imports-list;

  # Import the files needed for the home-manager package
  home-manager.users."${my.config.user.name}" = args@{ lib, config, pkgs, ... }: {
    imports = map (x: impall x args) un-home-manager-imports-list;
  };

}
