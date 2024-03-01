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
    gnome-contacts
    gnome-maps
    gnome-clocks
    gnome-keyring
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
  environment.systemPackages = with pkgs; [
    gnomeExtensions.caffeine
    gnomeExtensions.vitals
  ];

  # Nvidia Drivers
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.opengl.enable = true;
  # hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

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
    # "Oracle_VM_VirtualBox_Extension_Pack"
    "steam"
    "steam-original"
    "steam-run"
  ];

  # Steam
  programs.steam.enable = true;

  # Virtualbox
  # virtualisation.virtualbox.host.enable = true;
  # users.extraGroups.vboxusers.members = [ "fdm" ];
  # virtualisation.virtualbox.host.enableExtensionPack = true;
  # virtualisation.virtualbox.guest.enable = true;
  # virtualisation.virtualbox.guest.x11 = true;
}
