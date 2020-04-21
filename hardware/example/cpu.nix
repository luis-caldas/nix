{ lib, ... }:
{

  # Set the proper number of the max jobs
  nix.maxJobs = lib.mkDefault 1;

}
