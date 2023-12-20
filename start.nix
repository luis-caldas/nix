{ ... }:
{

  # Start point for everything
  imports = [

    # Default per device configuration and organising
    start/config.nix

    # General linker that loads all the necessary files
    start/linker.nix

  ];

}
