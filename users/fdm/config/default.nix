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

      ssh.enable = true;
    };
  };
in
[ 
  # multi-line configs
  # ./git
  ./zsh
]
