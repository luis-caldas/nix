{ my, pkgs, ... }:
let

  # Get my wanted packages
  packages = {
    shell = builtins.fetchGit "https://github.com/luis-caldas/myshell";
    vim = builtins.fetchGit {
      url = "https://github.com/luis-caldas/myvim";
      # fetchSubmodules = true;
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
    neovim = {
      enable = true;
      extraConfig = configFiles.vim;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };
  };

in
{

  # Enable adb debugging
  programs.adb.enable = my.config.x86_64;

  # Add wireshark
  programs.wireshark.enable = true;

  # Enable bash auto completion
  programs.bash.enableCompletion = true;

  # Configure base packages for the root user as well
  home-manager.users.root = { ... }: {
    programs = programsSet;
  };

  # Configure packages for main user
  home-manager.users."${my.config.user.name}" = { ... }: {

    programs = programsSet //
    # Configure Git
    { 
      git = {
        enable = true;
        userName = my.config.git.name;
        userEmail = my.config.git.email;
        package = pkgs.gitAndTools.gitFull;
        extraConfig = { pull = { rebase = false; }; init = { defaultBranch = "master"; }; };
      };}
    ;

  };

}
