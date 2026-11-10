{ pkgs, config, lib, ... }:
{
  home.username = "fdm";
  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    notion-app
  ];
  programs.ghostty.package = pkgs.ghostty-bin;
  programs.zsh.initContent = ''
    path=("$HOME/.nix-profile/bin" $path)
    typeset -U path
  '';
  imports = [
    ../modules/home-workstation.nix
  ];
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;
}
