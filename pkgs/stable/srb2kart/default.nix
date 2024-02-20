{ newScope, ... }:

let

  callPackage = newScope self;

  self = {
    srb2kart-unwrapped = callPackage ./game.nix { };
    srb2kart-data = callPackage ./data.nix { };
    srb2kart-link = callPackage ./link.nix { };
    srb2kart = callPackage ./wrapper.nix { };
  };

in self.srb2kart
