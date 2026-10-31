{ ... }:
{

  # Create some aliases for the file commands
  programs.bash.shellAliases = {
    # Simple
    cp = "cp -i";
    mv = "mv -i";
    # Extra
    dig = "drill";
  };

  # Experimental features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

}
