{ ... }:
{

  # Import arion
  imports = [
     "${builtins.fetchGit "https://github.com/luis-caldas/arion"}/nixos-module.nix"
  ];

  # Set docker as backend
  virtualisation.arion.backend = "docker";

}