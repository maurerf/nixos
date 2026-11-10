# Niri on NVIDIA under NixOS 26.05 (research)

[Knowledge index](README.md) · [Architecture](architecture.md) · [Deployment](deployment.md)

Research for the planned `desktop-pc` host (RTX 2060 SUPER, one 3840x2160
120 Hz monitor). Sources were read on 2026-11-10. Nothing here was built,
evaluated or run; every runtime claim is the source's, not an observation of
this hardware. Nix facts refer to the pinned nixpkgs revision
`f5c082a40f7571c266e74e80ae2e68aadd8a9fc7` (`nixos-26.05`) and Home Manager
`a6631107a83ceab5872f298a2ea710859c80c4cb` (`release-26.05`) from `flake.lock`.

## Recommendation

1. **Use the nixpkgs `programs.niri` module, not niri-flake.** The pin ships
   Niri 26.04 (latest upstream release) and xwayland-satellite 0.8.2, already
   in the official cache. niri-flake `main` pins `niri-stable` to v25.08 and
   xwayland-satellite v0.7, its `main` branch last changed on 2026-08-04 with
   breakage reports open since, and it would add a flake input plus a
   third-party binary cache. Its one real advantage is `programs.niri.settings` (config written
   in Nix); a plain `config.kdl` managed through Home Manager with
   `niri validate` at build time covers the same need.
2. **NVIDIA: default `stable` branch (595.71.05) with open kernel modules.**
   Set `services.xserver.videoDrivers = [ "nvidia" ]` and
   `hardware.nvidia.open = true`. Modesetting is already on by default for
   this driver version. Requires `allowUnfree` (userspace stays proprietary).
3. **Add the Niri VRAM application profile** through `environment.etc`, as the
   Niri wiki recommends for all NVIDIA users.
4. **Add `pkgs.xwayland-satellite` to the system packages.** The module
   deliberately does not enable Xwayland; Niri spawns satellite on demand when
   it is on `PATH`. Steam and X11 games need it.
5. **Set the output explicitly** in `config.kdl`: `mode` with the exact
   refresh from `niri msg outputs`, a `scale`, and
   `variable-refresh-rate on-demand=true` plus window rules for games.
6. **Pick session components separately** (see the table below); Niri ships
   none of them.

Unverified sketch of the system side (shape only, not built):

```nix
{
  programs.niri.enable = true;
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;

  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-niri-vram.json".text =
    builtins.toJSON {
      rules = [
        {
          pattern = { feature = "procname"; matches = "niri"; };
          profile = "Limit Free Buffer Pool On Wayland Compositors";
        }
      ];
      profiles = [
        {
          name = "Limit Free Buffer Pool On Wayland Compositors";
          settings = [ { key = "GLVidHeapReuseRatio"; value = 0; } ];
        }
      ];
    };
}
```

The NVIDIA part must stay out of the VM dry run (no NVIDIA device there).

## Findings

### nixpkgs module versus niri-flake

- `programs.niri.enable` at the pin installs the package, registers the
  display-manager session, installs the systemd user units, enables
  gnome-keyring, enables `xdg.portal` with `xdg-desktop-portal-gnome` and
  `-gtk`, sets the `niri` portal config (default `gnome;gtk`, Secret via
  gnome-keyring), and registers Nautilus on D-Bus for the GNOME file chooser
  (`programs.niri.useNautilus`, default true).
  [module](https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/nixos/modules/programs/wayland/niri.nix)
- Through the shared wayland-session helper it also enables polkit (the
  daemon, not an agent), a `swaylock` PAM service, dconf,
  `services.graphical-desktop` (which defaults `hardware.graphics`, PipeWire
  and default fonts on) and XDG autostart handling. It is called with
  `enableXWayland = false` and `enableWlrPortal = false`.
  [wayland-session.nix](https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/nixos/modules/programs/wayland/wayland-session.nix),
  [graphical-desktop.nix](https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/nixos/modules/services/misc/graphical-desktop.nix)
