{ pkgs, config, ... }:
  {
    home.username = "fdm";
    #home.homeDirectory = /home/fdm;
    home.stateVersion = "23.05";
    home.packages = with pkgs; [
      # --- CLI
      zsh-powerlevel10k
      vim
      git
      htop
      neofetch
      # -- FONTS
      #(pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
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
