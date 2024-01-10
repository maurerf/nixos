{ pkgs, ... }:
{
  gtk = {
    enable = true;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "Numix-Cursor";
      package = pkgs.numix-cursor-theme;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

    dconf.settings = {
    # ...
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Console.desktop"
        "firefox.desktop"
        "org.telegram.desktop.desktop"
        "org.gnome.Nautilus.desktop"
        "thunderbird.desktop"
        "org.keepassxc.KeePassXC.desktop"
        "spotify.desktop"
        "steam.desktop"
        "virtualbox.desktop"
      ];
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
    };
    "org/gnome/desktop/background" = {
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/vnc-l.png";
      picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/vnc-d.png";
    };
    "org/gnome/desktop/screensaver" = {
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/vnc-d.png";
      primary-color = "#3465a4";
      secondary-color = "#000000";
    };
  };
}
