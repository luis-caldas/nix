{ ... }@args:
let

  # Build the whole functions set
  allFunctions = let

    # Import normal functions
    localFunctions = import ./functions.nix args;

    # Import the container functinos
    containerFunctions = import ./containers.nix args;

  # Join everything
  in (

    # Normal functions at the root
    localFunctions //
    # Extras on their own subcategory
    {
      container = containerFunctions;
    }
    
  );

in
{

  # Overlay for all the functions
  nixpkgs.overlays = [

    # The overlay
    (final: prev: {

      # The functions
      functions = allFunctions;

    })

  ];

}