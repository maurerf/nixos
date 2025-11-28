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
    # -- FONTS (for cross-platform consistency)
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
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
