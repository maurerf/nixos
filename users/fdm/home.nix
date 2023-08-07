{ pkgs, config, lib, stdenv, ... }:
  {
    home.username = "fdm";
    #home.homeDirectory = /home/fdm;
    home.stateVersion = "22.11";
    home.packages = with pkgs; [
      # --- CLI
      zsh-powerlevel10k
      vim_configurable
      git
      htop
      # ---- WALLETS
      electrum
      monero-gui
      # ---- COMMUNICATION
      discord
      signal-desktop
      element-desktop
      tdesktop
      thunderbird
      zoom-us
      # ---- BROWSERS
      tor-browser-bundle-bin
      # -- APPLICATIONS
      spotify
      arandr
      libreoffice
      vlc
      bleachbit
      keepassxc
      kleopatra
      # -- DEVELOPMENT
      texlive.combined.scheme-full 
      # -- FONTS
      (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    ];
    programs.home-manager = {
      enable = true;
    };
    nixpkgs.config.allowUnfree = true;
    imports = builtins.concatMap import [
      ./config
    ];
    fonts.fontconfig.enable = true;
  }
