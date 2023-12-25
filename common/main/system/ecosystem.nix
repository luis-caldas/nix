{ ... }:
{

  # Create some aliases for the file commands
  programs.bash.shellAliases = {
    cp = "cp -i";
    mv = "mv -i";
  };

}
