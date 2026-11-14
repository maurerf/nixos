# Claude Code status line for the Workstations:
#   model · folder · branch (* when dirty) · ctx N% · 5h N%
# Claude Code itself is installed by hand (docs/deployment.md#manual-tools) and
# writes ~/.claude/settings.json at runtime, so Nix owns only the script and
# the settings' `statusLine` key, merged on activation; the rest of the file
# stays Claude's.
{ pkgs, lib, ... }:

let
  palette = import ./palette.nix;
  jq = lib.getExe pkgs.jq;

  # "#rrggbb" -> Bash ANSI-C string setting that 24-bit foreground colour.
  fg = hex:
    let
      channel = i: toString (lib.fromHexString (builtins.substring i 2 hex));
    in
    "$'\\e[38;2;${channel 1};${channel 3};${channel 5}m'";

  script = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [ pkgs.jq pkgs.git ];
    text = ''
      # Absent fields come back empty: rate_limits only exists for claude.ai
      # subscribers after the first API response; the context percentage can
      # be null early on. A unit separator, unlike a tab, keeps empty fields.
      IFS=$'\x1f' read -r model dir ctx fiveHour < <(
        jq -r '[
          .model.display_name // "",
          .workspace.current_dir // .cwd // "",
          (.context_window.used_percentage // "" | tostring),
          (.rate_limits.five_hour.used_percentage // "" | tostring)
        ] | join("\u001f")'
      )

      reset=$'\e[0m'
      sep=${fg palette.muted}' · '$reset

      # Higher usage reads brighter; the number stays the signal.
      usage() {
        local label=$1 pct=''${2%%.*} colour=${fg palette.muted}
        pct=''${pct:-0}
        if (( pct >= 80 )); then colour=${fg palette.vermillion}
        elif (( pct >= 50 )); then colour=${fg palette.yellow}
        fi
        printf '%s' "$sep$colour$label $pct%$reset"
      }

      out=${fg palette.skyBlue}$model$reset

      if [[ -n $dir ]]; then
        out+=$sep${fg palette.foreground}''${dir##*/}$reset
        if branch=$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null \
            || git -C "$dir" rev-parse --short HEAD 2>/dev/null); then
          out+=$sep${fg palette.bluishGreen}$branch$reset
          if [[ -n $(git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null) ]]; then
            out+=${fg palette.orange}'*'$reset
          fi
        fi
      fi

      [[ -z $ctx ]] || out+=$(usage ctx "$ctx")
      [[ -z $fiveHour ]] || out+=$(usage 5h "$fiveHour")

      printf '%s\n' "$out"
    '';
  };

  statusLineSetting = builtins.toJSON {
    type = "command";
    command = "~/.claude/statusline.sh";
  };
in
{
  # Stable path, so the merged setting does not change on every rebuild.
  home.file.".claude/statusline.sh".source = lib.getExe script;

  home.activation.claudeStatusLine = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    if [[ ! -e $settings && ! -L $settings ]]; then
      verboseEcho "Creating $settings with statusLine"
      run mkdir -p "$HOME/.claude"
      [[ -v DRY_RUN ]] || printf '{"statusLine":%s}\n' '${statusLineSetting}' > "$settings"
    elif ! ${jq} -e 'type == "object"' "$settings" > /dev/null 2>&1; then
      warnEcho "Not a readable JSON object, statusLine left unset: $settings"
    elif ! ${jq} -e --argjson want '${statusLineSetting}' \
        '.statusLine == $want' "$settings" > /dev/null; then
      verboseEcho "Merging statusLine into $settings"
      if [[ ! -v DRY_RUN ]]; then
        # Rewrite in place to keep the file's mode, owner and any symlink.
        merged=$(${jq} --argjson want '${statusLineSetting}' \
          '.statusLine = $want' "$settings")
        printf '%s\n' "$merged" > "$settings"
      fi
    fi
  '';
}
