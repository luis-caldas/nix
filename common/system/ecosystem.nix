{ pkgs, ... }:
let

  # Create some aliases for the file commands
  programs.bash.shellAliases = {
    cp = "cp -i";
    mv = "mv -i";
    rm = "${pkgs.rmtrash}/bin/rmtrash";
    rmdir = "${pkgs.rmtrash}/bin/rmdirtrash";
  };

}
