{ ... }:
let

  my = import ../../config.nix;

  # Get my wanted packages
  packages = {
    shell = builtins.fetchGit "https://github.com/luis-caldas/myshell";
    vim = builtins.fetchGit {
      url = "https://github.com/luis-caldas/myvim";
      # submodules = true;
    };
  };

  # Create a set with the proper files
  configFiles = {
    # Shell configuration
    bash = "source" + " " + packages.shell + "/shell/shell.bash";
    # Vim configuration
    vim = ''
      exec 'source' "'' + packages.vim + ''/vimrc.vim"
    '';
  };

  # Create the programs set for users
  programsSet = {
    bash = { 
      enable = true;
      bashrcExtra = configFiles.bash;
    }; 
    vim = {
      enable = true;
      extraConfig = configFiles.vim;
    };
  };

in
{

  # Configure base packages for the root user as well
  home-manager.users.root = { ... }: {
    programs = programsSet;
  };

  # Configure packages for main user
  home-manager.users."${my.config.user.name}" = { ... }: {
    
    programs = programsSet //
    # Configure Git
    { git = {
      enable = true;
      userName = my.config.git.name;
      userEmail = my.config.git.email;
    };};

  };

}
