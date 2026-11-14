# Claude Code status line for the Workstations:
#   model · folder · branch (* when dirty) · Context: 70k (7%) · 5h: 33% left
# Claude Code itself is installed by hand (docs/deployment.md#manual-tools) and
# writes ~/.claude/settings.json at runtime, so Nix owns only the script and
# the settings' `statusLine` key, merged on activation; the rest of the file
# stays Claude's.
{ pkgs, lib, ... }:

let
  palette = import ./palette.nix;
  jq = lib.getExe pkgs.jq;

  # Vermillion above the context limit and below the 5h floor, compared as
  # displayed (rounded). 150k tokens roughly ends current models' "smart
  # zone"; revisit when new Claude models ship.
  contextWarnThousands = 150;
  fiveHourWarnLeftPercent = 25;

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
      # Absent fields come back empty: current_usage is null before the first
      # API response and right after /compact; rate_limits exists only for
      # claude.ai subscribers after the first response. Context tokens count
      # input only, as Claude's own used_percentage does. A unit separator,
      # unlike a tab, keeps empty fields.
      IFS=$'\x1f' read -r model dir ctxTokens ctxPercent fiveHourLeft < <(
        jq -r '
          .context_window as $cw
          | ($cw.current_usage // null) as $u
          | [
              .model.display_name // "",
              .workspace.current_dir // .cwd // "",
              (if $u then ($u.input_tokens // 0)
                  + ($u.cache_creation_input_tokens // 0)
                  + ($u.cache_read_input_tokens // 0)
               else "" end),
              ($cw.used_percentage // "" | if . == "" then . else round end),
              (.rate_limits.five_hour.used_percentage // ""
                | if . == "" then . else [100 - . | round, 0] | max end)
            ]
          | map(tostring) | join("\u001f")'
      )

      reset=$'\e[0m'
      normal=${fg palette.muted}
      warn=${fg palette.vermillion}
      sep=$normal' · '$reset

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

      if [[ -n $ctxTokens ]]; then
        ctxThousands=$(( (ctxTokens + 500) / 1000 ))
        colour=$normal
        (( ctxThousands <= ${toString contextWarnThousands} )) || colour=$warn
        out+="$sep''${colour}Context: ''${ctxThousands}k"
        [[ -z $ctxPercent ]] || out+=" ($ctxPercent%)"
        out+=$reset
      fi

      if [[ -n $fiveHourLeft ]]; then
        colour=$normal
        (( fiveHourLeft >= ${toString fiveHourWarnLeftPercent} )) || colour=$warn
        out+="$sep''${colour}5h: $fiveHourLeft% left$reset"
      fi

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
