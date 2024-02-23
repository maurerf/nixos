{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ../hardware-configuration.nix
    ];

  # Bootloader
  #boot.loader.grub.enable = true;
  #boot.loader.grub.device = "nodev";
  #boot.loader.grub.efiSupport = true;
  #boot.loader.grub.useOSProber = true;

  # SSH
  services.openssh.enable = true;

  # Networking
  networking.networkmanager.enable = true;
  networking.hostName = "nixos-fdm";

  # Localisation
  time.timeZone = "Europe/Berlin";
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

  # Keymap
  console.keyMap = "de";

  # zsh
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # User 
  users.users.fdm = {
    isNormalUser = true;
    initialPassword = "Password";
    extraGroups = [ "wheel" ];
   };
   
  # Unfree packages
  nixpkgs.config.allowUnfree = false;

  # Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "23.05";
}
