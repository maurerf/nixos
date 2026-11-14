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
    ./claude-statusline.nix
    ./git.nix
    ./vscode.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    vim
    htop
    yt-dlp
    # spotify  # Temporarily disabled due to hash mismatch
    keepassxc
    telegram-desktop
    rar
    nerd-fonts.caskaydia-cove
    nerd-fonts.droid-sans-mono
  ];

  # Claude Code and the Codex CLI are installed manually with their official
  # self-updating installers, which put them in ~/.local/bin.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # GitHub CLI; also registers itself as Git's credential helper for github.com.
  # Log in once per Workstation with `gh auth login`.
  programs.gh.enable = true;

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;

  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "CaskaydiaCove Nerd Font";
      background = palette.background;
      foreground = palette.foreground;
      cursor-color = palette.skyBlue;
      selection-background = palette.border;
      selection-foreground = palette.foreground;
    };
  };
}
