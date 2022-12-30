args@{ my, lib, config, pkgs, utils, ... }:

# Do some assertions before starting the importing

# Touchpad + graphical asserion
assert lib.asserts.assertMsg
  (!(my.config.graphical.touchpad.enable && !my.config.graphical.enable))
  "Cannot enable touchpad without graphical mode";

# Touch + graphical assertion
assert lib.asserts.assertMsg
  (!(my.config.graphical.touch && !my.config.graphical.enable))
  "Cannot enable touch without graphical mode";

# Trackpoint + graphical assertion
assert lib.asserts.assertMsg
  (!(my.config.graphical.trackpoint.enable && !my.config.graphical.enable))
  "Cannot enable trackpoint without graphical mode";

# Audio production + audio assertion
assert lib.asserts.assertMsg
  (!(my.config.graphical.production.audio && !my.config.audio))
  "Cannot install audio production apps without audio";

# Audio production + graphical assertion
assert lib.asserts.assertMsg
  (!(my.config.graphical.production.audio && !my.config.graphical.enable))
  "Cannot install audio production apps without graphical mode";

# Video production + graphical assertion
assert lib.asserts.assertMsg
  (!(my.config.graphical.production.video && !my.config.graphical.enable))
  "Cannot enable video production without graphical mode";

# Model production + graphical assertion
assert lib.asserts.assertMsg
  (!(my.config.graphical.production.models && !my.config.graphical.enable))
  "Cannot enable model production without graphical mode";

# Electronics production + graphical assertion
assert lib.asserts.assertMsg
  (!(my.config.graphical.production.electronics && !my.config.graphical.enable))
  "Cannot enable electronics production without graphical mode";

let

  # My functions
  mfunc = import ./functions/func.nix { inherit lib; };

  # Home manager
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    ref = "release-" + my.version;
  };

  # Unstable packages
  upkgs = import
    (builtins.fetchGit "https://github.com/nixos/nixpkgs")
    { config = config.nixpkgs.config; };

  # My packages
  mpkgs = import ./pkgs/pkgs.nix { inherit pkgs upkgs; };

  # Generate the hardware folder location
  hardware-folder = ./config + ("/" + my.path);

  # Function for importing with all arguments
  impall = path: argolis: (import path (argolis // {
    inherit my mfunc mpkgs upkgs;
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
    ./common/system/exceptions.nix
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
    # Xorg config for user defined wm
    ./common/system/video/xorg.nix
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
  # Check if audio production is set
  mfunc.useDefault (my.config.audio && my.config.graphical.production.audio) [
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
    # Exceptions
    ./common/user/hm-exceptions.nix
  ] ++
  # Text based games
  mfunc.useDefault my.config.games [
    ./common/user/hm-games.nix
  ] [] ++
  # Visual imports for home-manager
  mfunc.useDefault (my.config.graphical.enable) [
    # The visual ecosystem use
    ./common/user/video/hm-ecosystem.nix
    # Extra custom gui packages
    ./common/user/video/hm-packages.nix
    # Window manager configs
    ./common/user/video/hm-window-managers.nix
  ] [] ++
  # Games
  mfunc.useDefault (my.config.graphical.enable && my.config.games) [
    ./common/user/video/hm-games.nix
  ] [] ++
  mfunc.useDefault my.config.bluetooth [
    ./common/user/video/hm-bluetooth.nix
  ] [];

in {

  # Set nix state version
  system.stateVersion = my.version;

  # Add the system import list
  imports = map (x: impall x args) un-imports-list;

  # Import the files needed for the home-manager package
  home-manager.users."${my.config.user.name}" = args@{ lib, config, pkgs, ... }: {

    # Import all home-manager files
    imports = map (x: impall x args) un-home-manager-imports-list;

  };

}