- The package is Niri 26.04 built with systemd, D-Bus and
  `xdp-gnome-screencast`. Upstream's latest release is v26.04 (2026-04-25).
  [package](https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/ni/niri/package.nix),
  [releases](https://github.com/niri-wm/niri/releases)
- Home Manager `release-26.05` has no `programs.niri` module. The NixOS wiki
  manages the config as `xdg.configFile."niri/config.kdl"` and shows a
  `runCommand` wrapper that runs `niri validate` at build time.
  [NixOS wiki: Niri](https://wiki.nixos.org/wiki/Niri)
- The NixOS wiki states niri-flake is only needed for a very recent Niri or
  for writing the configuration in Nix. [NixOS wiki: Niri](https://wiki.nixos.org/wiki/Niri)
- niri-flake `main` (read 2026-11-10) pins `niri-stable` to `v25.08`,
  `xwayland-satellite-stable` to `v0.7` and `nixpkgs-stable` to
  `nixos-25.11`. Its README says the cache serves `nixos-unstable` and
  `nixos-25.05`, that `programs.niri.settings` is not guaranteed compatible
  with other Niri versions, and that using its cache means trusting its
  maintainer. Open issues report evaluation/build breakage against newer
  nixpkgs and a community fork.
  [flake.nix](https://github.com/sodiboo/niri-flake/blob/main/flake.nix),
  [README](https://github.com/sodiboo/niri-flake/blob/main/README.md),
  [issue 1856](https://github.com/sodiboo/niri-flake/issues/1856),
  [issue 1851](https://github.com/sodiboo/niri-flake/issues/1851),
  [issue 1813](https://github.com/sodiboo/niri-flake/issues/1813)
- Niri's own NixOS note: a black screen from a TTY usually means Mesa out of
  sync between system and Niri. Using the nixpkgs package from the same pin
  avoids that by construction.
  [Getting Started](https://github.com/niri-wm/niri/blob/v26.04/docs/wiki/Getting-Started.md)

### NVIDIA driver options

- At the pin, `stable` = `production` = 595.71.05; `new_feature` is 590.48.01
  and `legacy_580` is 580.173.02 (described as for Maxwell through Volta).
  [nvidia-x11/default.nix](https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/os-specific/linux/nvidia-x11/default.nix),
  [nvidia.nix](https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/nixos/modules/hardware/video/nvidia.nix)
- `hardware.nvidia.open` has no default for drivers >= 560; leaving it unset
  fails an assertion whose message suggests open modules "on Turing or later
  GPUs (RTX series, GTX 16xx)". (same module)
- NVIDIA's 595.71.05 README: "We recommend the use of open kernel modules on
  all GPUs that support it." Listed downsides versus proprietary with GSP
  disabled: slower GPU initialization, longer suspend/resume latencies,
  marginal power impact; RTD3 only on Ampere and newer (not relevant to a
  desktop Turing card).
  [kernel_open](https://download.nvidia.com/XFree86/Linux-x86_64/595.71.05/README/kernel_open.html)
- The NixOS wiki likewise prefers open modules for Turing and newer and says
  unfree must be allowed even with them.
  [NixOS wiki: NVIDIA](https://wiki.nixos.org/wiki/NVIDIA)
- The module is activated by `"nvidia"` in `services.xserver.videoDrivers`
  even without an X server. `hardware.nvidia.modesetting.enable` defaults to
  true for drivers >= 535 and sets `nvidia-drm.modeset=1`, plus
  `nvidia-drm.fbdev=1` for >= 545. The module also adds the `egl-wayland`,
  `egl-gbm`, `egl-wayland2` ICDs and `nvidia-vaapi-driver`. (nvidia.nix)
- Niri requires GBM-capable drivers and kernel modesetting on NVIDIA.
  NVIDIA's README recommends `fbdev=1` against two-DRM-driver framebuffer
  conflicts. Both are met by the defaults above.
  [Getting Started](https://github.com/niri-wm/niri/blob/v26.04/docs/wiki/Getting-Started.md),
  [wayland-issues](https://download.nvidia.com/XFree86/Linux-x86_64/595.71.05/README/wayland-issues.html)
- Suspend: with open modules on 595 the module defaults
  `powerManagement.kernelSuspendNotifier` to true, but it only takes effect
  when `hardware.nvidia.powerManagement.enable = true` (default false,
  labelled experimental). The NixOS wiki describes `powerManagement.enable`
  as sometimes helping and sometimes causing suspend issues. Start without
  it; enable only if resume corrupts the session. (nvidia.nix, NixOS wiki)

### Known Niri/NVIDIA issues

- **VRAM**: Niri should use about 100 MiB; near 1 GiB indicates the NVIDIA
  heap-reuse quirk. The wiki's fix is an application profile setting
  `GLVidHeapReuseRatio` to 0 for process `niri` under
  `/etc/nvidia/nvidia-application-profiles-rc.d/`, then restarting Niri. The
  wiki says an upstream fix is unlikely.
  [Nvidia](https://github.com/niri-wm/niri/blob/v26.04/docs/wiki/Nvidia.md),
  [egl-wayland issue 126](https://github.com/NVIDIA/egl-wayland/issues/126)
- **Screencast flicker**: fixed in Niri since 25.08; the old debug flag is
  gone. (same wiki page)
- **Steam black window**: on some systems, fixed by disabling GPU-accelerated
  web views in Steam or launching with `-system-composer`.
  [Application Issues](https://github.com/niri-wm/niri/blob/v26.04/docs/wiki/Application-Issues.md)
- **Tearing**: Niri has no tearing page-flip support; the request is open.
  [issue 844](https://github.com/niri-wm/niri/issues/844)
- NVIDIA lists limited `nvidia-settings` on Wayland and no hardware overlays
  or front-buffer rendering for GLX under Xwayland. (wayland-issues)

### Xwayland for Steam and games

- Since Niri 25.08, Niri creates the X11 socket, exports `DISPLAY` and spawns
  `xwayland-satellite` (>= 0.7) on demand if the binary is on `PATH`; no
  manual service or `spawn-at-startup` is needed. The wiki names Steam and
  games as working.
  [Xwayland](https://github.com/niri-wm/niri/blob/v26.04/docs/wiki/Xwayland.md)
- nixpkgs 0.8.2 wraps satellite with `xwayland` on its `PATH`, so only that
  one package is needed.
  [package](https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/xw/xwayland-satellite/package.nix)
- Verification: the Niri journal shows `listening on X11 socket: :0`.
- Satellite scales most GTK/Qt apps automatically; Wine apps may render
  small on HiDPI and need per-app settings.
  [xwayland-satellite README](https://github.com/Supreeeme/xwayland-satellite/blob/v0.8.2/README.md)
- For fullscreen games misbehaving under a tiling compositor, the wiki
  recommends gamescope per game, e.g.
  `gamescope -f -w 1920 -h 1080 -W 1920 -H 1080 --force-grab-cursor --backend sdl -- %command%`.
  gamescope brings its own Xwayland and sets the render resolution, which is
  the natural route for 1080p games on the 4K panel. nixpkgs has
  `programs.gamescope` and `programs.steam` modules. Proton-GE's
  `PROTON_ENABLE_WAYLAND=1` is an experimental alternative.
  (Application Issues, Xwayland pages)

### VRR, mode and fractional scaling

- Niri picks the monitor's preferred mode, and the wiki warns that
  high-refresh monitors often prefer 60 Hz. Set
  `mode "3840x2160@<refresh>"` with the refresh matching `niri msg outputs`
  to three decimals.
  [Outputs](https://github.com/niri-wm/niri/blob/v26.04/docs/wiki/Configuration:-Outputs.md)
- Fractional scales such as `scale 1.5` are supported; unset, Niri guesses
  from physical size. (Outputs)
- `variable-refresh-rate` enables VRR if `niri msg outputs` reports support.
  `on-demand=true` turns it on only while a window with the
  `variable-refresh-rate true` window rule is shown, which the wiki suggests
  to avoid driver issues. Documented VRR problems: low-framerate cursor
  (workaround `debug { disable-cursor-plane }`), undetected VRR, and
  monitors that flash black continuously.
  (Outputs, [Window Rules](https://github.com/niri-wm/niri/blob/v26.04/docs/wiki/Configuration:-Window-Rules.md))

### Portals and screen sharing

- Screencasting uses portals plus PipeWire and needs
  `xdg-desktop-portal-gnome`, a D-Bus session, and Niri started as a session
  (display manager or `niri-session`). Monitors and single windows can be
  shared; `block-out-from "screencast"` hides chosen windows.
  [Screencasting](https://github.com/niri-wm/niri/blob/v26.04/docs/wiki/Screencasting.md)
- Upstream's portal set is gtk + gnome + gnome-keyring, with Nautilus needed
  for the GNOME file chooser. The nixpkgs module provides all of it, and
  graphical-desktop defaults PipeWire on.
  [Important Software](https://github.com/niri-wm/niri/blob/v26.04/docs/wiki/Important-Software.md)
- Do not set `GDK_BACKEND` globally; it breaks the screencast portal.
  (Important Software)
- Flatpak/portal apps read GNOME dconf settings (for example dark mode via
  `org.gnome.desktop.interface color-scheme`). (Important Software)

### Session components Niri leaves to the user

Niri "is not a complete desktop environment". Its default config binds
Alacritty (Mod+T), fuzzel (Mod+D) and swaylock (Super+Alt+L) and spawns
Waybar, but installs none of them. Components start either as systemd user
services bound to `graphical-session.target` or via `spawn-at-startup`.
[Getting Started](https://github.com/niri-wm/niri/blob/v26.04/docs/wiki/Getting-Started.md),
[Example systemd Setup](https://github.com/niri-wm/niri/blob/v26.04/docs/wiki/Example-systemd-Setup.md)

| Component | Provided by the nixpkgs module | Common choices (available at the pins) |
| --- | --- | --- |
| Greeter / display manager | Session file only | greetd with tuigreet or ReGreet; `services.displayManager.ly`, `sddm`, `gdm`; `dms-greeter`; greetd autologin straight into `niri-session` |
| Bar | No | Waybar (Home Manager `programs.waybar`); or a full shell |
| Launcher | No | fuzzel (Home Manager `programs.fuzzel`) |
| Notifications | No | mako, swaync (Home Manager services) |
| Screen locker | Only the `swaylock` PAM entry | swaylock; hyprlock |
| Idle / DPMS | No | swayidle calling `niri msg action power-off-monitors` and the locker; hypridle |
| Wallpaper | No (solid colour built in) | swaybg |
| Polkit agent | Polkit daemon only | Home Manager `services.polkit-gnome`; hyprpolkitagent; KDE agent |
| Terminal | No | Alacritty (default bind) or any |
| Xwayland | No | `xwayland-satellite` |
| File chooser backend | Nautilus registered by default | keep, or `useNautilus = false` for the GTK chooser |
| Keyring / Secret portal | gnome-keyring enabled | keep |
| Screenshots | Built into Niri | n/a |
| Output profiles | Static `output` blocks | kanshi (unneeded with one monitor) |

Alternative: one Quickshell-based shell replaces bar, launcher,
notifications, lock and more. Upstream's quick start uses DankMaterialShell
and also names Noctalia; nixpkgs at the pin has `programs.dms-shell`, a
`dms-greeter` module and `noctalia-shell` packages.

Other notes: the wiki warns Waybar starts twice if both the default
`spawn-at-startup "waybar"` line and a Waybar service are active. If the
locker dies Niri shows a red screen; bind the locker with
`allow-when-locked=true` to recover.
[FAQ](https://github.com/niri-wm/niri/blob/v26.04/docs/wiki/FAQ.md)
Electron apps need `NIXOS_OZONE_WL=1` or the `--ozone-platform=wayland`
flag to run natively. (NixOS wiki, Application Issues)

## Open uncertainties

- **Built-in VRAM profile.** NVIDIA ships default `GLVidHeapReuseRatio`
  profiles for several compositors since the 565 series (per the release
  note quoted in egl-wayland issue 126); whether 595.71.05
  already matches `niri` was not checked (it needs the driver's bundled
  profile file). The explicit profile is harmless either way. Confirm with
  `nvtop` on bare metal.
- **VRR on this monitor.** No source read confirms adaptive sync between
  this card, this monitor and Niri. Check `niri msg outputs` on bare metal
  and prefer on-demand VRR.
- **4K at 120 Hz link.** Which port/cable carries 120 Hz and whether the
  NVIDIA Linux driver negotiates the same mode as Windows was not
  researched; it is a bare-metal check via `niri msg outputs`.
- **Suspend/resume** with open modules on Turing is only described
  generically by NVIDIA and the NixOS wiki; untested here.
- **1080p games on the 4K panel.** gamescope is the documented route; its
  scaling quality, VRR pass-through and interaction with Niri fractional
  scaling are untested.
- **VM dry run.** Niri's docs require 3D acceleration in a VM. Whether a
  QEMU guest launched from WSL2 can provide usable GL (virgl or software
  rendering) is unverified and affects the dry-run acceptance criteria.
- **Version drift.** These facts are tied to the current lock; a later
  `flake.lock` update may change driver or Niri versions.
