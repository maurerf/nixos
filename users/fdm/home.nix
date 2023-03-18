{ pkgs, config, lib, stdenv, ... }:
  {
    home.username = "fdm";
    #home.homeDirectory = /home/fdm;
    home.stateVersion = "22.11";
    home.packages = with pkgs; [
      zsh-powerlevel10k
      (import ./config/vim/default.nix)
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
