{ my, mfunc, pkgs, ... }:
let

  # Create a set with the proper files
  configFiles = {
    # Shell configuration
    bash = ''
      source "${my.projects.shell}/shell/shell.bash"
      source "${my.projects.desktop.programs}/functions/functions.bash"
    '';
    # Vim configuration
    vim = ''
      exec 'source' "${my.projects.vim}/vimrc.vim"
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
  programs.adb.enable = ((my.arch == my.reference.x64) || (my.arch == my.reference.x86));

  # Add wireshark
  programs.wireshark.enable = true;

  # Enable bash auto completion
  programs.bash.enableCompletion = true;

  # Enable gnupg
  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "curses";
  };

  # Add packages that dont work with home-manager
  users.users."${my.config.user.name}".packages = mfunc.useDefault my.config.graphical.enable [

    # Office package
    pkgs.libreoffice

  ] [];

  # Configure base packages for the root user as well
  home-manager.users.root = { ... }: {
    programs = programsSet;
    home.stateVersion = my.version;
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
    xdg.configFile = (mfunc.useDefault (((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) && (!my.config.system.minimal)) {
      "virt/ovmf".source = "${pkgs.OVMFFull.fd}";
    } {}) // (mfunc.useDefault (!my.config.system.minimal) {
      "virt/qemu".source = "${pkgs.qemu}/share/qemu";
    } {}) // {
      "virt/win/qemu".source = "${pkgs.win-qemu}";
      "virt/win/spice".source = "${pkgs.win-spice}";
      "virt/win/virtio".source = "${pkgs.win-virtio}";
    };

    programs = programsSet //
    {

      # Configure Git
      git = {
        enable = true;
        userName = my.config.git.name;
        userEmail = my.config.git.email;
        package = pkgs.gitAndTools.gitFull;
        extraConfig = { pull = { rebase = false; }; init = { defaultBranch = "master"; }; };
      };

      # SSH configuration
      ssh = {
        enable = true;
        serverAliveInterval = 60;
        serverAliveCountMax = 5;
      };

    } //
    # Configure ncspot
    mfunc.useDefault my.config.audio {
      ncspot = {
        enable = true;
        settings = {
          gapless = true;
          notify = true;
        };
      };
    } {};

    # Add arduino libraries
    home.file = mfunc.useDefault (((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) && (!my.config.system.minimal))
    { ".local/share/arduino" = { source = "${pkgs.arduino}/share/arduino"; }; }
    {};

    # Set the state version for the user
    home.stateVersion = my.version;

  };

}
