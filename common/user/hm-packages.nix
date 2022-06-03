{ my, mfunc, pkgs, mpkgs, config, ... }:
{

  home.packages = with pkgs; [

    # Bin manipulation
    john
    flips
    xdelta
    hashcat
    radare2
    hexedit
    binutils
    geteltorito
    unixtools.xxd
    mpkgs.steghide
    python3Packages.binwalk-full

    # Disk
    pv
    duf
    ncdu
    parted
    testdisk
    smartmontools

    # Optical
    ccd2iso

    # Flashing tools
    avrdude
    heimdall
    dfu-programmer

    # Web tools
    w3m
    wget
    nmap
    aria
    bind
    atftp
    nload
    socat
    browsh
    firefox
    inetutils
    youtube-dl

    # Debugger
    gdb

    # Pen
    tor
    ncrack
    sqlmap
    thc-hydra

    # Sniffer
    wireshark

    # Keyboard
    xorg.xmodmap
    xdotool
    numlockx

    # Window manager manipulation
    wmctrl

    # Serial
    picocom
    minicom

    # Boot tools
    grub2
    (pkgs.writeShellScriptBin "grub-install-efi" "exec -a $0 ${grub2_efi}/bin/grub-install $@")
    efibootmgr

    # System monitoring
    usbutils
    pciutils

    # File manipulation
    tree
    file
    pigz
    p7zip
    unrar
    samba
    jdupes
    rdfind
    rmlint
    rmtrash

    # File systems
    sshfs
    jmtpfs
    archivemount

    # Virtualisation
    virt-manager

    # Optical disks
    cdrkit
    dvdplusrwtools

    # Net tools
    ntp
    lsof
    iperf
    ethtool
    bridge-utils
    shadowsocks-libev

    # Versioning
    subversion

    # Audio & Video manipulation
    potrace
    imagemagick
    libqrencode
    ffmpeg-full
    ghostscript
    waifu2x-converter-cpp
    python3Packages.pywal

    # Input
    xboxdrv
    mpkgs.x56linux
    linuxConsoleTools

    # EXIF
    exiftool

    # Android
    gitRepo
    simg2img

    # KVM & Virt
    qemu

    # Drives
    hdparm
    nvme-cli

    # Encryption
    gnupg
    openssl
    cryptsetup

    # Password managers
    bitwarden-cli

    # Password hash generator
    mkpasswd

    # User tools
    khal
    irssi
    _3llo
    neomutt
    tty-clock

    # Clipboard
    xclip

    # Image
    jp2a

    # Banner
    figlet

    # Logitech
    ltunify

    # Radio
    rtl-sdr

    # NFC
    pcsctools
    pcsclite

    # Bluetooth
    bluetooth_battery

    # Fetching packages
    pfetch
    neofetch
    screenfetch
    lsb-release

    # LLVM
    llvm

    # System
    stress
    evtest

    # Sensors
    lm_sensors

    #######
    # Dev #
    #######

    # Shell
    shellcheck
    xdg-user-dirs
    inotify-tools

    # C
    gcc
    cmake
    gnumake

    # Haskell
    ghc

    # JSON
    jq

    # Python
    python2Full
    python3Full

    # Ruby
    ruby

    # Javascript
    nodejs
    yarn
    nodePackages.http-server
    nodePackages.node2nix

    # Java
    adoptopenjdk-jre-openj9-bin-16

    # Markdown
    python3Packages.grip

    #######

  ] ++
  mfunc.useDefault ((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) [

    # Bin
    apktool

    # Flash utilities
    flashrom

  ] [] ++
  mfunc.useDefault my.config.services.fingerprint [
    fwupd
  ] [] ++
  mfunc.useDefault my.config.tex [ texlive.combined.scheme-medium ] [] ++
  mfunc.useDefault my.config.services.docker [ docker_compose ] [] ++
  mfunc.useDefault my.config.audio [

    # Local player
    cmus

    # Alsa tools
    alsaUtils

    # PulseAudio tools
    pulseaudio

    # Visualizer
    cli-visualizer

    # TUI mixer
    pamix
    ncpamixer

    # Patchers
    carla
    helvum

    # MPRIS controller
    playerctl

    # Morse code training
    aldo

  ] [];

}
