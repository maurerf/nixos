# Niri binds for desktop-pc: the one list behind Niri's `binds {}` block, its
# hotkey overlay (Mod+F1) and the fuzzel command palette (Mod+Shift+Space).
# profiles/home-desktop-pc.nix renders both. Each entry:
#   key     Niri key; "Mod+" becomes the configured modifier (Super, or Alt in
#           the VM). Niri matches the unshifted key of the de layout, so keys
#           that need Shift or AltGr there (/, =, [, ]) never fire.
#   title   overlay and palette description.
#   action  Niri action; args are its arguments (strings or integers).
#   props   optional KDL bind properties.
#   overlay false hides the bind from the overlay; the palette lists every bind.
# https://github.com/maurerf/nixos/issues/66
{ lib }:

let
  bind = key: title: action: args: { inherit key title action args; };
  hidden = entry: entry // { overlay = false; };
  withProps = props: entry: entry // { inherit props; };
  workspaces = f: lib.genList (i: f (i + 1)) 9;
in
[
  (bind "Mod+F1" "Show this hotkey overlay" "show-hotkey-overlay" [ ])
  (bind "Mod+Shift+Space" "Search and run a bind" "spawn" [ "niri-bind-palette" ])

  (bind "Mod+Return" "Open a terminal: Ghostty" "spawn" [ "ghostty" ])
  (bind "Mod+Space" "Run an application: fuzzel" "spawn" [ "fuzzel" ])
  (bind "Mod+Escape" "Lock the screen: swaylock" "spawn" [ "swaylock" ])
  # Literal Super: with the VM's Alt modifier, Mod+Alt would repeat lock.
  (bind "Super+Alt+Escape" "Suspend" "spawn" [ "systemctl" "suspend" ])

  (hidden (withProps "allow-when-locked=true"
    (bind "XF86AudioRaiseVolume" "Raise volume" "spawn-sh" [ "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+ -l 1.0" ])))
  (hidden (withProps "allow-when-locked=true"
    (bind "XF86AudioLowerVolume" "Lower volume" "spawn-sh" [ "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-" ])))
  (hidden (withProps "allow-when-locked=true"
    (bind "XF86AudioMute" "Mute or unmute audio" "spawn-sh" [ "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" ])))
  (hidden (withProps "allow-when-locked=true"
    (bind "XF86AudioMicMute" "Mute or unmute the microphone" "spawn-sh" [ "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" ])))

  (withProps "repeat=false" (bind "Mod+O" "Toggle the overview" "toggle-overview" [ ]))
  (withProps "repeat=false" (bind "Mod+Q" "Close the window" "close-window" [ ]))

  (bind "Mod+Left" "Focus the column to the left" "focus-column-left" [ ])
  (bind "Mod+Down" "Focus the window below" "focus-window-down" [ ])
  (bind "Mod+Up" "Focus the window above" "focus-window-up" [ ])
  (bind "Mod+Right" "Focus the column to the right" "focus-column-right" [ ])
  (bind "Mod+H" "Focus the column to the left" "focus-column-left" [ ])
  (bind "Mod+J" "Focus the window below" "focus-window-down" [ ])
  (bind "Mod+K" "Focus the window above" "focus-window-up" [ ])
  (bind "Mod+L" "Focus the column to the right" "focus-column-right" [ ])

  (bind "Mod+Ctrl+Left" "Move the column left" "move-column-left" [ ])
  (bind "Mod+Ctrl+Down" "Move the window down" "move-window-down" [ ])
  (bind "Mod+Ctrl+Up" "Move the window up" "move-window-up" [ ])
  (bind "Mod+Ctrl+Right" "Move the column right" "move-column-right" [ ])
  (bind "Mod+Ctrl+H" "Move the column left" "move-column-left" [ ])
  (bind "Mod+Ctrl+J" "Move the window down" "move-window-down" [ ])
  (bind "Mod+Ctrl+K" "Move the window up" "move-window-up" [ ])
  (bind "Mod+Ctrl+L" "Move the column right" "move-column-right" [ ])

  (bind "Mod+Home" "Focus the first column" "focus-column-first" [ ])
  (bind "Mod+End" "Focus the last column" "focus-column-last" [ ])
  (bind "Mod+Ctrl+Home" "Move the column to the start" "move-column-to-first" [ ])
  (bind "Mod+Ctrl+End" "Move the column to the end" "move-column-to-last" [ ])

  (bind "Mod+Page_Down" "Focus the workspace below" "focus-workspace-down" [ ])
  (bind "Mod+Page_Up" "Focus the workspace above" "focus-workspace-up" [ ])
  (bind "Mod+U" "Focus the workspace below" "focus-workspace-down" [ ])
  (bind "Mod+I" "Focus the workspace above" "focus-workspace-up" [ ])
  (bind "Mod+Ctrl+Page_Down" "Move the column to the workspace below" "move-column-to-workspace-down" [ ])
  (bind "Mod+Ctrl+Page_Up" "Move the column to the workspace above" "move-column-to-workspace-up" [ ])
  (bind "Mod+Ctrl+U" "Move the column to the workspace below" "move-column-to-workspace-down" [ ])
  (bind "Mod+Ctrl+I" "Move the column to the workspace above" "move-column-to-workspace-up" [ ])

  (withProps "cooldown-ms=150" (bind "Mod+WheelScrollDown" "Focus the workspace below" "focus-workspace-down" [ ]))
  (withProps "cooldown-ms=150" (bind "Mod+WheelScrollUp" "Focus the workspace above" "focus-workspace-up" [ ]))
  (withProps "cooldown-ms=150" (bind "Mod+Ctrl+WheelScrollDown" "Move the column to the workspace below" "move-column-to-workspace-down" [ ]))
  (withProps "cooldown-ms=150" (bind "Mod+Ctrl+WheelScrollUp" "Move the column to the workspace above" "move-column-to-workspace-up" [ ]))
]
# Workspace N, positional; no app is tied to a workspace. The overlay shows
# workspace 1 only. Shift moves the column (Niri's default uses Ctrl).
++ workspaces (n: (if n == 1 then lib.id else hidden)
  (bind "Mod+${toString n}" "Focus workspace ${toString n}" "focus-workspace" [ n ]))
