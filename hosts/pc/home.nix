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
      nix-output-monitor
      neofetch
      # ---- WALLETS
      electrum
      monero-gui
      # ---- COMMUNICATION
      discord
      signal-desktop
      element-desktop
      telegram-desktop
      thunderbird
      zoom-us
      whatsapp-for-linux
      # ---- BROWSERS
      tor-browser-bundle-bin
      # -- APPLICATIONS
      spotify
      arandr
      libreoffice
      vlc
      bleachbit
      filelight
      keepassxc
      kleopatra
      # -- FONTS
      (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    ];
    programs.home-manager = {
      enable = true;
    };
    nixpkgs.config.allowUnfree = true;
    imports = builtins.concatMap import [
      ../../modules
      ./modules
    ];
    fonts.fontconfig.enable = true;
  }
