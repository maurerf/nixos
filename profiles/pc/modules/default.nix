let
  more = { pkgs, ... }: {
    programs = {
      # one-line configs
      # none, currently
    };
  };
in
[ 
  # multi-line configs
  ./firefox
  ./vscode
  ./gtk
]
