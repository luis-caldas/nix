{ ... }:
let

  my = import ../../config.nix;

  # Get my wanted packages
  packages = {
    shell = builtins.fetchGit "https://github.com/luis-caldas/myshell";
    vim = builtins.fetchGit "https://github.com/luis-caldas/myvim";
  };

  # Create a set with the proper paths
  filesToLink = {
    # Shell configuration
    ${".profile"}.text = "source" + " " + packages.shell + "/shell/shell.bash";
    # Vim configuration
    ${".vimrc"}.text = ''
      exec 'source' "'' + packages.vim + ''/vimrc.vim"
    '';
  };

in
{

  # Configure base packages for the root user as well
  home-manager.users.root.home.file = filesToLink;

  # Configure packages for main user
  home-manager.users."${my.config.user.name}" = { ... }: {
    # Configure Git
    programs.git = {
      enable = true;
      userName = my.config.git.name;
      userEmail = my.config.git.email;
    };
    # Configure the base packages for the user
    home.file = filesToLink;
  };

}
