# Steam and Proton on NixOS with Niri and NVIDIA

Research for [issue #24](https://github.com/maurerf/nixos/issues/24), part of
the `desktop-pc` map ([issue #21](https://github.com/maurerf/nixos/issues/21)).
Sources were read on 2026-11-10 against `nixos-26.05`. Nothing here was run on
hardware: every statement is from module source, upstream documentation or
upstream issue trackers, and is cited. Driver installation and kernel
parameters for NVIDIA belong to the NVIDIA ticket and are only referenced here.

Target: RTX 2060 SUPER, i5-10600, 16 GB RAM, one 3840x2160 120 Hz monitor,
most games at 1080p.

## Recommendation

```nix
{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  # Optional tool for per-game use from Steam launch options.
  # Leave capSysNice at its default (false).
  programs.gamescope.enable = true;

  programs.gamemode.enable = true;
  # users.users.<name>.extraGroups = [ "gamemode" ];

  environment.systemPackages = [
    pkgs.xwayland-satellite # X11 for Steam and most games under Niri
    pkgs.mangohud # optional frame-time overlay for the gaming trial
  ];
}
```

Niri side (KDL, owned by whichever ticket decides how the Niri config is
managed):

```kdl
output "<connector from `niri msg outputs`>" {
    mode "3840x2160@<exact rate from `niri msg outputs`>"
    scale 2
    variable-refresh-rate on-demand=true
}

// Enable VRR only while a game is shown.
window-rule {
    match app-id=r#"^steam_app_\d+$"#
    variable-refresh-rate true
}

// Steam toasts otherwise appear as floating windows mid-screen.
window-rule {
    match app-id="steam" title=r#"^notificationtoasts_\d+_desktop$"#
    default-floating-position x=10 y=10 relative-to="bottom-right"
}
```

Default per-game path: plain Proton through Xwayland (xwayland-satellite), no
gamescope, no `PROTON_ENABLE_WAYLAND`. Add `gamemoderun %command%` where wanted.
Reach for gamescope only when a game misbehaves in a tiling compositor
(cursor escapes, refuses its resolution, wrong window size).

## What each piece does

### `programs.steam`

Source: [`nixos/modules/programs/steam.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/programs/steam.nix).

- Enabling it sets `hardware.graphics.enable = true` and
  `hardware.graphics.enable32Bit = true`, sets
  `services.pipewire.alsa.support32Bit` to follow
  `services.pipewire.alsa.enable`, and sets
  `hardware.steam-hardware.enable = true` (controller udev rules). **32-bit
  graphics need no separate declaration.**
- The module injects `hardware.graphics.package`/`package32` plus
  `extraPackages`/`extraPackages32` into the Steam FHS environment. With the
  NVIDIA module active those are the NVIDIA userspace libraries, so the 32-bit
  NVIDIA driver follows from `enable32Bit`
  ([`hardware/graphics.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/hardware/graphics.nix)
  links `/run/opengl-driver-32` when it is set).
- `extraCompatPackages` exports `STEAM_EXTRA_COMPAT_TOOLS_PATHS`; packages must
  have a `steamcompattool` output.
- Firewall options (`remotePlay`, `dedicatedServer`,
  `localNetworkGameTransfers`) default to closed. Leave them closed unless a
  feature is wanted.
- `gamescopeSession.enable` adds a separate "Steam" login session (gamescope on
  DRM, Big Picture). Not recommended here; see pitfalls.
- Steam is unfree. The NixOS wiki lists `steam` and `steam-unwrapped` as the
  names to allow when using a predicate
  ([wiki](https://wiki.nixos.org/wiki/Steam)); the map already sets
  `allowUnfree = true` for this host.

### Xwayland under Niri

- The NixOS Niri module imports the shared Wayland session helper with
  `enableXWayland = false`
  ([`programs/wayland/niri.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/programs/wayland/niri.nix)),
  so X11 support is not pulled in automatically.
- Since Niri 25.08, Niri creates the X11 socket, exports `DISPLAY` and spawns
  `xwayland-satellite` on demand, provided `xwayland-satellite >= 0.7` is in
  `$PATH` ([Niri Xwayland docs](https://github.com/niri-wm/niri/blob/main/docs/wiki/Xwayland.md)).
  `nixos-26.05` ships Niri 26.04 and xwayland-satellite 0.8.3, so adding the
  package to `environment.systemPackages` is sufficient. Check with
  `journalctl --user-unit=niri -b` for `listening on X11 socket`.
- Niri's docs state that xwayland-satellite "works well with most
  applications: Steam, games, Discord".
- Scaling: xwayland-satellite scales GTK/Qt apps itself, but "Wine apps ... may
  have small text on HiDPI displays" and need per-app settings
  ([README](https://github.com/Supreeeme/xwayland-satellite/blob/main/README.md)).
  This affects launchers and windowed games at `scale 2`, not fullscreen 3D.

### Proton-GE

- `pkgs.proton-ge-bin` is `GE-Proton11-1` on `nixos-26.05` and is meant only
  for `programs.steam.extraCompatPackages`; it deliberately cannot be installed
  into an environment
  ([package](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/pr/proton-ge-bin/package.nix)).
  It is prebuilt binary code (`sourceProvenance = binaryNativeCode`).
- It shows up in Steam as "GE-Proton" and must still be selected per game or as
  the default under Steam Play settings. The version only moves with flake
  updates. Valve's Proton (11.0 is current) is downloaded by Steam itself and
  should stay the default; GE is the fallback for games that need its patches
  (extra media codecs, `WINE_FULLSCREEN_FSR`)
  ([GE README](https://github.com/GloriousEggroll/proton-ge-custom/blob/master/README.md)).
- GE asks that issues seen only on GE are not reported to Valve.

### gamescope

Sources: [`programs/gamescope.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/programs/gamescope.nix),
[package](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/ga/gamescope/package.nix)
(3.16.23), [upstream README](https://github.com/ValveSoftware/gamescope/blob/master/README.md).

- Upstream supports the NVIDIA proprietary driver from 515.43.04 with
  `nvidia-drm.modeset=1`. `nixos-26.05` `production` is 595.71.05.
- Niri documents gamescope as the fix for fullscreen games that misbehave in a
  non-stacking compositor, with this command and the note that `--backend sdl`
  is needed because the default Wayland backend does not lock the cursor
  properly
  ([Application issues](https://github.com/niri-wm/niri/blob/main/docs/wiki/Application-Issues.md#fullscreen-games)):

  ```sh
  gamescope -f -w 1920 -h 1080 -W 1920 -H 1080 --force-grab-cursor --backend sdl -- %command%
  ```

- So gamescope nested under Niri is a documented, supported path. Whether it is
  *trouble-free on NVIDIA* is not established: see pitfalls. Treat it as a
  per-game tool, not the default.
- `capSysNice = true` must stay off. Steam runs in a bubblewrap FHS
  environment where a capability-wrapped binary cannot gain its capabilities,
  and gamescope launched from Steam launch options then fails with "failed to
  inherit capabilities". Maintainer guidance in the tracking issue is "Do not
  use `capSysNice = true`"
  ([nixpkgs #351516](https://github.com/NixOS/nixpkgs/issues/351516), open,
  last activity 2026-11-10).

### GameMode

Source: [`programs/gamemode.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/programs/gamemode.nix)
(GameMode 1.8.2).

- Installs the daemon as a user service, wraps `gamemoded` with
  `cap_sys_nice` (`enableRenice` defaults to true), enables polkit and creates
  the `gamemode` group.
- Upstream's polkit rule lets members of the privileged group run the governor
  and other helpers without authentication, and the PAM limit allows that group
  nice -10
  ([rules](https://github.com/FeralInteractive/gamemode/blob/master/data/polkit/rules.d/gamemode.rules.in)).
  Add the user to `gamemode`, otherwise the CPU-governor switch is expected to
  be denied or to prompt.
- Use per game: `gamemoderun %command%`
  ([upstream README](https://github.com/FeralInteractive/gamemode/blob/master/README.md)).
- Leave `settings.gpu` unset; the module example itself warns GPU
  optimisations can damage hardware.

## Running 1080p on the 4K panel

1080p is exactly half of 2160p per axis, so integer 2x scaling is available and
gives sharp pixels. Options, in recommended order:

1. **Render at 4K with DLSS where the game offers it.** DLSS "Performance"
   renders internally at 1080p and outputs native 4K, which avoids the scaling
   question. Proton ships NVAPI enabled by default (the README only documents a
   switch to *disable* it, `PROTON_DISABLE_NVAPI`)
   ([Proton README](https://github.com/ValveSoftware/Proton/blob/proton_11.0/README.md)).
   Bare-metal only.
2. **Pick 1920x1080 fullscreen in the game and let Proton scale.** Under
   Xwayland a game cannot switch the real display mode; Proton's fullscreen
   handling presents the requested resolution scaled to the screen.
   `WINE_FULLSCREEN_INTEGER_SCALING=1 %command%` is Valve-documented: "Enable
   integer scaling mode, to give sharp pixels when upscaling"
   ([Proton README](https://github.com/ValveSoftware/Proton/blob/proton_11.0/README.md)).
   GE-Proton additionally offers `WINE_FULLSCREEN_FSR=1`. No extra software.
3. **gamescope as the scaler**, when option 2 misbehaves:

   ```sh
   gamescope -w 1920 -h 1080 -W 3840 -H 2160 -f -S integer --force-grab-cursor --backend sdl -- %command%
   ```

   `-w/-h` is what the game sees, `-W/-H` is the output, `-S integer` is integer
   scaling; `-F fsr` or `-F nis` select FSR 1.0 or NVIDIA Image Scaling instead
   ([README](https://github.com/ValveSoftware/gamescope/blob/master/README.md)).
   Filtered upscaling in fullscreen on NVIDIA has an open flicker report
   ([gamescope #1739](https://github.com/ValveSoftware/gamescope/issues/1739)),
   so prefer `-S integer` first.
4. **Switch the monitor itself to 1080p for a session** and let the panel
   scale: `niri msg output <name> mode 1920x1080@<rate>` and
   `niri msg output <name> scale 1`. IPC output changes are temporary and are
   dropped when the output config next changes
   ([niri-ipc source](https://github.com/niri-wm/niri/blob/main/niri-ipc/src/lib.rs)).
   Only works if the monitor advertises a 1080p mode at the wanted rate
   (`niri msg outputs` lists modes; the rate must match to three decimals).
   Quality then depends on the monitor's scaler.

Desktop scale interacts with this: at Niri `scale 2` the logical desktop is
already 1920x1080
([outputs docs](https://github.com/niri-wm/niri/blob/main/docs/wiki/Configuration:-Outputs.md)).
What resolution list an Xwayland game is offered at `scale 2` is not documented
and must be observed on hardware.

## VRR

- Niri: `variable-refresh-rate` per output, optionally `on-demand=true` with a
  window rule so VRR is active only while a matching window is shown. Upstream
  recommends on-demand "to avoid various issues with VRR" and lists known
  problems (low-rate cursor, monitors that flash black)
  ([outputs docs](https://github.com/niri-wm/niri/blob/main/docs/wiki/Configuration:-Outputs.md),
  [window rules](https://github.com/niri-wm/niri/blob/main/docs/wiki/Configuration:-Window-Rules.md)).
  `niri msg outputs` reports whether the output is VRR-capable.
- The `"fullscreen-only"` value for the window rule is marked "Since: next
  release" and is not in Niri 26.04.
- Niri has no tearing (immediate) presentation; the request is open
  ([niri #844](https://github.com/niri-wm/niri/issues/844)). VRR plus an FPS
  cap below 120 is the available low-latency setup.
- Nested gamescope has `--adaptive-sync`; whether it has any effect under Niri
  was not established.

## Known pitfalls

- **Native Wayland Proton is slower on Niri with NVIDIA.** Niri has no explicit
  sync yet (PRs [#3217](https://github.com/niri-wm/niri/pull/3217) and
  [#1449](https://github.com/niri-wm/niri/pull/1449) open as of 2026-11-08). A
  report measured about 25% lower FPS with `PROTON_ENABLE_WAYLAND=1` than with
  Xwayland on NVIDIA under Niri, fixed by forks carrying explicit sync
  ([niri #4091](https://github.com/niri-wm/niri/issues/4091)). Niri's docs call
  the Proton Wayland mode experimental. Keep the Xwayland default.
- **Steam window fully black**: disable "GPU accelerated rendering in web
  views" in Steam settings, or start Steam with `-system-composer`
  ([Application issues](https://github.com/niri-wm/niri/blob/main/docs/wiki/Application-Issues.md#steam)).
- **Steam started from Niri `spawn-at-startup` may fail without a short delay**
  ([niri #2463](https://github.com/niri-wm/niri/issues/2463), closed).
- **Tiling-specific game issues, open upstream**: window closes while the
  process keeps running after an in-game resolution change
  ([niri #3021](https://github.com/niri-wm/niri/issues/3021)); game window
  shrinks after switching focus
  ([niri #4275](https://github.com/niri-wm/niri/issues/4275)); some games
  freeze when unfocused
  ([niri #1959](https://github.com/niri-wm/niri/issues/1959)). gamescope is the
  documented workaround class for these.
- **gamescope on NVIDIA has open bugs** at the time of reading: periodic hangs
  ([#2096](https://github.com/ValveSoftware/gamescope/issues/2096)), overlay
  alpha artefacts on 595.71.05
  ([#2171](https://github.com/ValveSoftware/gamescope/issues/2171)), a nested
  dialog-ordering bug
  ([#2456](https://github.com/ValveSoftware/gamescope/issues/2456)). The DRM
  (embedded session) backend has an open report of corruption at every 4K mode
  on NVIDIA
  ([#2309](https://github.com/ValveSoftware/gamescope/issues/2309)), which is
  the reason not to enable `programs.steam.gamescopeSession` for this monitor.
- **gamescope version lag**: `nixos-26.05` has 3.16.23 while upstream issues
  reference 3.16.31. Fixes and regressions between them are not assessed.
- **If Steam exits abnormally inside gamescope**, later gamescope launches can
  fail until Steam has been started and closed normally once
  ([Niri Xwayland docs](https://github.com/niri-wm/niri/blob/main/docs/wiki/Xwayland.md#using-gamescope)).
  This applies to running Steam itself inside gamescope, which is not
  recommended here; wrap individual games instead.
- **Overlays**: with gamescope use `--mangoapp` rather than wrapping the game
  in `mangohud` (gamescope `--help` text in
  [`main.cpp`](https://github.com/ValveSoftware/gamescope/blob/master/src/main.cpp)).
- **NVIDIA VRAM held by Niri**: Niri documents an application-profile
  workaround (`GLVidHeapReuseRatio`) for high compositor VRAM use
  ([Niri Nvidia docs](https://github.com/niri-wm/niri/blob/main/docs/wiki/Nvidia.md)).
  Relevant with 8 GB VRAM; belongs to the NVIDIA ticket.
- **HDR** is out of scope: Niri HDR support was not established, and GE-Proton
  documents HDR as requiring a compositor path that supports it.

## What a VM cannot verify

A VM dry run can show only that the configuration evaluates and builds, that
Steam's closure (including 32-bit graphics) is present, that the Steam client
starts and reaches its login window under Niri through xwayland-satellite, and
that `gamescope`, `gamemoderun` and `gamemoded` exist.

Bare-metal only:

- Anything involving the NVIDIA driver: Vulkan, DXVK/VKD3D, DLSS/NVAPI, 32-bit
  NVIDIA libraries actually loading, shader compilation, performance.
- gamescope at all in a meaningful sense (it needs a working Vulkan driver).
- VRR, 120 Hz, the monitor's mode list, and every 1080p scaling option above.
- Cursor locking, fullscreen and focus behaviour of real games under Niri.
- GameMode's governor switch on real hardware, controllers, audio latency.
- Anti-cheat titles, which depend on per-game vendor support, not on this
  configuration.

## Open uncertainties

- gamescope nested under Niri on this NVIDIA driver is documented by Niri but
  unverified for this hardware; open upstream bugs make it a per-game tool.
- Whether Proton's fullscreen scaling (option 2) behaves well through
  xwayland-satellite at Niri `scale 2` is not documented anywhere read.
- Whether 4K 120 Hz and VRR work on the chosen cable/port was not researched
  from primary sources. Third-party listings give the monitor one DisplayPort
  1.4 and two HDMI 2.1 inputs; the GPU's HDMI output generation limits what
  HDMI can carry, so DisplayPort is the expected connection. Confirm with
  `niri msg outputs` on hardware.
- `ntsync` (Proton 11 has a `PROTON_NO_NTSYNC` switch, implying use when the
  kernel offers it) was not checked against the `nixos-26.05` kernel
  configuration.
- No source was found for a Valve-documented `PROTON_ENABLE_WAYLAND`; it is
  documented by Niri and GE-Proton only.
