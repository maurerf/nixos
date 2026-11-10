# Linux availability of the Mac profile packages

Research for [issue #25](https://github.com/maurerf/nixos/issues/25), part of
the `desktop-pc` map ([issue #21](https://github.com/maurerf/nixos/issues/21)).

- **Researched:** 2026-11-10, by reading source only. Nothing was evaluated,
  built or run; Nix is not available on the research machine.
- **Pinned inputs (`flake.lock`):** nixpkgs `nixos-26.05` at
  [`f5c082a`](https://github.com/NixOS/nixpkgs/tree/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7)
  (committed 2026-09-25); Home Manager `release-26.05` at
  [`a663110`](https://github.com/nix-community/home-manager/tree/a6631107a83ceab5872f298a2ea710859c80c4cb).
- Paths below are relative to those revisions unless a full link is given.
  `NP` = `https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7`,
  `HM` = `https://github.com/nix-community/home-manager/blob/a6631107a83ceab5872f298a2ea710859c80c4cb`.

## Answer

Every package in `profiles/home-darwin.nix` except `notion-app` declares
`x86_64-linux` support under the same attribute name at the pinned revision.
No attribute needs renaming for a shared module. Six are unfree
(`claude-code`, `vscode`, `obsidian`, `rar`, and the disabled `spotify`; plus
`notion-app`, which is Darwin-only and out of scope), so the shared list only
evaluates on hosts with `allowUnfree` (or a matching `allowUnfreePredicate`).
The VPS keeps `allowUnfree = false` and does not import the app list, so that
is consistent with the map's standing decisions.

"Declares support" means `meta.platforms` and the Linux source/hash exist in
the package expression. Whether each app actually starts under Niri is for the
VM dry run to prove.

## Per-package table

| Attribute | x86_64-linux | Unfree? | Notes |
| --- | --- | --- | --- |
| `vim` | Yes (`platforms.unix`) | No (Vim licence) | Already used on the VPS. [`NP/pkgs/applications/editors/vim/common.nix`] |
| `htop` | Yes (`platforms.all`) | No (GPL-2.0-only) | Already used on the VPS. [`NP/pkgs/by-name/ht/htop/package.nix`] |
| `autoconf` | Yes (`platforms.all`) | No (GPL-3.0+) | [`NP/pkgs/development/tools/misc/autoconf/default.nix`] |
| `autogen` | Yes (`platforms.all`) | No (GPL/LGPL family) | [`NP/pkgs/by-name/au/autogen/package.nix`] |
| `automake` | Yes (`platforms.all`) | No (GPL-2.0+) | Alias for `automake118x`. [`NP/pkgs/development/tools/misc/automake/automake-1.18.x.nix`] |
| `doxygen` | Yes (`platforms.unix`; GUI variant Linux-only) | No (GPL-2.0+) | [`NP/pkgs/by-name/do/doxygen/package.nix`] |
| `yt-dlp` | Yes (no `platforms` restriction; Python application) | No (Unlicense) | [`NP/pkgs/by-name/yt/yt-dlp/package.nix`] |
| `claude-code` | Yes (listed explicitly) | **Yes** (`unfree`, prebuilt binary) | Version 2.1.223. Terminal program, no display flags. Linux wrapper adds `bubblewrap` and `socat` for the sandbox. [`NP/pkgs/by-name/cl/claude-code/package.nix`] |
| `vscode` | Yes (listed explicitly) | **Yes** (`unfree`) | Version 1.119.0. Electron; wrapper honours `NIXOS_OZONE_WL` (see below). [`NP/pkgs/applications/editors/vscode/vscode.nix`], [`.../generic.nix`] |
| `spotify` (disabled) | Yes (listed explicitly) | **Yes** (`unfree`) | Linux build is a pinned Snap revision, a different source from the macOS `.dmg`, so the Darwin "hash mismatch" does not carry over. Chromium-based; wrapper reacts to `NIXOS_OZONE_WL=1`. Depends on `ffmpeg_4`, kept in nixpkgs specifically for it. [`NP/pkgs/by-name/sp/spotify/package.nix`], [`.../linux.nix`] |
| `keepassxc` | Yes (`platforms.linux ++ darwin`) | No (GPL-2.0+) | Qt 5. Linux build enables the Secret Service and YubiKey features by default. Built with X11 support and without `qtwayland` in its inputs, so expect it to run through Xwayland (see uncertainties). [`NP/pkgs/by-name/ke/keepassxc/package.nix`] |
| `telegram-desktop` | Yes (`platforms.all`) | No (GPL-3.0-only) | Qt 6, built from source; Linux wrapper includes `qtwayland`, so native Wayland. `meta.mainProgram` is `Telegram`. [`NP/pkgs/applications/networking/instant-messengers/telegram/telegram-desktop/default.nix`], [`.../unwrapped.nix`] |
| `obsidian` | Yes (listed explicitly) | **Yes** (`licenses.obsidian`, `free = false`) | Version 1.13.7. Electron (nixpkgs `electron`, currently `electron_43`); wrapper honours `NIXOS_OZONE_WL`. [`NP/pkgs/by-name/ob/obsidian/package.nix`], [`NP/lib/licenses/licenses.nix`] |
| `anki-bin` | Yes (listed explicitly; `x86_64-linux` is the only Linux platform) | No (AGPL-3.0+, inherited from `anki`) | Version 25.02.5, upstream binary inside an FHS environment. Upstream defaults to X11 even in a Wayland session unless `ANKI_WAYLAND=1` is set or no `DISPLAY` exists (see below). [`NP/pkgs/by-name/an/anki-bin/package.nix`] |
| `rar` | Yes (`x86_64-linux` has a source entry) | **Yes** (`unfree`, prebuilt binary) | Version 7.21. No `aarch64-linux` build, irrelevant for this host. [`NP/pkgs/by-name/ra/rar/package.nix`] |
| `nerd-fonts.fira-code` | Yes (`platforms.all`) | No (OFL + MIT) | Already used on the VPS. [`NP/pkgs/data/fonts/nerd-fonts/default.nix`], [`.../manifests/fonts.json`] |
| `nerd-fonts.droid-sans-mono` | Yes (`platforms.all`) | No (OFL + MIT + Apache-2.0) | Already used on the VPS. Same sources. |
| `notion-app` (out of scope) | **No** (Darwin only) | Yes | Must stay in the Darwin profile, not the shared list. [`NP/pkgs/by-name/no/notion-app/package.nix`] |

## Wayland and Electron under Niri

- **`NIXOS_OZONE_WL=1`.** The NixOS wiki documents
  `environment.sessionVariables.NIXOS_OZONE_WL = "1";` as the switch that
  makes Chromium/Electron apps use native Wayland
  ([wiki: Wayland, "Electron and Chromium"](https://wiki.nixos.org/wiki/Wayland#Electron_and_Chromium)).
  The same page says that since NixOS 25.05, Chromium and Electron default to
  native Wayland when `XDG_SESSION_TYPE` is unset or `wayland`. At the pinned
  revision the wrappers still read the variable:
  - `vscode`: when both `NIXOS_OZONE_WL` and `WAYLAND_DISPLAY` are set, adds
    `--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations
    --enable-wayland-ime=true --wayland-text-input-version=3`
    (`pkgs/applications/editors/vscode/generic.nix`, line 375).
  - `obsidian`: same condition, adds `--ozone-platform=wayland
    --enable-wayland-ime=true --wayland-text-input-version=3`
    (`pkgs/by-name/ob/obsidian/package.nix`, line 108).
  - `spotify`: when `NIXOS_OZONE_WL` is exactly `1`, unsets `DISPLAY` so the
    client picks Wayland (`pkgs/by-name/sp/spotify/linux.nix`, line 243).

  Setting the variable once on the NixOS host covers all three. It is a
  NixOS-level (`environment.sessionVariables`) setting, so it belongs in the
  host configuration, not in the shared home module.
- **X11 apps need xwayland-satellite.** The nixpkgs Niri module imports the
  shared Wayland-session helper with `enableXWayland = false`
  (`nixos/modules/programs/wayland/niri.nix`), so `programs.niri.enable` does
  not enable Xwayland. Niri (packaged at 26.04) integrates
  `xwayland-satellite` automatically since 25.08 when version 0.7 or newer is
  on `PATH`
  ([niri wiki: Xwayland](https://github.com/YaLTeR/niri/blob/v26.04/docs/wiki/Xwayland.md));
  nixpkgs ships `xwayland-satellite` 0.8.2 for Linux. The host should install
  it: Steam needs it anyway, and `keepassxc` and `anki-bin` are expected to
  use it.
- **`anki-bin`.** Upstream Anki 25.02.5 forces `QT_QPA_PLATFORM=xcb` in a
  Wayland session when `DISPLAY` is available, and only uses Wayland when
  `ANKI_WAYLAND=1` is set or X11 is absent
  ([`qt/aqt/__init__.py`, lines 609-632](https://github.com/ankitects/anki/blob/25.02.5/qt/aqt/__init__.py#L609-L632)).
  With xwayland-satellite present it runs as an X11 client, which is
  upstream's recommended default; no flag needed.
- **`vscode`.** The Niri wiki notes that VS Code on the Wayland backend still
  queries an X server for the keymap, and that some hotkeys misbehave without
  a `DISPLAY`
  ([niri wiki: Application Issues](https://github.com/YaLTeR/niri/blob/v26.04/docs/wiki/Application-Issues.md)).
  xwayland-satellite provides that `DISPLAY`.
- **Portals and keyring.** `programs.niri.enable` already sets up
  `xdg-desktop-portal-gnome`, the GTK portal and GNOME Keyring
  (`nixos/modules/programs/wayland/niri.nix`); file pickers in the Electron
  apps rely on these. Nothing extra per package.

## Darwin-only options that must stay out of a shared module

From `profiles/home-darwin.nix`:

| Setting | Verdict | Why |
| --- | --- | --- |
| `targets.darwin.copyApps.enable = true;` | **Darwin profile only** | The option exists on every platform (Home Manager imports `./targets/darwin` unconditionally, `HM/modules/modules.nix`), but enabling it asserts a Darwin platform (`assertPlatform ... lib.platforms.darwin` in `HM/modules/targets/darwin/copyapps.nix`). On Linux it fails evaluation. |
| `targets.darwin.linkApps.enable = false;` | **Darwin profile only** | Setting it to `false` would evaluate on Linux, but it only exists to pair with `copyApps` on macOS (`HM/modules/targets/darwin/linkapps.nix`). Keep both together. |
| `programs.zsh.initContent` path snippet (`path=("$HOME/.nix-profile/bin" $path)`) | **Darwin profile only** | A macOS workaround. NixOS already puts `$HOME/.nix-profile` and `/etc/profiles/per-user/$USER` in `environment.profiles`, from which `PATH` is built (`NP/nixos/modules/config/users-groups.nix`, lines 1000-1005; `NP/nixos/modules/config/shells-environment.nix`). Harmless on Linux but redundant, and it hardcodes a profile path that changes if `home-manager.useUserPackages` is ever enabled (`HM/modules/home-environment.nix`, `home.profileDirectory`). |
| `notion-app` | **Darwin profile only** | Darwin-only package. |

Safe to share between both profiles: the remaining `home.packages` entries,
`programs.home-manager.enable`, `fonts.fontconfig.enable` (already used by the
Linux VPS profile), and the `modules/git.nix` and `modules/zsh.nix` imports.
`home.username` and `home.stateVersion` are per-profile today and should stay
where they are (state versions are preserved by repository rule).

## Uncertainties

- **Nothing was evaluated or built.** All claims come from reading package
  expressions. A package can declare `x86_64-linux` and still fail to build or
  be missing from the binary cache at this revision. Unfree packages are never
  in the public cache; `claude-code`, `vscode`, `obsidian`, `rar` and
  `spotify` are fetched from upstream and repackaged locally, which fails if
  upstream has removed or replaced the pinned file. The VM dry run settles
  this.
- **`keepassxc` on Wayland.** The expression has no `qtwayland` input and
  enables X11 support, which suggests it runs through Xwayland. Whether Qt's
  Wayland plugin still ends up on the wrapper's plugin path was not checked.
  With xwayland-satellite installed it should work either way; behaviour of
  auto-type and the tray icon under Niri is untested.
- **`NIXOS_OZONE_WL` necessity.** The wiki says Electron defaults to Wayland
  since 25.05, so the variable may be redundant for `obsidian` and `vscode`.
  The wrappers still add extra flags (IME, window decorations) only when it
  is set, so setting it is the conservative choice. Not verified at runtime.
- **`spotify`.** Disabled on the Mac for a hash mismatch; the Linux source is
  different and looked consistent, but whether the Snap download still matches
  its hash was not tested. It links against the old `ffmpeg_4`.
- **Fractional scaling on the 4K monitor.** Anki upstream notes Wayland
  fractional-scaling bugs; X11 clients under xwayland-satellite may render
  blurry or small at non-integer scale. Not assessed here.
- **Niri wiki link.** The Niri repository has moved organisations at some
  point (wiki text references `niri-wm/niri`); the `YaLTeR/niri` URLs resolved
  on 2026-11-10 at tag `v26.04`.
- The wiki is community-maintained and undated; its statements were
  cross-checked against the wrapper source where possible.

[`NP/pkgs/applications/editors/vim/common.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/applications/editors/vim/common.nix
[`NP/pkgs/by-name/ht/htop/package.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/ht/htop/package.nix
[`NP/pkgs/development/tools/misc/autoconf/default.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/development/tools/misc/autoconf/default.nix
[`NP/pkgs/by-name/au/autogen/package.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/au/autogen/package.nix
[`NP/pkgs/development/tools/misc/automake/automake-1.18.x.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/development/tools/misc/automake/automake-1.18.x.nix
[`NP/pkgs/by-name/do/doxygen/package.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/do/doxygen/package.nix
[`NP/pkgs/by-name/yt/yt-dlp/package.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/yt/yt-dlp/package.nix
[`NP/pkgs/by-name/cl/claude-code/package.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/cl/claude-code/package.nix
[`NP/pkgs/applications/editors/vscode/vscode.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/applications/editors/vscode/vscode.nix
[`.../generic.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/applications/editors/vscode/generic.nix
[`NP/pkgs/by-name/sp/spotify/package.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/sp/spotify/package.nix
[`.../linux.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/sp/spotify/linux.nix
[`NP/pkgs/by-name/ke/keepassxc/package.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/ke/keepassxc/package.nix
[`NP/pkgs/applications/networking/instant-messengers/telegram/telegram-desktop/default.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/applications/networking/instant-messengers/telegram/telegram-desktop/default.nix
[`.../unwrapped.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/applications/networking/instant-messengers/telegram/telegram-desktop/unwrapped.nix
[`NP/pkgs/by-name/ob/obsidian/package.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/ob/obsidian/package.nix
[`NP/lib/licenses/licenses.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/lib/licenses/licenses.nix
[`NP/pkgs/by-name/an/anki-bin/package.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/an/anki-bin/package.nix
[`NP/pkgs/by-name/ra/rar/package.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/ra/rar/package.nix
[`NP/pkgs/data/fonts/nerd-fonts/default.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/data/fonts/nerd-fonts/default.nix
[`.../manifests/fonts.json`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
[`NP/pkgs/by-name/no/notion-app/package.nix`]: https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/no/notion-app/package.nix
