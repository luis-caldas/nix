{ pkgs, ... }:
{

  # Simple packages to get any user going
  environment.systemPackages = with pkgs; [

    # File
    tree
    file

    # Encoding
    dos2unix

    # Compression
    pigz
    unar
    zip
    p7zip

    # Encryption
    gnupg
    openssl
    cryptsetup
    wireguard-tools

    # Password
    pwgen
    mkpasswd

    # Boot
    grub2
    grub2_efi
    efibootmgr

    # Disks
    hdparm
    hddtemp
    nvme-cli

    # Versioning
    git

    # Release
    lsb-release

    # Data
    pv

    # Pring
    ccze

    # Text
    less
    most
    unixtools.xxd

    # Editor
    neovim
    hexedit

    # Monitor
    htop
    gotop

    # GPU Top
    radeontop

    # OpenCL
    clinfo

    # Monitoring
    lsof
    psmisc
    sysstat

    # Stress
    stress
    evtest

    # Muxer
    tmux
    screen

    # Shell
    bc

    # Nix
    nix-du
    nix-top
    nix-tree
    nix-diff

    # XDG
    trash-cli
    xdg-user-dirs

    # Download
    wget

    # Networking
    nmap
    hping
    socat
    tcpdump
    tcping-go

    # Interfaces
    bridge-utils

    # Network Speed
    iperf

    # Network Tools
    ethtool
    iproute2
    shadowsocks-libev

    # Utils
    killall
    binutils
    moreutils
    v4l-utils
    inotify-tools

    # Compatibility
    envsubst

    # System Monitor
    lshw
    usbutils
    pciutils
    dmidecode

    # Sensors
    lm_sensors

    # Serial
    picocom
    minicom

  ];

}
