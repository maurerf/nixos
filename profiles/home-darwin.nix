{ pkgs, config, lib, ... }:
{
  home.username = "fdm";
  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    vim
    htop
    vscode
    # spotify  # Temporarily disabled due to hash mismatch
    keepassxc
    notion-app
    telegram-desktop
    obsidian
    anki-bin
    rar
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.droid-sans-mono
  ];
  programs.home-manager = {
    enable = true;
  };
  imports = [
    ../modules/git.nix
    ../modules/zsh.nix
  ];
  fonts.fontconfig.enable = true;
  targets.darwin.linkApps.enable = true;
}