++ workspaces (n: (if n == 1 then lib.id else hidden)
  (bind "Mod+Shift+${toString n}" "Move the column to workspace ${toString n}" "move-column-to-workspace" [ n ]))
++ [
  # ü is where the US [ key sits; + pairs with - for growing.
  (bind "Mod+udiaeresis" "Consume or expel the window to the left" "consume-or-expel-window-left" [ ])
  (bind "Mod+Shift+udiaeresis" "Consume or expel the window to the right" "consume-or-expel-window-right" [ ])
  (bind "Mod+Comma" "Consume the next window into the column" "consume-window-into-column" [ ])
  (bind "Mod+Period" "Expel the bottom window from the column" "expel-window-from-column" [ ])

  (bind "Mod+R" "Cycle preset column widths" "switch-preset-column-width" [ ])
  (bind "Mod+Shift+R" "Cycle preset column widths backwards" "switch-preset-column-width-back" [ ])
  (bind "Mod+F" "Maximize the column" "maximize-column" [ ])
  (bind "Mod+Shift+F" "Fullscreen the window" "fullscreen-window" [ ])
  # Super+C/V/X/A/Z are edit keys (xremap), so Niri's C/V binds take Shift.
  (bind "Mod+Shift+C" "Center the column" "center-column" [ ])
  (bind "Mod+Minus" "Shrink the column width" "set-column-width" [ "-10%" ])
  (bind "Mod+plus" "Grow the column width" "set-column-width" [ "+10%" ])
  (bind "Mod+Shift+Minus" "Shrink the window height" "set-window-height" [ "-10%" ])
  (bind "Mod+Shift+plus" "Grow the window height" "set-window-height" [ "+10%" ])

  (bind "Mod+Shift+V" "Float or tile the window" "toggle-window-floating" [ ])
  (bind "Mod+Ctrl+V" "Switch focus between floating and tiling" "switch-focus-between-floating-and-tiling" [ ])
  (bind "Mod+W" "Toggle tabbed column display" "toggle-column-tabbed-display" [ ])

  # The small Apple keyboard has no Print key; Mod+Shift+1–9 move columns.
  (bind "Mod+Shift+S" "Screenshot a selection" "screenshot" [ ])
  (bind "Mod+Ctrl+S" "Screenshot the screen" "screenshot-screen" [ ])
  # Literal Super, as for suspend: in the VM Mod+Alt would be Alt+Alt.
  (bind "Super+Alt+S" "Screenshot the window" "screenshot-window" [ ])
  (bind "Print" "Screenshot a selection" "screenshot" [ ])
  (bind "Ctrl+Print" "Screenshot the screen" "screenshot-screen" [ ])
  (bind "Alt+Print" "Screenshot the window" "screenshot-window" [ ])

  (withProps "allow-inhibiting=false"
    (bind "Mod+Shift+Escape" "Toggle app shortcut inhibiting" "toggle-keyboard-shortcuts-inhibit" [ ]))
  (bind "Mod+Shift+E" "Quit Niri" "quit" [ ])
  (bind "Ctrl+Alt+Delete" "Quit Niri" "quit" [ ])
  (bind "Mod+Shift+P" "Power off the monitors" "power-off-monitors" [ ])
]
