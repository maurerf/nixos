# Niri binds for desktop-pc: the one list behind Niri's `binds {}` block, its
# hotkey overlay (Super+F1) and the fuzzel command palette (Super+Shift+Space).
# profiles/home-desktop-pc.nix renders both. Each entry:
#   key     Niri key, written with Super. Niri matches the unshifted key of the
#           de layout, so keys that need Shift or AltGr there (/, =, [, ])
#           never fire.
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
  # Media keys work on the lock screen and stay out of the overlay.
  mediaKey = key: title: command:
    hidden (withProps "allow-when-locked=true" (bind key title "spawn-sh" [ command ]));
  workspaces = f: lib.genList (i: f (i + 1)) 9;
in
[
  (bind "Super+F1" "Show this hotkey overlay" "show-hotkey-overlay" [ ])
  (bind "Super+Shift+Space" "Search and run a bind" "spawn" [ "niri-bind-palette" ])

  (bind "Super+Return" "Open a terminal: Ghostty" "spawn" [ "ghostty" ])
  (bind "Super+Space" "Run an application: fuzzel" "spawn" [ "fuzzel" ])
  (bind "Super+Escape" "Lock the screen: swaylock" "spawn" [ "swaylock" ])
  (bind "Super+Alt+Escape" "Suspend" "spawn" [ "systemctl" "suspend" ])

  (mediaKey "XF86AudioRaiseVolume" "Raise volume" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+ -l 1.0")
  (mediaKey "XF86AudioLowerVolume" "Lower volume" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-")
  (mediaKey "XF86AudioMute" "Mute or unmute audio" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
  (mediaKey "XF86AudioMicMute" "Mute or unmute the microphone" "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")

  (withProps "repeat=false" (bind "Super+O" "Toggle the overview" "toggle-overview" [ ]))
  (withProps "repeat=false" (bind "Super+Q" "Close the window" "close-window" [ ]))

  (bind "Super+Left" "Focus the column to the left" "focus-column-left" [ ])
  (bind "Super+Down" "Focus the window below" "focus-window-down" [ ])
  (bind "Super+Up" "Focus the window above" "focus-window-up" [ ])
  (bind "Super+Right" "Focus the column to the right" "focus-column-right" [ ])
  (bind "Super+H" "Focus the column to the left" "focus-column-left" [ ])
  (bind "Super+J" "Focus the window below" "focus-window-down" [ ])
  (bind "Super+K" "Focus the window above" "focus-window-up" [ ])
  (bind "Super+L" "Focus the column to the right" "focus-column-right" [ ])

  (bind "Super+Ctrl+Left" "Move the column left" "move-column-left" [ ])
  (bind "Super+Ctrl+Down" "Move the window down" "move-window-down" [ ])
  (bind "Super+Ctrl+Up" "Move the window up" "move-window-up" [ ])
  (bind "Super+Ctrl+Right" "Move the column right" "move-column-right" [ ])
  (bind "Super+Ctrl+H" "Move the column left" "move-column-left" [ ])
  (bind "Super+Ctrl+J" "Move the window down" "move-window-down" [ ])
  (bind "Super+Ctrl+K" "Move the window up" "move-window-up" [ ])
  (bind "Super+Ctrl+L" "Move the column right" "move-column-right" [ ])

  (bind "Super+Home" "Focus the first column" "focus-column-first" [ ])
  (bind "Super+End" "Focus the last column" "focus-column-last" [ ])
  (bind "Super+Ctrl+Home" "Move the column to the start" "move-column-to-first" [ ])
  (bind "Super+Ctrl+End" "Move the column to the end" "move-column-to-last" [ ])

  (bind "Super+Page_Down" "Focus the workspace below" "focus-workspace-down" [ ])
  (bind "Super+Page_Up" "Focus the workspace above" "focus-workspace-up" [ ])
  (bind "Super+U" "Focus the workspace below" "focus-workspace-down" [ ])
  (bind "Super+I" "Focus the workspace above" "focus-workspace-up" [ ])
  (bind "Super+Ctrl+Page_Down" "Move the column to the workspace below" "move-column-to-workspace-down" [ ])
  (bind "Super+Ctrl+Page_Up" "Move the column to the workspace above" "move-column-to-workspace-up" [ ])
  (bind "Super+Ctrl+U" "Move the column to the workspace below" "move-column-to-workspace-down" [ ])
  (bind "Super+Ctrl+I" "Move the column to the workspace above" "move-column-to-workspace-up" [ ])

  (withProps "cooldown-ms=150" (bind "Super+WheelScrollDown" "Focus the workspace below" "focus-workspace-down" [ ]))
  (withProps "cooldown-ms=150" (bind "Super+WheelScrollUp" "Focus the workspace above" "focus-workspace-up" [ ]))
  (withProps "cooldown-ms=150" (bind "Super+Ctrl+WheelScrollDown" "Move the column to the workspace below" "move-column-to-workspace-down" [ ]))
  (withProps "cooldown-ms=150" (bind "Super+Ctrl+WheelScrollUp" "Move the column to the workspace above" "move-column-to-workspace-up" [ ]))
]
# Workspace N, positional; no app is tied to a workspace. The overlay shows
# workspace 1 only. Shift moves the column (Niri's default uses Ctrl).
++ workspaces (n: (if n == 1 then lib.id else hidden)
  (bind "Super+${toString n}" "Focus workspace ${toString n}" "focus-workspace" [ n ]))
++ workspaces (n: (if n == 1 then lib.id else hidden)
  (bind "Super+Shift+${toString n}" "Move the column to workspace ${toString n}" "move-column-to-workspace" [ n ]))
++ [
  # ü is where the US [ key sits; + pairs with - for growing.
  (bind "Super+udiaeresis" "Consume or expel the window to the left" "consume-or-expel-window-left" [ ])
  (bind "Super+Shift+udiaeresis" "Consume or expel the window to the right" "consume-or-expel-window-right" [ ])
  (bind "Super+Comma" "Consume the next window into the column" "consume-window-into-column" [ ])
  (bind "Super+Period" "Expel the bottom window from the column" "expel-window-from-column" [ ])

  (bind "Super+R" "Cycle preset column widths" "switch-preset-column-width" [ ])
  (bind "Super+Shift+R" "Cycle preset column widths backwards" "switch-preset-column-width-back" [ ])
  (bind "Super+F" "Maximize the column" "maximize-column" [ ])
  (bind "Super+Shift+F" "Fullscreen the window" "fullscreen-window" [ ])
  # Super+C/V/X/A/Z are edit keys (xremap), so Niri's C/V binds take Shift.
  (bind "Super+Shift+C" "Center the column" "center-column" [ ])
  (bind "Super+Minus" "Shrink the column width" "set-column-width" [ "-10%" ])
  (bind "Super+plus" "Grow the column width" "set-column-width" [ "+10%" ])
  (bind "Super+Shift+Minus" "Shrink the window height" "set-window-height" [ "-10%" ])
  (bind "Super+Shift+plus" "Grow the window height" "set-window-height" [ "+10%" ])

  (bind "Super+Shift+V" "Float or tile the window" "toggle-window-floating" [ ])
  (bind "Super+Ctrl+V" "Switch focus between floating and tiling" "switch-focus-between-floating-and-tiling" [ ])
  (bind "Super+W" "Toggle tabbed column display" "toggle-column-tabbed-display" [ ])

  # The small Apple keyboard has no Print key; Super+Shift+1–9 move columns.
  (bind "Super+Shift+S" "Screenshot a selection" "screenshot" [ ])
  (bind "Super+Ctrl+S" "Screenshot the screen" "screenshot-screen" [ ])
  (bind "Super+Alt+S" "Screenshot the window" "screenshot-window" [ ])
  (bind "Print" "Screenshot a selection" "screenshot" [ ])
  (bind "Ctrl+Print" "Screenshot the screen" "screenshot-screen" [ ])
  (bind "Alt+Print" "Screenshot the window" "screenshot-window" [ ])

  (withProps "allow-inhibiting=false"
    (bind "Super+Shift+Escape" "Toggle app shortcut inhibiting" "toggle-keyboard-shortcuts-inhibit" [ ]))
  (bind "Super+Shift+E" "Quit Niri" "quit" [ ])
  (bind "Ctrl+Alt+Delete" "Quit Niri" "quit" [ ])
  (bind "Super+Shift+P" "Power off the monitors" "power-off-monitors" [ ])
]
