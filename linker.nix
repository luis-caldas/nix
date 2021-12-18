args@{ my, oattrs, lib, config, pkgs, utils, ... }:

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

# Model production + graphical assertion
assert lib.asserts.assertMsg
  (!(my.config.graphical.production.models && !my.config.graphical.enable))
  "Cannot enable model production without graphical mode";

# Electronics production + graphical assertion
assert lib.asserts.assertMsg
  (!(my.config.graphical.production.electronics && !my.config.graphical.enable))
  "Cannot enable electronics production without graphical mode";

let

  # Inherit some vars
  inherit (oattrs) mfunc;

  # Generate the hardware folder location
  hardware-folder = ./config + ("/" + my.path);

  # Function for importing with all arguments
  importWithAll = path: extraArguments:
  let
    allArguments =
      args //
      { inherit my; inherit (oattrs) mfunc mpkgs upkgs; } //
      extraArguments;
  in
    import path (builtins.trace ("importWithAll - " + my.name + " " + path + " - " + (builtins.elemAt my.config.graphical.display.extraCommands 0)) allArguments);

  # System specific hardware configuration
  un-imports-list = [ (hardware-folder + "/hardware.nix") ]
  # Local options for local packages
  ++
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
  ] ++
  # Text based games
  mfunc.useDefault my.config.games [
    ./common/user/hm-games.nix
  ] [] ++
  # Visual imports for home-manager
  mfunc.useDefault my.config.graphical.enable [
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

  # Default general configs
  defaultConfigHomeManager = {
    # Allow unfree packages on home-manager as well
    nixpkgs.config.allowUnfree = true;
  };
  # Merge all home-manager modules
  hm-merged = lib.mkMerge (
    [ defaultConfigHomeManager ] ++
    (map (eachImport: importWithAll eachImport oattrs.home-manager-modules) un-home-manager-imports-list)
  );

  # Create default config
  defaultConfig = {
    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;
    # Import the files needed for the home-manager package
    home-manager.users."${my.config.user.name}" = hm-merged;
  };
  # Merge all the possible data
  merged = lib.mkMerge (
    [ (builtins.trace defaultConfig.home-manager.users.majora.contents defaultConfig) ] ++
    (map (eachImport: importWithAll eachImport {}) un-imports-list)
  );

in merged
