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
    lz4

    # Encryption
    gnupg
    openssl
    cryptsetup
    wireguard-tools

    # Password
    pwgen
    mkpasswd

    # Boot
    sbctl
    grub2
    grub2_efi
    efibootmgr

    # Disks
    hdparm
    hddtemp
    nvme-cli
    smartmontools

    # Partitioning
    parted

    # iOS
    ifuse
    libheif
    libheif.out

    # Versioning
    git

    # Diff
    delta

    # Release
    lsb-release

    # Data
    pv

    # Printing
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

    # GPU monitoring
    radeontop

    # OpenCL
    clinfo

    # Monitoring
    lsof
    psmisc
    sysstat
    # witr  # TODO 26.05

    # Stress
    stress
    evtest

    # Muxer
    tmux
    screen

    # Shell
    bc

    # JSON
    jq
    jless

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

    # Network speed
    iperf

    # Network tools
    iw
    ethtool
    iproute2
    shadowsocks-rust

    # Utils
    killall
    binutils
    moreutils
    v4l-utils
    inotify-tools

    # Compatibility
    envsubst

    # System monitoring
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
