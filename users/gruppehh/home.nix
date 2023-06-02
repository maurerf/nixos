{ pkgs, config, lib, stdenv, ... }:
  {
    home.username = "gruppehh";
    #home.homeDirectory = /home/gruppehh;
    home.stateVersion = "22.11";
    home.packages = with pkgs; [
      # --- CLI
      zsh-powerlevel10k
      (import ./config/vim/default.nix)
      git
      htop
      neofetch
      # ---- BROWSERS
      firefox
      tor-browser-bundle-bin
      # -- APPLICATIONS
      arandr
      tdesktop
      libreoffice
      vlc
      bleachbit
      keepassxc
      kleopatra
      # -- FONTS
      (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    ];
    programs.home-manager = {
      enable = true;
    };
    nixpkgs.config.allowUnfree = false;
    imports = builtins.concatMap import [
      ./config
    ];
    fonts.fontconfig.enable = true;
  }
