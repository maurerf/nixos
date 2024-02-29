{ programs, ... }:

{
  programs.git = {
    enable = true;
    userName  = "Felix Maurer";
    userEmail = "felix@maurerf.com";
    extraConfig = {
      pull.rebase = true;
    };
  };
}
  