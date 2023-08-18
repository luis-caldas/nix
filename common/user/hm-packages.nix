{ my, mfunc, pkgs, mpkgs, config, ... }:
{

  home.packages = with pkgs; [

    # Bin manipulation
    flips
    xdelta
    radare2
    hexedit
    binutils
    geteltorito
    unixtools.xxd

    # Disk
    pv
    f3
    duf
    ncdu
    parted
    zerofree
    testdisk
    ddrescue
    dislocker
    ventoy-full
    squashfsTools
    smartmontools

    # Optical
    bchunk
    ccd2iso

    # Flashing tools
    avrdude
    heimdall
    dfu-programmer

    # Web tools
    w3m
    frp
    wget
    nmap
    aria
    bind
    atftp
    nload
    socat
    knot-dns
    inetutils

    # Debugger
    gdb

    # Review
    nixpkgs-review

    # Pen
    tor
    ncrack
    sqlmap
    thc-hydra

    # Sniffer
    wireshark

    # Serial
    picocom
    minicom

    # Boot tools
    grub2
    (pkgs.writeShellScriptBin
      "grub-install-efi"
      "exec -a $0 ${grub2_efi}/bin/grub-install $@"
    )  # Grub EFI on the same system but with different name
    efibootmgr

    # System monitoring
    lshw
    usbutils
    pciutils

    # File manipulation
    tree
    file
    pigz
    (p7zip.override { enableUnfree = true; })  # Enable for rar and others
    unar
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
    hping
    ethtool
    bridge-utils
    shadowsocks-libev

    # Versioning
    subversion

    # Audio & Video manipulation
    potrace
    imagemagick
    qrencode
    ghostscript
    waifu2x-converter-cpp
    python3Packages.pywal

    # Input
    xboxdrv
    mpkgs.x56linux
    linuxConsoleTools

    # Kernel Drivers
    v4l-utils

    # EXIF
    exiftool

    # Android
    gitRepo
    simg2img

    # Video share
    scrcpy

    # Drives
    hdparm
    hddtemp
    nvme-cli

    # Encryption
    gnupg
    openssl
    cryptsetup
    wireguard-tools

    # Password
    pwgen
    mkpasswd
    bitwarden-cli

    # NFC
    mfoc
    mfcuk
    libnfc

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

    # Misc
    element

    # Terminal
    cbonsai
    pipes

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

    # JSON
    jq

    # XML & YAML
    python3Packages.yq

    # Python
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
    pandoc
    python3Packages.grip

    # Pentest
    john
    hashcat


    #######

  ] ++
  mfunc.useDefault (!my.config.system.minimal) [

    # Pentest
    metasploit
    steghide
    python3Packages.binwalk-full

    # Haskell
    ghc

    # Web
    browsh
    firefox
    youtube-dl

    # KVM & Virt
    qemu_full

    # Video
    ffmpeg-full

  ] [] ++
  mfunc.useDefault ((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) [

    # Flash utilities
    flashrom

  ] []++
  mfunc.useDefault (((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) && (!my.config.system.minimal)) [

    # Bin
    apktool

  ] [] ++
  mfunc.useDefault my.config.services.fingerprint [
    fwupd
  ] [] ++
  mfunc.useDefault my.config.tex [ texlive.combined.scheme-medium ] [] ++
  mfunc.useDefault my.config.services.docker [ docker-compose ] [] ++
  mfunc.useDefault my.config.audio [

    # Local player
    cmus

    # Tools
    pamixer
    pipewire
    alsaUtils
    pulseaudio

    # Visualizer
    cli-visualizer

    # TUI mixer
    pamix
    ncpamixer

    # MPRIS controller
    playerctl

    # Morse code training
    aldo

  ] [];

}
