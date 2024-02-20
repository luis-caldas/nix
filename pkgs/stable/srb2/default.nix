{ newScope, ... }:

let

  callPackage = newScope self;

  self = {
    srb2-unwrapped = callPackage ./game.nix { };
    srb2-data = callPackage ./data.nix { };
    srb2-link = callPackage ./link.nix { };
    srb2 = callPackage ./wrapper.nix { };
  };

in self.srb2
