{ pkgs, config, lib, stdenv, ... }:
  {
    home.username = "fdm";
    #home.homeDirectory = /home/fdm;
    home.stateVersion = "22.11";
    home.packages = with pkgs; [
      zsh-powerlevel10k
      vim
      spotify
      # ---- WALLETS
      electrum
      monero-gui
      # ---- COMMUNICATION
      discord
      signal-desktop
      tdesktop
      thunderbird
      zoom
      # ---- BROWSERS
      librewolf
      firefox
      tor-browser-bundle-bin
    ];
    programs.home-manager = {
      enable = true;
    };
    nixpkgs.config.allowUnfree = true;
    imports = builtins.concatMap import [
      ./config
    ];
  }
