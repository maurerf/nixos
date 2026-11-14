# Home Manager profile for desktop-pc: the Workstation module plus the
# Linux-only Niri session (Waybar, fuzzel, mako, swaylock/swayidle).
{ config, lib, pkgs, ... }:

let
  palette = import ../modules/palette.nix;
  # fuzzel and swaylock take colours without the leading "#".
  hex = colour: lib.removePrefix "#" colour;

  niriConfig = pkgs.replaceVars ./desktop-pc/niri.kdl {
    inherit (palette) background border muted;
    modKey = config.desktopPc.niriModKey;
    polkitAgent = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    # wpctl targets, not placeholders.
    DEFAULT_AUDIO_SINK = null;
    DEFAULT_AUDIO_SOURCE = null;
  };
  validatedNiriConfig = pkgs.runCommand "niri-config.kdl" { nativeBuildInputs = [ pkgs.niri ]; } ''
    niri validate -c ${niriConfig}
    cp ${niriConfig} $out
  '';
in
{
  imports = [
    ../modules/home-workstation.nix
  ];

  options.desktopPc.niriModKey = lib.mkOption {
    type = lib.types.enum [ "Super" "Alt" ];
    default = "Super";
    description = "Niri modifier key; the VM variant uses Alt because Windows captures Super.";
  };

  config = {
    home.username = "fdm";
    home.stateVersion = "26.05";

    programs.ghostty.package = pkgs.ghostty;

    home.packages = with pkgs; [
      firefox
      thunderbird
      swayidle
      bluetui
      kdePackages.filelight
      wl-clipboard
    ];

    xdg.configFile."niri/config.kdl".source = validatedNiriConfig;

    # Bar: workspace numbers left; volume, Bluetooth, network (only when
    # relevant), Tray and clock right. Text only.
    programs.waybar = {
      enable = true;
      settings.main = {
        layer = "top";
        position = "top";
        height = 26;
        spacing = 12;
        modules-left = [ "niri/workspaces" ];
        modules-right = [ "wireplumber" "bluetooth" "network" "tray" "clock" ];
        "niri/workspaces".format = "{index}";
        wireplumber = {
          format = "vol {volume}%";
          format-muted = "vol muted";
        };
        bluetooth = {
          format = "bt {status}";
          format-disabled = "bt off";
          format-connected = "bt {device_alias}";
          format-connected-battery = "bt {device_alias} {device_battery_percentage}%";
          on-click = "${pkgs.ghostty}/bin/ghostty --class=com.maurerf.bluetui --title=Bluetooth -e ${pkgs.bluetui}/bin/bluetui";
        };
        network = {
          format-ethernet = "";
          format-wifi = "wifi {essid}";
          format-linked = "net no ip";
          format-disconnected = "offline";
          tooltip = false;
        };
        tray.spacing = 8;
        clock = {
          format = "{:%a %d %b %H:%M}";
          locale = "en_US.UTF-8";
          tooltip = false;
        };
      };
      style = ''
        * {
          font-family: "FiraCode Nerd Font";
          font-size: 13px;
          border: none;
          border-radius: 0;
          min-height: 0;
        }
        window#waybar {
          background: ${palette.background};
          color: ${palette.foreground};
        }
        #workspaces button {
          padding: 0 6px;
          color: ${palette.muted};
          background: transparent;
        }
        #workspaces button.active {
          color: ${palette.foreground};
          box-shadow: inset 0 -2px ${palette.skyBlue};
        }
        #workspaces button.urgent {
          color: ${palette.orange};
        }
        #clock, #wireplumber, #bluetooth, #network, #tray {
          padding: 0 6px;
        }
        #wireplumber.muted, #network.disconnected {
          color: ${palette.orange};
        }
      '';
    };

    # Launcher: applications only, Super+Space.
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          font = "FiraCode Nerd Font:size=12";
          # Follow Niri's output scale instead of the monitor's reported DPI.
          dpi-aware = "no";
          terminal = "ghostty -e";
        };
        colors = {
          background = "${hex palette.background}f2";
          text = "${hex palette.foreground}ff";
          match = "${hex palette.skyBlue}ff";
          selection = "${hex palette.border}ff";
          selection-text = "${hex palette.foreground}ff";
          selection-match = "${hex palette.skyBlue}ff";
          border = "${hex palette.skyBlue}ff";
        };
      };
    };

    # Notifications: top right, 5 s, no sound.
    services.mako = {
      enable = true;
      settings = {
        anchor = "top-right";
        default-timeout = 5000;
        font = "FiraCode Nerd Font 11";
        background-color = palette.surface;
        text-color = palette.foreground;
        border-color = palette.skyBlue;
        border-size = 2;
        "urgency=high" = {
          border-color = palette.orange;
          default-timeout = 0;
        };
      };
    };

    # Lock screen: wrong vs verifying differ by orange vs blue, not red vs green.
    programs.swaylock = {
      enable = true;
      settings = {
        color = hex palette.background;
        font = "FiraCode Nerd Font";
        indicator-idle-visible = false;
        show-failed-attempts = true;
        inside-color = hex palette.surface;
        inside-clear-color = hex palette.surface;
        inside-ver-color = hex palette.surface;
        inside-wrong-color = hex palette.surface;
        ring-color = hex palette.border;
        ring-clear-color = hex palette.muted;
        ring-ver-color = hex palette.skyBlue;
        ring-wrong-color = hex palette.orange;
        key-hl-color = hex palette.skyBlue;
        bs-hl-color = hex palette.orange;
        line-color = "00000000";
        line-clear-color = "00000000";
        line-ver-color = "00000000";
        line-wrong-color = "00000000";
        separator-color = "00000000";
        text-color = hex palette.foreground;
        text-clear-color = hex palette.foreground;
        text-ver-color = hex palette.foreground;
        text-wrong-color = hex palette.orange;
      };
    };

    # Stock Adwaita dark for GTK; no custom theme. GTK4 reads the colour
    # scheme, GTK3 apps (the polkit agent) need the settings.ini preference.
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    # Qt does not recognise XDG_CURRENT_DESKTOP=niri and draws its own light
    # file dialog; route Qt apps (Telegram, KeePassXC) to the portal chooser.
    # Takes effect after re-login. https://github.com/maurerf/nixos/issues/58
    home.sessionVariables.QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
    gtk = {
      enable = true;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    };

    home.pointerCursor = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
      gtk.enable = true;
    };
  };
}
