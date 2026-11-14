# VS Code for the Workstations, tuned for reading Markdown specs, diffs and Git
# rather than writing code. Fully declarative: settings.json is a read-only
# Nix symlink and the extensions directory holds only the declared extensions,
# so change both here. The Claude Code extension is left out; Claude runs in
# the terminal outside Nix (docs/decisions.md).
{ pkgs, lib, ... }:

let
  palette = import ./palette.nix;
in
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;

    profiles.default = {
      # Nix pins VS Code and its extensions.
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        bierner.markdown-mermaid
        bierner.markdown-preview-github-styles
        mhutchie.git-graph
        jnoortheen.nix-ide
      ];

      userSettings = {
        "editor.fontFamily" = "'CaskaydiaCove Nerd Font', monospace";
        "editor.fontLigatures" = false;
        "terminal.integrated.fontFamily" = "'CaskaydiaCove Nerd Font'";

        # Reading first: Markdown opens rendered, long lines wrap.
        "workbench.editorAssociations" = {
          "*.md" = "vscode.markdown.preview.editor";
        };
        "workbench.startupEditor" = "none";
        "editor.minimap.enabled" = false;
        "editor.wordWrap" = "on";
        "diffEditor.renderSideBySide" = true;
        "diffEditor.useInlineViewWhenSpaceIsLimited" = true;
        "files.autoSave" = "afterDelay";

        "git.autofetch" = true;
        "git.confirmSync" = false;

        "telemetry.telemetryLevel" = "off";
        "extensions.autoUpdate" = false;

        "nix.enableLanguageServer" = true;
        "nix.serverPath" = lib.getExe pkgs.nixd;

        # Default Dark Modern marks diffs and Git changes red vs green; use
        # palette blue for added and orange for removed or deleted instead.
        "workbench.colorCustomizations" = {
          "diffEditor.insertedTextBackground" = "${palette.blue}55";
          "diffEditor.insertedLineBackground" = "${palette.blue}33";
          "diffEditor.removedTextBackground" = "${palette.orange}55";
          "diffEditor.removedLineBackground" = "${palette.orange}33";
          "diffEditorGutter.insertedLineBackground" = "${palette.blue}55";
          "diffEditorGutter.removedLineBackground" = "${palette.orange}55";
          "diffEditorOverview.insertedForeground" = palette.blue;
          "diffEditorOverview.removedForeground" = palette.orange;
          "editorGutter.addedBackground" = palette.skyBlue;
          "editorGutter.modifiedBackground" = palette.yellow;
          "editorGutter.deletedBackground" = palette.orange;
          "editorOverviewRuler.addedForeground" = palette.skyBlue;
          "editorOverviewRuler.modifiedForeground" = palette.yellow;
          "editorOverviewRuler.deletedForeground" = palette.orange;
          "gitDecoration.addedResourceForeground" = palette.skyBlue;
          "gitDecoration.untrackedResourceForeground" = palette.skyBlue;
          "gitDecoration.modifiedResourceForeground" = palette.yellow;
          "gitDecoration.deletedResourceForeground" = palette.orange;
          "gitDecoration.conflictingResourceForeground" = palette.reddishPurple;
        };
      };
    };
  };
}
