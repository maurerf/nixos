# Home Manager settings for the Workstations (hosts the user sits at): the Mac
# and desktop-pc. The VPS profile does not import this. Each profile sets
# programs.ghostty.package for its platform. Several packages are unfree, so
# the importing host must set nixpkgs.config.allowUnfree.
{ pkgs, ... }:

let
  palette = import ./palette.nix;
in
{
  imports = [
    ./git.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    vim
    htop
    yt-dlp
    vscode
    # spotify  # Temporarily disabled due to hash mismatch
    keepassxc
    telegram-desktop
    obsidian
    anki-bin
    rar
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];

  # Claude Code and the Codex CLI are installed manually with their official
  # self-updating installers, which put them in ~/.local/bin.
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;

  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "FiraCode Nerd Font";
      background = palette.background;
      foreground = palette.foreground;
      cursor-color = palette.skyBlue;
      selection-background = palette.border;
      selection-foreground = palette.foreground;
    };
  };
}
