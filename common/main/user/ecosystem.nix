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
  programs.adb.enable = !pkgs.stdenv.hostPlatform.isAarch;

  # Add wireshark
  programs.wireshark.enable = config.mine.graphics.enable;

  # Enable bash auto completion
  programs.bash.enableCompletion = true;

  # Enable gnupg
  programs.gnupg.agent.enable = true;

  # Enable waydroid
  virtualisation.waydroid.enable = config.mine.services.virtual.android;

  # Add packages that dont work with home manager
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
    in {
      enable = true;
      desktop = "${commonBase}/desktop";
      documents = "${commonBase}/docs";
      download = "${commonBase}/downloads";
      music = "${commonBase}/mus";
      pictures = "${commonBase}/pics";
      publicShare = "${commonBase}/pub";
      templates = "${commonBase}/templates";
      videos = "${commonBase}/vids";
    };

    # Add ovmf path
    xdg.configFile =
    # Full omvf files only if not minimal
    (if ((!pkgs.stdenv.hostPlatform.isAarch) && (!config.mine.minimal)) then {
      "virt/ovmf".source = "${pkgs.OVMFFull.fd}";
    } else {}) //

    # QEmu only linked if not minial
    (if (!config.mine.minimal) then {
      "virt/qemu".source = "${pkgs.qemu}/share/qemu";
      "virt/win/qemu".source = "${pkgs.virtio-win}";
      "virt/win/spice".source = "${pkgs.win-spice}";
      "virt/win/virtio".source = "${pkgs.win-virtio}";
    } else {});

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
      (!pkgs.stdenv.hostPlatform.isAarch) && (!config.mine.minimal)
    ) then {
      ".local/share/arduino" = { source = "${pkgs.arduino}/share/arduino"; }; }
    else {};

    # Set the state version for the user
    home.stateVersion = config.system.stateVersion;

  };

}
