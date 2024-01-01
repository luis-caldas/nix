{ ... }:
{

  # Import arion
  imports = [
     "${builtins.fetchGit "https://github.com/hercules-ci/arion"}/nixos-module.nix"
  ];

  # Set docker as backend
  virtualisation.arion.backend = "docker";

}