{ config, pkgs, lib, ... }:

{
  imports =
    [ 
      ./minimal.nix
    ];

  # Bootloader TODO FIXME
  #boot.loader.systemd-boot.enable = true;
  #boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";

  #boot.initrd.systemd.enable = true;
  #boot.plymouth.enable = true;
  #boot.plymouth.theme = "bgrt";
  #boot.kernelParams = [ "quit" ];

  # XServer
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver = {
    xkb.layout = "de";
    xkb.variant = "";
  };
  services.xserver.displayManager.gdm.wayland = false;

  # GNOME
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gnome-connections
    gedit # text editor
  ]) ++ (with pkgs.gnome; [
    gnome-music
    gnome-calendar
    gnome-weather
    gnome-clocks
    gnome-keyring
    gnome-contacts
    gnome-maps
    epiphany # web browser
    geary # email reader
    evince # document viewer
    gnome-characters
    totem # video player
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
    yelp # help app
    simple-scan # document scanner
  ]);

  # CUPS (printing)
  services.printing.enable = true;

  # Sound
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Overlays
  nixpkgs.overlays = [
    (final: prev: {
      gnome = prev.gnome.overrideScope' (gnomeFinal: gnomePrev: {
        mutter = gnomePrev.mutter.overrideAttrs ( old: {
          src = pkgs.fetchgit {
            url = "https://gitlab.gnome.org/vanvugt/mutter.git";
            # GNOME 45: triple-buffering-v4-45
            rev = "0b896518b2028d9c4d6ea44806d093fd33793689";
            sha256 = "sha256-mzNy5GPlB2qkI2KEAErJQzO//uo8yO0kPQUwvGDwR4w=";
          };
        } );
      });
    })
  ];
   
  # Unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "vscode"
    "vscode-extension-ms-vscode-cpptools"
    "vscode-extension-github-copilot"
    "discord"
    "spotify"
  ];
}
