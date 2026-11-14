# One AirPods link key for Windows and NixOS (research)

Research for [issue #80](https://github.com/maurerf/nixos/issues/80), part of
map [#56](https://github.com/maurerf/nixos/issues/56). Follows
[AirPods and Bluetooth audio on NixOS](https://github.com/maurerf/nixos/blob/research/airpods-bluetooth/docs/research/airpods-bluetooth.md)
([#26](https://github.com/maurerf/nixos/issues/26)). Sources read 2026-11-14.
Reading only: nothing here was run on `desktop-pc`, and no host was inspected.

## Answer in short

Pair the AirPods on NixOS first, then on Windows (Windows pairs last), then
copy the Windows link key into BlueZ's `[LinkKey]` once. Read the Windows key
from NixOS with `reged -x` (from nixpkgs `chntpw`) on a copy of the `SYSTEM`
hive, taken from a temporary read-only mount of the Windows partition. Nothing
is written to Windows. Stop `bluetooth.service` before editing the `info`
file and start it again afterwards. This is a documented one-off procedure on
mutable state, not a declarative setting: there is no NixOS option for it,
and a link key must not go into the Nix store. The copy holds until either
OS re-pairs, or the AirPods are reset.

## Why Windows misbehaves now (observed 2026-11-14)

A paired device stores one link key per host Bluetooth address. Windows and
NixOS share the Intel 3168 adapter address, so pairing on NixOS replaced, on
the AirPods, the key Windows created. Windows still has its old key and
therefore still lists the AirPods as paired.

Likely mechanism (inferred, not established from a primary source): the
baseband link comes up (Windows shows "connected"), but the link-key
authentication the AirPods require before audio profiles (A2DP/HFP) fails,
so no audio stream is set up and the link is torn down. That fits the
observed "connects, no audio, disconnects after a while". Windows' event log
or a Bluetooth HCI trace would confirm it; this was not checked. Either way,
the fix is the same: both OSes need the key the AirPods currently hold.

## Which keys AirPods use

- AirPods audio is classic Bluetooth (BR/EDR), see the
  [previous research](https://github.com/maurerf/nixos/blob/research/airpods-bluetooth/docs/research/airpods-bluetooth.md#recommended-configuration).
  A BR/EDR bond stores one 16-byte **link key**, plus a key type and PIN
  length [1][2].
- Whether AirPods also store LE keys (LTK/IRK) after pairing with a non-Apple
  host was **not established**. Check before copying, without printing key
  values:
  - BlueZ: list the group headers in the `info` file
    (`sudo grep '^\[' /var/lib/bluetooth/<adapter>/<device>/info`). Only
    `[LinkKey]` means BR/EDR only. `[LongTermKey]`, `[PeripheralLongTermKey]`
    or `[IdentityResolvingKey]` mean LE keys too [1].
  - Windows: a BR/EDR-only device is one `REG_BINARY` value named after the
    device address under the adapter key. LE-bonded devices get a per-device
    **subkey** with `LTK`, `KeyLength`, `ERand`, `EDIV`, `IRK`, `Address` and so on
    [3].
- If LE keys exist, the Arch wiki has per-device transformation tables
  (ERand byte reversal, decimal conversion) but no AirPods entry; treat that
  case as unverified and fall back to re-pairing [3]. Audio needs only
  the BR/EDR link key.

## Storage formats

| | Windows | BlueZ (NixOS) |
| --- | --- | --- |
| Location | `HKLM\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters\Keys\<adapter>`; offline: `Windows/System32/config/SYSTEM`, `ControlSet00X\...` [3][4] | `/var/lib/bluetooth/<adapter>/<device>/info`, group `[LinkKey]` [1] |
| Name | value named after the device address, lowercase hex, no colons [4] | directory named after the device address, uppercase with colons [1] |
| Key | `REG_BINARY`, 16 bytes; `.reg` export: `hex:a6,1b,...` [4] | `Key=` 32 uppercase hex characters [1][5] |
| Type / PIN length | not stored with the value (not found in any source) | `Type=`, `PINLength=` integers [1][5] |
| Access | SYSTEM account only; admin regedit needs `PsExec -s` [3][6] | root, file mode 0600 [5] |

**Byte order: no conversion.** BlueZ writes `key[0]..key[15]` as uppercase hex
in order [5]. bt-dualboot moves keys between the two formats by only stripping
or adding the `hex:` prefix and commas, without reversing [4], and the Arch
wiki says to copy the Windows bytes, remove spaces and uppercase them [3].
(Only old macOS, High Sierra and earlier, needs reversal [3].)

Keep BlueZ's existing `Type` and `PINLength`. BlueZ defines type values `0x04`
to `0x08` for Secure Simple Pairing keys (unauthenticated/authenticated, P-192/P-256) [2].
Both OSes paired the same device with the same adapter, so the type should
match, but that is an assumption.

## Which direction

**Recommended: Windows pairs last, key copied into BlueZ.**

- Writes only to NixOS-owned state; the Windows hive is only read.
- Reading the hive from NixOS needs no Windows tooling.
- The [dual-boot layout](https://github.com/maurerf/nixos/blob/main/docs/decisions.md)
  has no Windows mounts. A temporary, read-only mount by hand fits that
  decision, because nothing is added to the configuration.
  Windows Fast Startup and hibernation are already off, so the NTFS
  volume is cleanly closed.

**Alternative: NixOS pairs last, key written into Windows.** This is what
`bt-dualboot` automates (Linux to Windows only; "pull" is explicitly out of
scope) [4]. It needs a **read-write** NTFS mount and edits the SYSTEM hive with
`reged -I`, which its README calls "non-official and hackish"; `chntpw` itself
says it supports Windows "NT3.x to Win8.1" and is "somewhat hackish" [4][7].
bt-dualboot was tested on Linux Mint and Windows 10, copies only
`[LinkKey]`, so it does not support LE [3][4], and its last release is v1.0.1
(repository last pushed 2024-05-28) [4]. A broken SYSTEM hive can stop Windows
from booting, which is a worse failure than a broken BlueZ `info` file.

## Procedure (recommended direction)

Run by hand with explicit approval; not run yet.

1. NixOS: AirPods already paired (done in
   [#57](https://github.com/maurerf/nixos/issues/57)). Back up the device
   directory: `sudo cp -a /var/lib/bluetooth/<adapter>/<device> /root/airpods-info.bak`.
2. Windows: remove the stale AirPods entry, pair again, check audio works.
   From now on, only Windows has a matching key until step 5.
3. NixOS: identify the Windows partition (`lsblk -f`), then mount read-only:
   `sudo mount -o ro -t ntfs3 /dev/<part> /mnt` (or `ntfs-3g` from
   `nix shell nixpkgs#ntfs3g`). If the volume is BitLocker-encrypted this
   fails; see "Fallback" below.
4. Copy the hive to RAM and export only the adapter's key:
   ```sh
   sudo cp /mnt/Windows/System32/config/SYSTEM /run/airpods-hive  # /run is tmpfs
   sudo umount /mnt
   reged=$(nix build --no-link --print-out-paths nixpkgs#chntpw)/bin/reged
   sudo "$reged" -x /run/airpods-hive \
     'HKEY_LOCAL_MACHINE\SYSTEM' 'ControlSet001\Services\BTHPORT\Parameters\Keys' /root/bt.reg
   ```
   Check `Select\Current` (or `ls` in `chntpw -e`) if `ControlSet001` is not
   the current set [3]. `reged -x` only exports [7].
5. `sudo systemctl stop bluetooth`, then replace `Key=` under `[LinkKey]` in
   the AirPods' `info` with the 16 bytes from `bt.reg`, uppercase and without
   commas. Leave `Type`/`PINLength` alone. `sudo systemctl start bluetooth`.
   bluetoothd loads stored keys into the kernel only at adapter
   initialisation (`Load Link Keys`) and rewrites `info` whenever a value
   changes, so editing while it runs can be lost or ignored [2][5].
6. Delete the hive copy and `bt.reg` (`shred -u`): the hive holds other
   secrets, and both files hold the link key [4]. Never paste the key into the
   repository, an issue or a shell history that is kept.
7. Test audio on NixOS, then reboot into Windows and test again.

**Fallback if Windows is BitLocker-encrypted:** export on Windows instead:
`PsExec64.exe -s -i regedit.exe`, export
`HKLM\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters\Keys\<adapter>` to a
`.reg` file on a USB stick, use it in step 5, then delete it [3][6]. Avoid the
shared ESP as the exchange location: it is unencrypted FAT and easy to forget.

## Does the key stay stable?

- A bonded link key is stored and reused for later connections. A new one is
  only created by a new pairing; BlueZ only stores keys it receives in a
  `New Link Key` event [2]. Normal reconnects therefore keep the key. Not
  confirmed from an Apple source for AirPods.
- **Breaks the match:** re-pairing on either OS (including "Remove device" on
  Windows or `bluetoothctl remove` on NixOS), or resetting the AirPods, which
  the Apple procedure follows with a fresh pairing [8].
- **Firmware updates:** no source found either way. If the AirPods stop
  working on one OS after an update, compare keys again (redo steps 2 to 7).
- A one-time copy therefore holds as long as nobody re-pairs; any later
  re-pair needs the procedure again.

## Packaging and declarativeness (nixpkgs `nixos-26.05`, checked 2026-11-14) [10]

- `chntpw` is packaged (version `140201`) and provides `chntpw` and `reged`.
- `bt-dualboot` is **not** packaged (no attribute, no occurrence in the
  nixpkgs tree, also not under `python3Packages`).
- The kernel's NTFS support is in nixpkgs' common kernel config;
  `boot.supportedFilesystems.ntfs` would only add `ntfs-3g` to the system and
  is not needed for a temporary mount.
- Nothing should be declarative. `/var/lib/bluetooth` is state that
  bluetoothd rewrites, BlueZ advises against touching it from outside
  bluetoothd [1], and a link key in the flake would end up world-readable in
  `/nix/store`. A secrets mechanism plus a pre-start unit could in theory
  install the key, but the AirPods would still change it on any re-pair; not
  worth the complexity. Use `nix shell nixpkgs#chntpw` for the one-off.

## Risks and undo

| Option | Risk | Undo |
| --- | --- | --- |
| Copy Windows key into BlueZ (recommended) | Wrong bytes or type: AirPods fail on NixOS. Key left in a temp file. | Stop bluetooth, restore `/root/airpods-info.bak`, start bluetooth; or re-pair on NixOS (breaks Windows again). |
| bt-dualboot / write into Windows hive | Corrupt SYSTEM hive, Windows may not boot; needs rw NTFS mount. | bt-dualboot's backup (`--backup`), or restore the hive copy; Windows recovery otherwise. |
| Re-pair on each OS switch (status quo) | Inconvenient only. | None needed. |

## Uncertainties

- Whether AirPods bond LE keys as well as the BR/EDR link key with Windows 11
  and BlueZ; check the groups as above before copying.
- The failure mechanism behind the Windows symptom is inferred, not traced.
- No Microsoft documentation of the `BTHPORT\Parameters\Keys` layout was found; the
  location and format come from bt-dualboot's source, the Arch wiki and a
  community write-up [3][4][9].
- Whether Windows on `desktop-pc` uses BitLocker or device encryption is
  unknown (not inspected).
- AirPods firmware-update behaviour and Apple's reset semantics are not
  documented in detail by Apple [8].

## Sources

1. BlueZ, [doc/settings-storage.txt](https://github.com/bluez/bluez/blob/master/doc/settings-storage.txt)
2. BlueZ, [doc/mgmt-protocol.rst](https://github.com/bluez/bluez/blob/master/doc/mgmt-protocol.rst) (Load Link Keys, New Link Key)
3. Arch wiki, [Bluetooth: Dual boot pairing](https://wiki.archlinux.org/title/Bluetooth#Dual_boot_pairing) (raw source read 2026-11-14)
4. [x2es/bt-dualboot](https://github.com/x2es/bt-dualboot): README, `bt_windows/convert.py`, `bt_sync_manager/bt_sync_manager.py`, `bt_linux/bluetooth_device_factory.py`, `windows_registry/windows_registry.py`
5. BlueZ, [src/adapter.c](https://github.com/bluez/bluez/blob/master/src/adapter.c) (`get_key_info`, `store_link_key`, `load_link_keys`)
6. Microsoft, [PsExec](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec)
7. `chntpw`/`reged` 140201 usage text (nixpkgs `nixos-26.05` build)
8. Apple, [Reset your AirPods](https://support.apple.com/en-us/118531)
9. grawity, [Bluetooth key sharing](https://nullroute.lt/~grawity/bluetooth-key-sharing.html)
10. nixpkgs `nixos-26.05`: `pkgs/by-name/ch/chntpw/package.nix`,
    `pkgs/os-specific/linux/kernel/common-config.nix`,
    `nixos/modules/tasks/filesystems/ntfs.nix`
