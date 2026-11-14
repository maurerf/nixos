# Claude Code status line for the Workstations:
#   model · folder · branch (* when dirty) · ctx N% · 5h N%
# Claude Code itself is installed by hand (docs/deployment.md#manual-tools) and
# writes ~/.claude/settings.json at runtime, so Nix owns only the script and
# the settings' `statusLine` key, merged on activation; the rest of the file
# stays Claude's.
{ pkgs, lib, ... }:

let
  palette = import ./palette.nix;

  # "#rrggbb" -> 24-bit ANSI foreground escape.
  fg = hex:
    let
      channel = i: toString (lib.fromHexString (builtins.substring i 2 hex));
    in
    "\\033[38;2;${channel 1};${channel 3};${channel 5}m";

  statusLine = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [ pkgs.jq pkgs.git ];
    text = ''
      # Absent fields come back empty: rate_limits only exists for subscribers
      # after the first API response; context percentages can be null early on.
      # Unit separator, not tab: whitespace IFS would collapse empty fields.
      IFS=$'\x1f' read -r model dir ctx five < <(
        jq -r '[
          .model.display_name // "",
          .workspace.current_dir // .cwd // "",
          (.context_window.used_percentage // "" | tostring),
          (.rate_limits.five_hour.used_percentage // "" | tostring)
        ] | join("\u001f")'
      )

      reset='\033[0m'
      sep="${fg palette.muted} · $reset"

      # Higher usage reads brighter; the number stays the signal.
      level() {
        local pct=''${1%.*}
        if (( pct >= 80 )); then printf '%s' '${fg palette.vermillion}'
        elif (( pct >= 50 )); then printf '%s' '${fg palette.yellow}'
        else printf '%s' '${fg palette.muted}'
        fi
      }

      out="${fg palette.skyBlue}$model$reset$sep${fg palette.foreground}''${dir##*/}$reset"

      if branch=$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null \
          || git -C "$dir" rev-parse --short HEAD 2>/dev/null); then
        out+="$sep${fg palette.bluishGreen}$branch$reset"
        if [[ -n $(git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null) ]]; then
          out+="${fg palette.orange}*$reset"
        fi
      fi

      if [[ -n $ctx ]]; then
        out+="$sep$(level "$ctx")ctx ''${ctx%.*}%$reset"
      fi
      if [[ -n $five ]]; then
        out+="$sep$(level "$five")5h ''${five%.*}%$reset"
      fi

      printf '%b\n' "$out"
    '';
  };

  settingsKey = builtins.toJSON {
    type = "command";
    command = "~/.claude/statusline.sh";
  };
in
{
  # Stable path, so the merged key does not change on every rebuild.
  home.file.".claude/statusline.sh".source = lib.getExe statusLine;

  home.activation.claudeStatusLine = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    if [[ ! -e $settings ]]; then
      verboseEcho "Creating $settings with statusLine"
      run mkdir -p "$HOME/.claude"
      [[ -v DRY_RUN ]] || printf '{"statusLine":%s}\n' '${settingsKey}' > "$settings"
    elif ! ${lib.getExe pkgs.jq} -e 'type == "object"' "$settings" > /dev/null 2>&1; then
      warnEcho "Not a JSON object, statusLine left unset: $settings"
    elif ! ${lib.getExe pkgs.jq} -e --argjson key '${settingsKey}' \
        '.statusLine == $key' "$settings" > /dev/null; then
      verboseEcho "Merging statusLine into $settings"
      if [[ ! -v DRY_RUN ]]; then
        # Rewrite in place to keep the file's mode, owner and any symlink.
        merged=$(${lib.getExe pkgs.jq} --argjson key '${settingsKey}' \
          '.statusLine = $key' "$settings")
        printf '%s\n' "$merged" > "$settings"
      fi
    fi
  '';
}
