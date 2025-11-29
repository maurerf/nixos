{ pkgs, config, ... }:
{
  home.username = "fdm";
  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    vim
    htop
    neofetch
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
}
