{ pkgs, lib, config, ... }:

let

  setResolution = pkgs.writeShellScript "setter" ''
    set -eu

    mode="$1"

    output="$(
      ${pkgs.wlr-randr}/bin/wlr-randr |
      ${pkgs.gawk}/bin/awk '
        /^[^[:space:]]/ { output = $1 }
        /Enabled: yes/ { print output; exit }
      '
    )"

    case "$mode" in
      auto)
        exec ${pkgs.wlr-randr}/bin/wlr-randr \
          --output "$output" \
          --on \
          --preferred \
          --scale 1
        ;;

      *)
        ${pkgs.wlr-randr}/bin/wlr-randr \
          --output "$output" \
          --mode "$mode" \
          --scale 1
        ;;
    esac
  '';

  swayConfig = pkgs.writeText "sway-config" ''
    input type:keyboard {
      xkb_layout gb
      xkb_options ctrl:nocaps
    }

    input type:touchpad {
      tap enabled
      natural_scroll enabled
    }

    output * bg #101010 solid_color scale 1

    font pango:sans 10

    default_border pixel 2
    default_floating_border pixel 2
    hide_edge_borders none

    gaps inner 8
    gaps outer 8
    smart_gaps off

    client.focused          #4c7899 #285577 #ffffff #2e9ef4 #285577
    client.focused_inactive #333333 #222222 #dddddd #222222 #222222
    client.unfocused        #333333 #202020 #bbbbbb #202020 #202020
    client.urgent           #aa0000 #900000 #ffffff #900000 #900000
    client.placeholder      #000000 #202020 #ffffff #202020 #202020
    client.background       #202020

    bar {
      swaybar_command ${pkgs.sway}/bin/swaybar
      position bottom
      height 28

      colors {
        statusline #eeeeee
        background #202020
        focused_workspace #285577 #285577 #ffffff
        inactive_workspace #202020 #202020 #bbbbbb
      }
    }

    focus_follows_mouse yes
    mouse_warping none

    floating_modifier Mod1 normal

    bindsym Mod4+Return exec ${pkgs.foot}/bin/foot
    bindsym Mod4+r exec ${pkgs.fuzzel}/bin/fuzzel

    bindsym Mod4+1 exec ${setResolution} 256x224
    bindsym Mod4+2 exec ${setResolution} 320x240
    bindsym Mod4+3 exec ${setResolution} 640x480
    bindsym Mod4+4 exec ${setResolution} 800x600
    bindsym Mod4+0 exec ${setResolution} auto

    bindsym XF86AudioRaiseVolume exec ${pkgs.wireplumber}/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
    bindsym XF86AudioLowerVolume exec ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bindsym XF86AudioMute exec ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    bindsym XF86AudioMicMute exec ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

    bindsym Alt+F4 kill

    bindsym Mod4+Left focus left
    bindsym Mod4+Down focus down
    bindsym Mod4+Up focus up
    bindsym Mod4+Right focus right

    bindsym Mod4+Shift+Left move left
    bindsym Mod4+Shift+Down move down
    bindsym Mod4+Shift+Up move up
    bindsym Mod4+Shift+Right move right

    bindsym Mod4+f fullscreen toggle
    bindsym Mod4+Shift+c reload
    bindsym Mod4+Shift+e exit
  '';

  session = pkgs.writeShellScriptBin "sway" ''
    set -eu
    exec ${pkgs.sway}/bin/sway --config ${swayConfig}
  '';

  desktopEntry = pkgs.makeDesktopItem {
    name = "simple";
    desktopName = "Simple";
    comment = "Minimal Sway Wayland";
    exec = "${session}/bin/sway";
    tryExec = "${pkgs.sway}/bin/sway";
    destination = "/share/wayland-sessions";
  };

  sessionPackage = pkgs.symlinkJoin {
    name = "sway";
    paths = [
      session
      desktopEntry
    ];
    passthru.providedSessions = [ "simple" ];
  };

in

lib.mkIf (config.mine.graphics.enable && config.mine.graphics.simple)

{
  services.displayManager.sessionPackages = [
    sessionPackage
  ];
}
