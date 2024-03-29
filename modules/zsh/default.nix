{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    #syntaxHighlighting.enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    shellAliases = {
      lsa = "ls -alF";
      rebuild = "sudo nixos-rebuild switch";
      cdconf = "cd /etc/nixos/";
    };
    oh-my-zsh = {
       enable = true;
    #  plugins = [ "powerlevel10k" ];
    };
    plugins = [ 
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ./p10k-config;
        file = "p10k.zsh";
      }
      {
        name = "zsh-vi-mode";
        file = "./share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        src = pkgs.zsh-vi-mode;
      }
    ];
  };
}
