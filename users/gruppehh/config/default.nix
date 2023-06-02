let
  more = { pkgs, ... }: {
    programs = {
      # one-line configs
      gpg.enable = true;

      htop = {
        enable = true;
        settings = {
          sort_direction = true;
          sort_key = "PERCENT_CPU";
        };
      };

      git = {
        enable = true;
        userName = "Felix Maurer";
        userEmail = "maurerfelix@protonmail.com";
      };

      ssh.enable = true;
    };
  };
in
[ 
  # multi-line configs
  # ./git TODO: fix
  ./zsh
]
