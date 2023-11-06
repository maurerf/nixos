{ pkgs, config, lib, stdenv, ... }:
  {
    home.username = "fdm";
    #home.homeDirectory = /home/fdm;
    home.stateVersion = "23.05";
    home.packages = with pkgs; [
      # --- CLI
      zsh-powerlevel10k
      vim_configurable
      git
      htop
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
