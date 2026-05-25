{ ... }:
{

  # Entry point for everything
  imports = [

    # Import all configuration needed for the build
    start/config.nix

    # Link all the needed files and modules
    start/linker.nix

  ];

}
