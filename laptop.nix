{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.systemd.enable = true;
  #boot.plymouth.enable = true;
  #boot.plymouth.theme = "bgrt";
  boot.kernelParams = [ "quit" ];

  networking.hostName = "nixos-pc"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;
  #hardware.enableRedistributableFirmware = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable the X11 windowing system. TODO: doesnt this config use wayland?
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure GNOME
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gnome-connections
  ]) ++ (with pkgs.gnome; [
    gnome-music
    gnome-calendar
    gnome-weather
    gnome-contacts
    gnome-maps
    gedit # text editor
    epiphany # web browser
    geary # email reader
    evince # document viewer
    gnome-characters
    totem # video player
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
  ]);

  # Configure keymap in X11
  services.xserver = {
    layout = "de";
    xkbVariant = "";
  };

  # Configure console keymap
  console.keyMap = "de";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Set global default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.fdm = {
    isNormalUser = true;
    description = "fdm";
    initialPassword = "Password";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
        # Manages/Disables Screensaver
        gnomeExtensions.caffeine

        # Battery Indicator For Wireless Mouse/Keyboard/Headphones
        # gnomeExtensions.wireless-hid

        # System/Load Information Applet
        gnomeExtensions.vitals

        # i3 Style Workspaces
        gnomeExtensions.space-bar

        # Hide Apps in App Menu
        gnomeExtensions.app-hider

        # Clipboard History Applet
        gnomeExtensions.clipboard-indicator

        # Logo Applet (macos-Style)
        gnomeExtensions.logo-menu
    ];
   };
   
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable Steam
  # programs.steam.enable = true;

  # Enable Virtualbox
  # virtualisation.virtualbox.host.enable = true;
  # users.extraGroups.vboxusers.members = [ "fdm" ];

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Leave this unchanged
  system.stateVersion = "22.11"; # Did you read the comment?
}
