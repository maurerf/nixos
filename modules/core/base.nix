{ config, pkgs, ... }:

{
  # NOTE: as this base module is hardware agnostic, you need to adjust boot loader settings locally before rebuilding
  
  # SSH
  services.openssh.enable = true;

  # Networking
  networking.networkmanager.enable = true;

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
  system.stateVersion = "24.05";
}