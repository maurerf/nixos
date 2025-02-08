{ pkgs, config, ... }:
{
  home.username = "fdm";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [
    vim
    vscode
    spotify
    keepassxc
    telegram-desktop
    warp-terminal
    neofetch
  ];
  programs.home-manager = {
    enable = true;
  };
  nixpkgs.config.allowUnfree = true;
}
