{ my, mfunc, pkgs, ... }:
let

  # Create a set with the proper files
  configFiles = {
    # Shell configuration
    bash = "source" + " " + my.projects.shell + "/shell/shell.bash";
    # Vim configuration
    vim = ''
      exec 'source' "'' + my.projects.vim + ''/vimrc.vim"
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

    # Configure XDG custom folders
    xdg.userDirs = {
      enable = true;
      desktop = "$HOME/home/desktop";
      documents = "$HOME/home/docs";
      download = "$HOME/home/downloads";
      music = "$HOME/home/mus";
      pictures = "$HOME/home/pics";
      publicShare = "$HOME/home/pub";
      templates = "$HOME/home/templates";
      videos = "$HOME/home/vids";
    };

    # Add ovmf path
    xdg.configFile."virt-ovmf".source = "${pkgs.OVMF.fd}/FV";

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

    # Add arduino libraries
    home.file = mfunc.useDefault my.config.x86_64
    { ".local/share/arduino" = { source = "${pkgs.arduino}/share/arduino"; }; }
    {};

  };

}
