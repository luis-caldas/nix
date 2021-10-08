args@{ my, lib, config, pkgs, utils, ... }:
let

  # My functions
  mfunc = import ./functions/func.nix { inherit lib; };

  # Extract this version from nixpkgs
  versionList = lib.splitString "." lib.version;
  versionConcatenated = (
    builtins.elemAt versionList 0 +
    "." +
    builtins.elemAt versionList 1
  );

  # System Version
  version = versionConcatenated;

  # Home manager
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    ref = ("release-" + version);
  };

  # Unstable packages
  upkgs = import
    (builtins.fetchGit "https://github.com/nixos/nixpkgs")
    { config = config.nixpkgs.config; };

  # My packages
  mpkgs = import ./pkgs/pkgs.nix { inherit pkgs upkgs; };

  # NUR user repos
  nur = import (builtins.fetchGit "https://github.com/nix-community/NUR") { inherit pkgs; };

  # Generate the hardware folder location
  hardware-folder = ./config + ("/" + my.path);

  # Function for importing with all arguments
  impall = path: argolis: (import path (argolis // {
    inherit my mfunc mpkgs upkgs nur;
  }));

  # System specific hardware configuration
  un-imports-list = [ (hardware-folder + "/hardware.nix") ]
  # Local options for local packages
  ++
  [ ./pkgs/options.nix ] ++
  # All the system modules
  [
    ./common/system/boot.nix
    ./common/system/kernel.nix
    ./common/system/drivers.nix
    ./common/system/ecosystem.nix
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
  mfunc.useDefault my.config.graphical.enable [
    # Install Xorg if graphics are on
    ./common/system/video/video.nix
    # Install preferred system wide gui applications
    ./common/system/video/packages.nix
  ] [] ++
  # Xorg configs for graphical interfaces
  mfunc.useDefault (my.config.graphical.enable && !my.config.graphical.kodi) [
    # Xorg config for user defined wm
    ./common/system/video/xorg.nix
  ] [] ++
  # Kodi config
  mfunc.useDefault (my.config.graphical.enable && my.config.graphical.kodi) [
    # Kodi xorg and app configs
    ./common/system/video/kodi.nix
  ] [] ++
  # Check if there is touchpad and graphical support
  mfunc.useDefault (my.config.graphical.enable && my.config.graphical.touchpad.enable) [
    ./common/system/video/touchpad.nix
  ] [] ++
  # Check if there is trackpoint
  mfunc.useDefault (my.config.graphical.enable && my.config.graphical.trackpoint.enable) [
    ./common/system/video/trackpoint.nix
  ] [] ++
  # Check if audio is supported
  mfunc.useDefault my.config.audio [ ./common/system/audio.nix ] [] ++
  # Set config for games
  mfunc.useDefault (
    my.config.graphical.enable && (my.config.games || my.config.graphical.kodi)
  ) [
    ./common/system/video/games.nix
  ] [] ++
  # Check if audio production is set
  mfunc.useDefault (my.config.audio && my.config.graphical.production.audio && !my.config.graphical.kodi) [
    ./common/system/production.nix
  ] [] ++
  # Check if bluetooth is supported
  mfunc.useDefault my.config.bluetooth [ ./common/system/bluetooth.nix ] [] ++
  # Bluetooth and video are enabled
  mfunc.useDefault (my.config.bluetooth && my.config.graphical.enable) [
    ./common/system/video/bluetooth.nix
  ] [];

  # Home manager importing list
  un-home-manager-imports-list = [
    # Non graphical packages I use
    ./common/user/hm-packages.nix
  ] ++
  # Text based games
  mfunc.useDefault my.config.games [
    ./common/user/hm-games.nix
  ] [] ++
  # Visual imports for home-manager
  mfunc.useDefault (my.config.graphical.enable && !my.config.graphical.kodi) [
    # The visual ecosystem use
    ./common/user/video/hm-ecosystem.nix
    # Extra custom gui packages
    ./common/user/video/hm-packages.nix
    # Window manager configs
    ./common/user/video/hm-window-managers.nix
  ] [] ++ 
  # Games
  mfunc.useDefault (my.config.graphical.enable && my.config.games && !my.config.graphical.kodi) [
    ./common/user/video/hm-games.nix
  ] [] ++
  mfunc.useDefault my.config.bluetooth [
    ./common/user/video/hm-bluetooth.nix
  ] [];

in {

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Add the system import list
  imports = map (x: impall x args) un-imports-list;

  # Import the files needed for the home-manager package
  home-manager.users."${my.config.user.name}" = args@{ lib, config, pkgs, nixpkgs, ... }: {

    # Allow unfree packages on home-manager as well
    nixpkgs.config.allowUnfree = true;

    # Import all home-manager files
    imports = map (x: impall x args) un-home-manager-imports-list;

  };

}
