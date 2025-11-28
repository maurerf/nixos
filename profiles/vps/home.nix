{ pkgs, config, ... }:
{
  home.username = "fdm";
  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    # --- CLI
    zsh-powerlevel10k
    vim_configurable
    git
    htop
    neofetch
    # -- FONTS
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
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
