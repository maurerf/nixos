# AirPods and Bluetooth audio on NixOS (research)

Research for [issue #26](https://github.com/maurerf/nixos/issues/26), part of
map [#21](https://github.com/maurerf/nixos/issues/21). Sources read
2026-11-10. This is reading only: nothing here was tested on the target
hardware, and no configuration has been written yet.

Target: `desktop-pc`, NixOS 26.05, Niri (Wayland), Intel Bluetooth on an Intel
Wireless-AC 3168 combo card, AirPods and an MX Master 3S, dual-boot with
Windows 11.

## Answer in short

Enable BlueZ and PipeWire with their defaults and add no WirePlumber Bluetooth
overrides. The nixpkgs PipeWire build already carries AAC, and WirePlumber's
defaults already enable mSBC and automatic headset-profile switching. The real
limits are not configuration problems: the AirPods microphone forces a
low-quality headset profile, and AirPods must be re-paired (or have their link
key copied) after each OS switch because both systems share one adapter
address. The mouse avoids that by using a separate Easy-Switch channel per OS.

## Recommended configuration

```nix
{
  hardware.bluetooth.enable = true;      # powerOnBoot already defaults to true

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;            # 32-bit ALSA clients, e.g. Steam games
    pulse.enable = true;
  };
}
```

Why this is enough:

- `hardware.bluetooth.enable` installs `pkgs.bluez`, runs `bluetoothd` and
  writes `/etc/bluetooth/main.conf` with `General.ControllerMode = "dual"` and
  `Policy.AutoEnable = powerOnBoot` (default `true`) [1]. `dual` is what the
  two devices need together: AirPods audio is classic Bluetooth (BR/EDR) and
  the mouse is Bluetooth LE.
- WirePlumber is enabled whenever `services.pipewire.enable` is set [2], and
  it is the component that owns Bluetooth audio.
- AAC: the nixpkgs PipeWire package (1.6.11 on `nixos-unstable` when read)
  lists `fdk_aac` among its Bluetooth build inputs [3], and upstream builds the
  AAC codec plugin whenever that dependency is found; there is no separate
  switch [4]. WirePlumber's `bluez5.codecs` defaults to all available codecs
  [5]. No `pulseaudioFull`-style override is needed; that advice on the NixOS
  Bluetooth wiki page applies to PulseAudio only [6].
- mSBC, SBC-XQ and hardware volume default to `true`, subject to the hardware
  quirks database [5]. mSBC is always built [4].
- `bluetooth.autoswitch-to-headset-profile` defaults to `true`: the device
  switches to HSP/HFP when an application starts recording and returns to the
  previous profile when recording ends [7].

Deliberately left out:

- No `services.pipewire.wireplumber.extraConfig` block for `bluez5.roles`. The
  NixOS PipeWire wiki shows one but warns that it "may break wireplumber" and
  can remove the A2DP playback options (SBC, SBC-XQ, AAC) [8]. It also only
  restates defaults.
- No `General.ControllerMode = "bredr"`. Forum posts suggest it as an AirPods
  pairing fix, but BlueZ documents it as restricting every controller to that
  transport [9], which would cut off the LE mouse. Treat it as a temporary
  troubleshooting step only, if pairing fails.
- No `hardware.bluetooth.hsphfpd.enable`. The WirePlumber module asserts
  against it [2].

Optional, decide at execution time:

- `hardware.bluetooth.settings.General.Experimental = true;` enables BlueZ's
  experimental D-Bus interfaces [9]; the NixOS wiki uses it for battery
  reporting and notes it may cause bugs [6]. Leave off unless battery level is
  wanted.
- If a separate microphone is used and AirPods should never drop to headset
  quality:

  ```nix
  services.pipewire.wireplumber.extraConfig."11-bluetooth-policy" = {
    "wireplumber.settings"."bluetooth.autoswitch-to-headset-profile" = false;
  };
  ```

  This is the form the NixOS wiki gives [8] for the setting documented
  upstream [7].
- `bluetooth.autoswitch-restore-timeout` (default 4000 ms) can be raised if an
  application closes and reopens the microphone and the profile flaps [7].

## Expected limitations

### Codec (AAC)

AAC should be offered for AirPods playback, with SBC and SBC-XQ as fallbacks.
PipeWire's AAC encoder defaults to constant bitrate
(`bluez5.a2dp.aac.bitratemode = 0`; 1 to 5 select variable-bitrate quality
levels) [10]. Apple-only features such as automatic device switching and
spatial audio are outside what BlueZ and PipeWire provide; this was not
researched further.

### Microphone quality

Using the AirPods microphone means leaving A2DP for the headset profile.
WirePlumber's own documentation says headset mode has much lower audio quality
than A2DP, which is why it switches only while a capture stream exists [7].
Playback is degraded for the duration of a call. The codec in that mode is mSBC
or CVSD; PipeWire also builds an LC3-SWB headset codec [4], but whether AirPods
negotiate it was not established.

Community reports on AirPods in headset mode are mixed, including no audio and
"robotic" mSBC sound on some setups [11]. These are forum posts and bug
reports with varying hardware, so they show a risk, not an expected outcome.
A wired or USB microphone with autoswitch disabled is the dependable fallback.

### Dual-boot re-pairing

Both operating systems use the same adapter address but create their own
pairing keys, so a device paired on one OS is rejected by the other.

- **MX Master 3S:** pair Windows on one Easy-Switch channel and NixOS on
  another, then switch channels with the button on the underside. Logitech
  documents three channels, each paired separately [12]. No key copying needed.
- **AirPods:** they have no channels. Either re-pair after each OS switch, or
  copy the key once: pair on NixOS, then pair on Windows, then copy the Windows
  link key into the `[LinkKey]` group of
  `/var/lib/bluetooth/<adapter>/<device>/info` and restart `bluetooth.service`.
  BlueZ documents that file layout and the `[LinkKey]` fields [13]; the Windows
  side lives in the SYSTEM hive under
  `ControlSet001\Services\BTHPORT\Parameters\Keys`, readable from Linux with
  `chntpw`, per community guides [14]. Any later re-pair on either OS breaks
  the match.
- Caveats: BlueZ calls direct edits of its storage "highly discouraged" [13].
  The procedure is manual state outside the flake. `bt-dualboot` automates the
  opposite direction (Linux keys into the Windows registry), is tested only on
  Linux Mint and Windows 10, and calls hive editing "non-official and hackish"
  [15]. For the trial, re-pairing AirPods on demand is the low-risk choice.

## Pairing UI for Niri

Niri is not a full desktop environment and ships no Bluetooth UI; its own
software list covers notifications, portals and a polkit agent but nothing for
Bluetooth [16]. Options named by the NixOS wiki [6]:

| Option | Fit for Niri |
| --- | --- |
| `bluetoothctl` (`pair`, `trust`, `connect`) | Comes with BlueZ, always available. Good fallback. |
| `bluetui` or `bluetuith` (TUI) | Runs in a terminal, needs no tray or bar. Best default while the bar/shell choice is open. |
| `services.blueman.enable` | Installs Blueman and registers its D-Bus and systemd units [17]. `blueman-manager` is an ordinary window; `blueman-applet` needs a bar with a system tray. |
| `overskride` (GTK4 GUI) | Standalone window, no tray needed. |

Recommendation: a TUI plus `bluetoothctl` for the first build; add Blueman
only if the chosen bar has a tray. If the session ticket picks a desktop shell
with its own Bluetooth panel, that replaces all of these.

## Uncertainties

- Nothing was tested on the hardware. AirPods model and firmware matter and
  are not recorded.
- nixpkgs sources were read on `nixos-unstable`, not the `release-26.05`
  branch. Option names here are long-standing, but confirm at build time.
- Package attribute names for `bluetui`, `bluetuith` and `overskride` were
  taken from the NixOS wiki, not checked against nixpkgs.
- Intel Bluetooth firmware: the adapter needs firmware from `linux-firmware`.
  This is normally covered by `hardware.enableRedistributableFirmware`, which
  generated hardware configurations usually enable; that was not verified from
  source in this session. Check `dmesg` for firmware load errors on first boot.
- Wi-Fi/Bluetooth coexistence: the 3168 shares 2.4 GHz between both radios.
  The kernel's iwlwifi page says coexistence is well tested on 7260 and newer
  and does not single out the 3168 [18]. The host uses Ethernet, so the risk
  is small; audio stutter under 2.4 GHz Wi-Fi load would point here.
- Whether each Easy-Switch channel presents a distinct Bluetooth address (what
  makes the two-channel approach work against one adapter) is widely reported
  but was not confirmed from a primary source.
- The key-copy registry path comes from community guides. The Arch wiki
  dual-boot section, the intended secondary source, could not be fetched
  (blocked by bot protection), as was the PipeWire GitLab; the PipeWire GitHub
  mirror was read instead.
- The PipeWire and WirePlumber documentation list `hfp_hf` in the default
  `bluez5.roles` while also saying only HFP is enabled by default [5][10];
  whether HSP roles are on by default is unclear. It does not affect AirPods,
  which use HFP.

## Sources

1. nixpkgs, `nixos/modules/services/hardware/bluetooth.nix`:
   <https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/hardware/bluetooth.nix>
2. nixpkgs, `nixos/modules/services/desktops/pipewire/wireplumber.nix`:
   <https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/desktops/pipewire/wireplumber.nix>
3. nixpkgs, `pkgs/by-name/pi/pipewire/package.nix`:
   <https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/pi/pipewire/package.nix>
4. PipeWire, `spa/plugins/bluez5/meson.build` (GitHub mirror):
   <https://github.com/PipeWire/pipewire/blob/master/spa/plugins/bluez5/meson.build>
5. WirePlumber, Bluetooth configuration:
   <https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/bluetooth.html>
6. NixOS wiki, Bluetooth: <https://wiki.nixos.org/wiki/Bluetooth>
7. WirePlumber, settings:
   <https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/settings.html>
8. NixOS wiki, PipeWire: <https://wiki.nixos.org/wiki/PipeWire>
9. BlueZ, `src/main.conf`:
   <https://github.com/bluez/bluez/blob/master/src/main.conf>
10. PipeWire, `pipewire-props(7)`:
    <https://docs.pipewire.org/page_man_pipewire-props_7.html>
11. Community reports (low trust), for example PipeWire issue 1631:
    <https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/1631>
12. Logitech, Getting Started: MX Master 3S:
    <https://support.logi.com/hc/articles/5218056588311-Getting-Started-MX-Master-3S>
13. BlueZ, `doc/settings-storage.txt`:
    <https://github.com/bluez/bluez/blob/master/doc/settings-storage.txt>
14. Community guides for key copying (low trust), for example:
    <https://unix.stackexchange.com/questions/255509>
15. `bt-dualboot` README: <https://github.com/x2es/bt-dualboot>
16. Niri wiki, Important Software:
    <https://github.com/niri-wm/niri/blob/main/docs/wiki/Important-Software.md>
17. nixpkgs, `nixos/modules/services/desktops/blueman.nix`:
    <https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/desktops/blueman.nix>
18. Linux wireless documentation, iwlwifi:
    <https://wireless.docs.kernel.org/en/latest/en/users/drivers/iwlwifi.html>
