{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    extensions = with pkgs.vscode-extensions; [
      james-yu.latex-workshop
      jnoortheen.nix-ide
      ms-vscode.cpptools
      ms-python.python
      #vscodevim.vim
      github.vscode-pull-request-github
      github.copilot
    ];
  };
}
