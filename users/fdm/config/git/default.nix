{ pkgs, ... }:

{
  # Git
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.git.enable

  programs.git.enable = true;

  programs.git.extraConfig = {
    pull.rebase = true;
  }

  programs.git.userEmail = "maurerfelix@protonmail.com";
  programs.git.userName = "Felix Maurer";
}
