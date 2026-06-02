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

  # Create the program set for users
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
      withRuby = true;
      withPython3 = true;
      plugins = with pkgs.vimPlugins; [
        coc-nvim
        vim-nix
        vim-fugitive
        vim-gitgutter
        vim-surround
        haskell-vim
        vim-lsp
      ];
    };
  };

in
{

  # Add Wireshark
  programs.wireshark.enable = config.mine.graphics.enable;

  # Enable bash auto completion
  programs.bash.completion.enable = true;

  # Enable GnuPG
  programs.gnupg.agent.enable = true;

  # Enable Waydroid
  virtualisation.waydroid.enable = config.mine.services.virtual.android;

  # Add packages that don't work with Home Manager
  users.users."${config.mine.user.name}".packages = if config.mine.graphics.enable then (with pkgs; [

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
    xdg.userDirs = let
      commonBase = "$HOME/home";
      altBase = "$HOME/play";
    in {
      enable = true;
      setSessionVariables = true;
      #
      desktop = "${commonBase}/desktop";
      documents = "${commonBase}/docs";
      download = "${commonBase}/downloads";
      music = "${commonBase}/mus";
      pictures = "${commonBase}/pics";
      videos = "${commonBase}/vids";
      projects = "${altBase}/projects";
      publicShare = "${altBase}/pub";
      templates = "${altBase}/templates";
    };

    # Add OVMF path
    xdg.configFile =
    # Full OVMF files when the system is not minimal
    (if ((!pkgs.stdenv.hostPlatform.isAarch) && (!config.mine.minimal)) then {
      "virt/ovmf".source = "${pkgs.OVMFFull.fd}";
    } else {}) //

    # Link QEMU only when the system is not minimal
    (if (!config.mine.minimal) then {
      "virt/qemu".source = "${pkgs.qemu}/share/qemu";
      "virt/win/qemu".source = "${pkgs.virtio-win}";
      "virt/win/spice".source = "${pkgs.win-spice}";
    } else {});

    # Default program configurations
    programs = programsSet //
    {

      # Configure Git
      git = {
        enable = true;
        settings = {
          user.name = config.mine.user.git.name;
          user.email = config.mine.user.git.email;
          pull.rebase = false;
          init.defaultBranch = "master";
        };
        package = pkgs.gitFull;
      };

      # SSH configuration
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."*" = {  # All servers
          serverAliveInterval = 60;
          serverAliveCountMax = 5;
        };
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

    # Add Arduino libraries
    home.file = if (
      (!pkgs.stdenv.hostPlatform.isAarch) && (!config.mine.minimal)
    ) then {
      ".local/share/arduino" = { source = "${pkgs.arduino}/share/arduino"; }; }
    else {};

    # Set the state version for the user
    home.stateVersion = config.system.stateVersion;

  };

}
