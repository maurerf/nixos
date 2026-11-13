# Research: system-wide Super+C/V copy and paste on Niri

Ticket: [#59](https://github.com/maurerf/nixos/issues/59) (map [#56](https://github.com/maurerf/nixos/issues/56)).
Researched 2026-11-13 against the sources pinned in `flake.lock` at commit
`56dae95` (nixpkgs `nixos-26.05` rev `f5c082a4`, 2026-09-25). Nothing on the
live system was changed; all claims below come from source code or upstream
docs at the pinned versions, except where marked **unverified**.

## Question

Make `Super+C/V/X/A/Z` mean copy/paste/cut/select-all/undo in every app on
`desktop-pc` (Niri, Wayland, xkb layout `de`), while `Ctrl+C` stays interrupt in
Ghostty.

## Recommendation

**Use xremap's Niri build (`pkgs.xremap.niri`) as a Home Manager systemd user
service**, with one keymap that turns `Super+key` into `Ctrl+key` in every app
*except* Ghostty, and let Ghostty receive `Super+key` unchanged and handle it with
its own `super+…` keybinds (the same bindings Ghostty uses by default on macOS).
Move Niri's `Super+C` (`center-column`) and `Super+V` (`toggle-window-floating`)
to other keys and keep `Super+X/A/Z` free of Niri binds.

Why this one:

- It is the only option that is app-aware **at keypress time**: xremap asks
  Niri's IPC for the focused window when it evaluates a remap, so there is no
  focus-change race (keyd's mapper rebinds asynchronously after focus events).
- `exact_match: true` remaps only the exact combo, so Niri's other Super binds
  (`Super+Shift+V`, `Super+Ctrl+…`) are untouched.
- It needs `input`/`uinput` group access for the user. keyd's app-aware path
  instead needs access to keyd's socket, which upstream says is root-equivalent
  (and the code confirms; see below).
- Ghostty's Linux config ends up mirroring its macOS defaults, so the Mac needs
  nothing.

Cost: no NixOS/Home Manager module exists for xremap at the pinned versions, so
the implementer writes a ~15-line user unit, adds `fdm` to `input` and `uinput`,
and enables `hardware.uinput`.

## Current state in this repo

- `profiles/desktop-pc/niri.kdl`: `@modKey@+C { center-column; }`,
  `@modKey@+V { toggle-window-floating; }`,
  `@modKey@+Shift+V { switch-focus-between-floating-and-tiling; }`. `Super+X`,
  `Super+A`, `Super+Z` are unbound. `Super+Q` closes the window (already
  Mac-like). Keyboard layout `de`.
- `profiles/home-desktop-pc.nix`: `desktopPc.niriModKey` defaults to `Super`;
  the VM variant (`machines/desktop-pc.nix`) sets `Alt` because the Windows host
  captures Super, so this feature cannot be exercised in the VM.
- `modules/home-workstation.nix`: Ghostty settings shared with the Mac; no
  keybinds set. The package is set per platform
  (`profiles/home-desktop-pc.nix`: `programs.ghostty.package = pkgs.ghostty`).
- `machines/desktop-pc.nix`: `users.users.fdm.extraGroups = [ "networkmanager"
  "gamemode" ]` (plus `wheel` from `modules/nixos-base.nix`). No remapper.
- Session: greetd → `niri-session` (systemd-managed `niri.service`).

## Why a remapper is needed at all

Per-app config cannot cover "every app": Ghostty and VS Code accept custom
keybinds, but Firefox, GTK/Qt apps (Thunderbird, KeePassXC, Telegram) and web
apps that read `keydown` events hardcode `Ctrl+C/V`. Niri has no "send keys to
client" action (no such action in `niri-config/src/binds.rs` / `niri-ipc`), so
the compositor alone cannot translate. The translation must happen below the
compositor (evdev/uinput), or via a spawned virtual-keyboard client (see
"Options ruled out").

## The terminal problem

A blanket `Super+C → Ctrl+C` makes `Super+C` in Ghostty send interrupt, which
defeats the goal. Ghostty's Linux defaults are copy `ctrl+shift+c`, paste
`ctrl+shift+v`, select-all `ctrl+shift+a`; on macOS they are `super+c/v/a`
(`src/config/Config.zig`: "On macOS we default to super but Linux ctrl+shift
since ctrl+c is to kill the process"). So Ghostty needs a per-app exception:
either remap `Super+key → Ctrl+Shift+key` there, or pass `Super+key` through and
bind `super+c=copy_to_clipboard` etc. in Ghostty. Ghostty's GTK app id is
`com.mitchellh.ghostty` for release builds (`src/apprt/gtk/App.zig`).

## Options compared

### A. xremap, Niri variant (recommended)

- Package: `pkgs/by-name/xr/xremap/package.nix` at version **0.15.7**, with a
  `niri` variant (`features = [ "niri" ]`) exposed as `pkgs.xremap.niri`
  (`passthru = lib.mapAttrs … variants`). Default variant is `wlroots`.
- No NixOS module in nixpkgs and none in Home Manager `release-26.05`
  (`modules/services` has no xremap/keyd/kanata). Upstream points NixOS users at
  the external `xremap/nix-flake` (README "NixOS"); adding an input for this is
  unnecessary, a hand-written user service is enough.
- App awareness: `src/client/niri_client.rs` connects to `$NIRI_SOCKET`, sends
  `Request::Windows` and picks `is_focused`; `current_application` returns the
  window's `app_id`. Niri's own `import_environment()` (`src/main.rs`) runs
  `systemctl --user import-environment … NIRI_SOCKET`, so a user unit ordered
  `After=niri.service`/`PartOf=graphical-session.target` sees the socket.
  `xremap --list-windows` (since 0.15.5) lists app ids for writing filters.
- Config (README "keymap", "application", "exact_match"): per-keymap
  `application: { not: [...] }` / `only: [...]`; `exact_match: true` disables
  the default inexact matching (by default `Ctrl-n: down` would also turn
  `Ctrl-Shift-n` into `Shift-down`).
- Modifier handling: `send_key_press_and_release` in `src/event_handler.rs`
  releases the extra held modifiers (Super) before emitting the target combo
  and re-presses them after, so the app sees a clean `Ctrl+C`.
- Permissions (`doc/running_without_sudo.md`, `doc/running_as_user_service.md`):
  user needs `input` (read evdev) and write access to `/dev/uinput`. Upstream
  lists the cons: the user account is opened to keylogging, remapping stays
  active while locked. On NixOS, `hardware.uinput.enable` provides the `uinput`
  group and udev rule (the keyd module sets it via `mkDefault true`, showing the
  option exists).
- Compatibility risk: xremap 0.15.7 links `niri-ipc 25.11.0` while nixpkgs ships
  niri **26.04**. `niri-ipc` declares no `deny_unknown_fields`, and the
  `Windows` request is long-standing, so it should work; **unverified at
  runtime** — check with `xremap --list-windows` during implementation.
- Per-keypress cost: one IPC round trip per evaluated filtered keymap (a new
  socket connection each time, per the code comment). **Unverified** whether
  this is perceptible; it only applies when a filtered keymap is consulted.

Sketch for the implementing ticket (key names per
`doc/reference_key_names.md`; verify syntax when implementing):

```yaml
keymap:
  - name: mac-style edit keys
    exact_match: true
    application:
      not: [com.mitchellh.ghostty]
    remap:
      Super-c: C-c
      Super-v: C-v
      Super-x: C-x
      Super-a: C-a
      Super-y: C-y              # key labelled Z on the de layout is KEY_Y
      Super-Shift-y: C-Shift-y  # redo
```

Ghostty side (Linux profile only, mirrors macOS defaults):

```
keybind = super+c=copy_to_clipboard
keybind = super+v=paste_from_clipboard
keybind = super+a=select_all
```

### B. keyd + keyd-application-mapper

- NixOS module `services.keyd` exists (`nixos/modules/services/hardware/keyd.nix`),
  package **2.6.0**, system daemon running as root with `input`/`uinput`
  groups, config in `services.keyd.keyboards.<name>.settings`; it has a NixOS
  test. Global remap is trivial: `[meta] c = C-c`. keyd docs: "bindings are not
  affected by the modifiers of the layer in which they are defined" (so Super is
  dropped), but other held modifiers carry through (`shift+capslock+j` →
  `shift+down`), so `Super+Shift+V` would also be rewritten unless composite
  layers are defined.
- App awareness: `keyd-application-mapper` (bundled in the nixpkgs package)
  reads `~/.config/keyd/app.conf` and runs `keyd bind` on focus change. Its
  `Wlroots` backend uses `zwlr_foreign_toplevel_manager_v1`, which Niri
  implements (`src/protocols/foreign_toplevel.rs`, exposed to unrestricted
  clients in `src/niri.rs`). Its man page still says "At the moment X, Sway and
  Gnome are supported", i.e. Niri is not an advertised target. The NixOS module
  does not start it; a user service would be needed.
- Rebinding is asynchronous: keys pressed right after a focus change can use the
  previous app's map. **Unverified** how often this bites in practice.
- Security: the mapper talks to `/var/run/keyd.socket` (mode `0660`, group
  `keyd`, `src/ipc.c`); the NixOS module does not create the `keyd` group. keyd
  docs: "Users with access to the keyd socket should be considered privileged".
  The code confirms it: `IPC_BIND` applies any expression without a peer
  credential check, and `command()` runs `/bin/sh -c` as the daemon user
  ("probably root"). Granting `fdm` the `keyd` group therefore lets any process
  of `fdm` run commands as root without a password.
- Verdict: best choice for a **global, app-agnostic** remap; the Ghostty
  exception is what makes it worse than xremap here.

### C. kanata

- NixOS module `services.kanata` exists, but kanata has no built-in app
  awareness on Linux; its README lists third-party helpers (qanata, nata,
  hyprkan, kanata-switcher) that switch layers over kanata's TCP port. Another
  out-of-tree component for the same result as A. Ruled out.

### D. Per-app config only

- Ghostty (`super+c=copy_to_clipboard`), VS Code (`keybindings.json`) could be
  done. Firefox, GTK/Qt apps and web apps cannot. Fails "every app". Ruled out
  as the main approach, but Ghostty's part is reused in A.

### Options ruled out

- **App-agnostic CUA keys** (`Super+C → Ctrl+Insert`, `Super+V → Shift+Insert`,
  `Super+X → Shift+Delete`, no app awareness). Ghostty accepts `ctrl+insert` as
  copy on Linux, but its `shift+insert` default is `paste_from_selection`
  (primary selection), not the clipboard (`src/config/Config.zig`). It does not
  cover select-all/undo (`Ctrl+A`/`Ctrl+Z` are readline/`SIGTSTP` in a
  terminal), and web apps that handle `keydown` for `Ctrl+C/V` would not see the
  Insert variants. Support in GTK/Qt/Firefox/Chromium is **unverified** here.
- **Niri bind + spawned `wtype`** (Niri supports virtual-keyboard for
  unrestricted clients, `src/niri.rs`). No extra privileges, but it spawns a
  process per keypress and the interaction with the still-held physical Super
  is **unverified**. Could be prototyped if group membership is unacceptable.

## Niri bind conflicts

xremap/keyd sit below Niri, so in non-Ghostty apps Niri sees `Ctrl+C`, never
`Super+C`. In Ghostty (pass-through), Niri sees `Super+C` and its bind wins
before Ghostty. So:

- Move `center-column` and `toggle-window-floating` off `Super+C`/`Super+V`
  (free letters today include B, D, G, M, N, S, T; the choice belongs to the
  implementing ticket and the keybinding-help ticket).
- `Super+Shift+V` can stay with `exact_match: true` in xremap.
- Keep `Super+X`, `Super+A`, `Super+Z` (physical `KEY_Y` on `de`) unbound in
  Niri.

## Layout note (`de`)

Both xremap and keyd work on evdev keycodes, i.e. US-QWERTY positions. On the
`de` layout the key labelled Z is `KEY_Y`. Mapping each key to Ctrl plus the
**same** keycode is layout-independent: xkb on the uinput device then produces
`Ctrl+z` for the Z-labelled key. Write the remap by keycode, not by label.

## Per-app exceptions and follow-ups

- **Ghostty**: excluded from the remap; handles `super+…` itself. Put the
  keybinds in `profiles/home-desktop-pc.nix` (Linux only), not the shared
  module.
- **VS Code integrated terminal**: VS Code is one app id, so `Super+C → Ctrl+C`
  also reaches its terminal. **Unverified** default: whether Linux VS Code
  copies on `Ctrl+C` with a selection. Handle in the VS Code keybindings ticket
  if needed (`ctrl+c` with `terminalFocus && terminalTextSelected` →
  copy selection).
- **Games/Steam**: could be excluded with `application: not:` by
  `^steam_app_` if `Super+C` ever matters in a game.
- **Lock screen**: upstream notes remapping stays active while locked; harmless
  for these combos.

## macOS side

Nothing needed. Ghostty's macOS defaults are already `super+c/v/a`, undo/redo on
`super+z`/`super+shift+z` (`src/config/Config.zig`), and the remapper is
Linux-only. Keep the Ghostty keybinds out of `modules/home-workstation.nix` to
avoid platform-specific behaviour in the shared module.

## Sources (pinned store paths at time of research)

- nixpkgs `f5c082a4`: `pkgs/by-name/xr/xremap/package.nix`,
  `pkgs/by-name/ke/keyd/package.nix`,
  `nixos/modules/services/hardware/{keyd,kanata}.nix`.
- xremap v0.15.7: `README.md`, `Cargo.toml`, `Cargo.lock`,
  `src/client/niri_client.rs`, `src/event_handler.rs`,
  `doc/running_without_sudo.md`, `doc/running_as_user_service.md`,
  `doc/running_as_system_service.md`, `doc/reference_key_names.md`.
- keyd v2.6.0: `docs/keyd.scdoc`, `docs/keyd-application-mapper.scdoc`,
  `scripts/keyd-application-mapper`, `src/ipc.c`, `src/daemon.c`,
  `src/keyboard.c`.
- kanata (nixpkgs pin): `README.md` "Community projects".
- niri 26.04: `src/main.rs`, `src/niri.rs`, `src/protocols/foreign_toplevel.rs`.
- Ghostty 1.3.1: `src/config/Config.zig`, `src/apprt/gtk/App.zig`.
- Home Manager `release-26.05` (`a6631107`): `modules/services` listing.
