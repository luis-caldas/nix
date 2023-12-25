{ ... }:
{

  # Start point of everything
  imports = [

    # Import all the configuration needed for the building
    start/config.nix

    # Link all the needed files and modules
    start/linker.nix

  ];

}
