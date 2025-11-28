{ pkgs, config, ... }:
{
  home.username = "fdm";
  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    vim
    vscode
    spotify
    keepassxc
    telegram-desktop
    warp-terminal
    neofetch
    # -- Migrated from Homebrew
    obsidian
    openscad
    cmake
    # -- FONTS (for cross-platform consistency)
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.droid-sans-mono
  ];
  programs.home-manager = {
    enable = true;
  };
  nixpkgs.config.allowUnfree = true;
  imports = builtins.concatMap import [
    ../../modules
  ];
  fonts.fontconfig.enable = true;
}
