{ pkgs, config, ... }:
let

  # Create a set with the proper files
  configFiles = {
    # Shell configuration
    bash = ''
      source "${pkgs.reference.projects.shell}/shell/shell.bash"
      source "${pkgs.reference.projects.desktop}/programs/functions/functions.bash"
    '';
    # Vim configuration
    vim = ''
      exec 'source' "${pkgs.reference.projects.vim}/vimrc.vim"
    '';
  };

  # Create the programs set for users
  programsSet = {
    bash = {
      enable = true;
      # My files should always be at the end
      initExtra = configFiles.bash;
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
  programs.adb.enable = (pkgs.reference.arch == pkgs.reference.arches.x64) || (pkgs.reference.arch == pkgs.reference.arches.x86);

  # Add wireshark
  programs.wireshark.enable = true;

  # Enable bash auto completion
  programs.bash.enableCompletion = true;

  # Enable gnupg
  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "curses";
  };

  # Add packages that dont work with home manager
  users.users."${config.mine.user.name}".packages = if config.mine.graphical.enable then (with pkgs; [

    # Office package
    libreoffice

  ]) else [];

  # Configure base packages for the root user as well
  home-manager.users.root = { ... }: {
    programs = programsSet;
    home.stateVersion = config.system.stateVersion;
  };

  # Configure packages for main user
  home-manager.users."${config.mine.user.name}" = { ... }: {

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
    xdg.configFile =
    # Full omvf files only if not minimal
    (if (
      ((pkgs.reference.arch == pkgs.reference.arches.x64) || (pkgs.reference.arch == pkgs.reference.arches.x86))
      && (!config.mine.system.minimal)
    ) then {
      "virt/ovmf".source = "${pkgs.OVMFFull.fd}";
    } else {}) //

    # QEmu only linked if not minial
    (if (!config.mine.system.minimal) then {
      "virt/qemu".source = "${pkgs.qemu}/share/qemu";
    } else {}) //

    # Normally linked
    {
      "virt/win/qemu".source = "${pkgs.virtio-win}";
      "virt/win/spice".source = "${pkgs.win-spice}";
      "virt/win/virtio".source = "${pkgs.win-virtio}";
    };

    # Default program configurations
    programs = programsSet //
    {

      # Configure Git
      git = {
        enable = true;
        userName = config.mine.user.git.name;
        userEmail = config.mine.user.git.email;
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
    (if config.mine.audio then {
      ncspot = {
        enable = true;
        settings = {
          gapless = true;
          notify = true;
        };
      };
    } else {});

    # Add arduino libraries
    home.file = if (
      ((pkgs.reference.arch == pkgs.reference.arches.x64) || (pkgs.reference.arch == pkgs.reference.arches.x86))
      && (!config.mine.system.minimal)
    ) then {
      ".local/share/arduino" = { source = "${pkgs.arduino}/share/arduino"; }; }
    else {};

    # Set the state version for the user
    home.stateVersion = config.system.stateVersion;

  };

}
