# VS Code for the Workstations, tuned for reading Markdown specs, diffs and Git
# rather than writing code. Fully declarative: settings.json is a read-only
# Nix symlink and the extensions directory holds only the declared extensions,
# so change both here. The Claude Code extension is left out because it would
# pin Claude with the flake; Claude runs in the terminal (docs/decisions.md).
{ pkgs, lib, ... }:

let
  palette = import ./palette.nix;

  # Sky blue for added, orange for removed, yellow for modified; two
  # alpha suffixes keep diff highlights from hiding the text.
  added = palette.skyBlue;
  removed = palette.orange;
  modified = palette.yellow;
  strong = "55";
  faint = "33";
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

        # Default Dark Modern marks diffs and Git changes red vs green.
        "workbench.colorCustomizations" = {
          "diffEditor.insertedTextBackground" = added + strong;
          "diffEditor.insertedLineBackground" = added + faint;
          "diffEditor.removedTextBackground" = removed + strong;
          "diffEditor.removedLineBackground" = removed + faint;
          "diffEditorGutter.insertedLineBackground" = added + strong;
          "diffEditorGutter.removedLineBackground" = removed + strong;
          "diffEditorOverview.insertedForeground" = added;
          "diffEditorOverview.removedForeground" = removed;
          "editorGutter.addedBackground" = added;
          "editorGutter.modifiedBackground" = modified;
          "editorGutter.deletedBackground" = removed;
          "editorOverviewRuler.addedForeground" = added;
          "editorOverviewRuler.modifiedForeground" = modified;
          "editorOverviewRuler.deletedForeground" = removed;
          "gitDecoration.addedResourceForeground" = added;
          "gitDecoration.untrackedResourceForeground" = added;
          "gitDecoration.renamedResourceForeground" = added;
          "gitDecoration.modifiedResourceForeground" = modified;
          "gitDecoration.stageModifiedResourceForeground" = modified;
          "gitDecoration.deletedResourceForeground" = removed;
          "gitDecoration.stageDeletedResourceForeground" = removed;
          "gitDecoration.conflictingResourceForeground" = palette.reddishPurple;
          "scmGraph.historyItemHoverAdditionsForeground" = added;
          "scmGraph.historyItemHoverDeletionsForeground" = removed;
        };
      };
    };
  };
}
