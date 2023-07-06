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
      firefox
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
      jetbrains.idea-community maven jdk gcc12
      (vscode-with-extensions.override {
        vscodeExtensions = with vscode-extensions; [
          bbenoist.nix
          ms-vscode.cpptools
          ms-python.python
          haskell.haskell
          justusadam.language-haskell
          #vscodevim.vim
          github.vscode-pull-request-github
          #akamud.vscode-theme-onedark
        ];
      })
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
