{ config, pkgs, ... }:

{
  # NOTE: as this base module is hardware agnostic, you need to adjust boot loader settings locally before rebuilding
  
  services.openssh.enable = true;

  networking.networkmanager.enable = true;

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

  console.keyMap = "de";

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  users.users.fdm = {
    isNormalUser = true;
    initialPassword = "Password";
    extraGroups = [ "wheel" ];
   };
   
  nixpkgs.config.allowUnfree = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.05";
}