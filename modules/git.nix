{ pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Felix Maurer";
      user.email = "felix@maurerf.com";
      pull.rebase = false;
    };
  };
}