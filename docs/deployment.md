# Validation and deployment

[Knowledge index](README.md) · [VPS recovery](vps-recovery.md)

## Select checks

For a package or host-module change, evaluate and build the affected host. Shared
modules or shared inputs affect both hosts; validate both where possible and report
unavailable native platforms. Documentation-only edits need Markdown link, content
and Git diff checks. No new planning/evidence files are required for ordinary work.

Run from the repository root with locked inputs, selecting applicable commands:

```sh
nix eval --raw .#darwinConfigurations.m2-macbook-air.system.drvPath --no-update-lock-file --no-write-lock-file
nix eval --raw .#nixosConfigurations.vps.config.system.build.toplevel.drvPath --no-update-lock-file --no-write-lock-file
nix flake check --no-build --all-systems --no-update-lock-file --no-write-lock-file
git diff --check
# Native Mac (or compatible builder)
nix build .#darwinConfigurations.m2-macbook-air.system --no-update-lock-file --no-write-lock-file
# Native Linux (or compatible builder)
nix build .#nixosConfigurations.vps.config.system.build.toplevel --no-update-lock-file --no-write-lock-file
```

`desktop-pc` has two outputs to evaluate and build: the toplevel and its VM
(`config.system.build.vm`). A change to the Linux base or the Workstation module
affects it too. Changes to the Linux base must leave the VPS toplevel `drvPath`
unchanged unless a VPS change is intended. Without a native Linux machine, build
in NixOS-WSL on the Windows PC (WSL 3.0.5 + NixOS-WSL 2605.7.2, set up 2026-11-10):

```sh
nix eval --raw .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath --no-update-lock-file --no-write-lock-file
nix eval --raw .#nixosConfigurations.desktop-pc.config.system.build.vm.drvPath --no-update-lock-file --no-write-lock-file
nix build .#nixosConfigurations.desktop-pc.config.system.build.toplevel --no-update-lock-file --no-write-lock-file
nix build .#nixosConfigurations.desktop-pc.config.system.build.vm --no-update-lock-file --no-write-lock-file
```

To run the VM from NixOS-WSL with nested KVM and GL through WSLg, delete any old
`desktop-pc.qcow2` in the working directory for a fresh disk, then run:

```sh
export LD_LIBRARY_PATH=/run/opengl-driver/lib GALLIUM_DRIVER=d3d12
export QEMU_OPTS="-chardev socket,id=ser0,path=/tmp/vm-serial.sock,server=on,wait=off,logfile=$PWD/serial.log -serial chardev:ser0 -monitor unix:/tmp/vm-mon.sock,server=on,wait=off"
export QEMU_KERNEL_PARAMS="systemd.wants=serial-getty@ttyS0.service"
./result/bin/run-desktop-pc-vm
```

Both GL variables are needed; without them QEMU falls back to software GL
([observation](https://github.com/maurerf/nixos/issues/32)). The other two are
optional and change no configuration: they give a scriptable serial console
(write to the socket, read `serial.log`) and a QEMU monitor, and start a getty
on `ttyS0`, which systemd does not do on its own here. The VM login is `fdm`
with the throwaway password `fdm`, and Niri's modifier is Alt.

Observed in the first dry run (2026-11-10,
[findings](https://github.com/maurerf/nixos/issues/36)): the guest resolution
follows the QEMU window, and Ctrl+Alt+F (fullscreen) gives 1920x1080 on the 4K
monitor at 200 % Windows scaling. Windows keeps Alt+Space, Alt+Escape and the
other Alt shortcuts it owns, and Ctrl+Alt+G (input grab) did not change that.
Send those keys through the monitor instead, for example
`echo "sendkey alt-spc" | nix shell nixpkgs#socat -c socat - UNIX-CONNECT:/tmp/vm-mon.sock`.

PR CI evaluates the outputs and checks the flake; it does not replace native builds.
The [Fredy candidate](fredy.md) has two VPS outputs; evaluate and build both
`vps-fredy-bootstrap` and `vps` before its staged activation. The Mac output is
unchanged by this VPS-only change.
For deployment, build the clean, committed candidate on each affected native host,
record its full source commit, `nix hash file flake.lock`, output (`realpath result`),
and old active/selected system paths. Keep later documentation commits distinct.
Compare `nix store diff-closures "$OLD" "$NEW"` and
`nix path-info --closure-size "$OLD" "$NEW"`; review removals, migrations, state
compatibility and free bytes/inodes. Reuse results only for unchanged relevant inputs.

## Deployment

Before activating **each production host**, present the concrete candidate, target
host, build results, relevant changes, risks, recovery route and timing constraints;
obtain explicit user approval. A request to update inputs is not activation approval.
Do not infer approval from archived waivers. Check [retained decisions](decisions.md)
and establish fresh access, backup and recovery readiness for the actual change.

For updates affecting both hosts, prepare outside the outage windows, deploy Mac
first and accept it before the separate VPS window. Reconfirm the historical
planning allowance of two hours per window and at most one hour of mail interruption
with the operator; an unmeasured restore cannot guarantee that deadline. Single-host
changes need only their affected host window.

Set `CANDIDATE` to the reviewed full commit, never a moving branch. Before activation,
record the old generation number/closure and verify it is retained and readable
(`nix store verify --recursive --no-trust "$OLD"`). Keep recovery access available.

Mac, after approval:

```sh
sudo darwin-rebuild switch --flake "github:maurerf/nixos/$CANDIDATE#m2-macbook-air" --no-update-lock-file --no-write-lock-file
```

Check `darwin-version --configuration-revision`, active and selected paths
(`/run/current-system`, `/nix/var/nix/profiles/system`), daemon health and
`nix store ping --store daemon`. In a fresh Terminal verify login, Zsh/Git, app
discovery and launches for the operator's currently used apps. Compare manual
Homebrew inventory when relevant. Establish mutable-data backup and independent
recovery access anew; the [Mac waiver](decisions.md#historical-exceptions) is not a backup.
For Home Manager app-link migrations, inspect any old trampolines and their
embedded launch targets before moving them aside; verify Spotlight resolves to
the current copied apps and repeat discovery after a fresh login.

VPS: complete [recovery preparation](vps-recovery.md), establish baseline mail/access
checks below, and keep a second SSH session plus independent Vultr console available.
For a compatible live transition, the proposed route is:

```sh
sudo nixos-rebuild test --flake "github:maurerf/nixos/$CANDIDATE#vps" --no-update-lock-file --no-write-lock-file
# Only after test succeeds and acceptance checks pass:
sudo nixos-rebuild switch --flake "github:maurerf/nixos/$CANDIDATE#vps" --no-update-lock-file --no-write-lock-file
```

`test` activates services and can write mail state; it is not a dry run. Recheck
acceptance after each step. A failed step stops this sequence for diagnosis and a
recovery decision. A migration requiring reboot needs a separately reviewed and
approved `boot`/reboot route, with target selected before reboot and target
booted/active/selected afterward. The [2026 D-Bus failure](decisions.md#historical-exceptions)
is not a general fallback authorization.

Fredy adds a justified public HTTPS requirement on TCP 443. Its
[first-login sequence](fredy.md#first-login-and-public-switch) uses
`#vps-fredy-bootstrap` first, then `#vps` only after the initial password has
been replaced and verified. Both stages require the same mail/access checks
after `test` and `switch`. Public 443 is expected only for the Fredy HTTPS
host; direct 9998 and quota-status 12340 remain nonpublic. Check the Vultr
firewall independently of the NixOS firewall and preserve port 80 for ACME.

## VPS acceptance

Before and after activation, verify the candidate/baseline revision with
`nixos-version --configuration-revision`; compare `/run/current-system`,
`/nix/var/nix/profiles/system` and, after reboot, `/run/booted-system` to expected
closures. After a successful `test`, the active path should match the candidate;
the selected and booted paths remain at their recorded pre-test values.
Check zero failed units, required services, queue depth, free space/inodes, intended
listeners and host/provider firewall rules. The 2026-09-28 service names were
`postfix dovecot rspamd nginx sshd redis-rspamd kresd@1`; verify actual names for
the candidate rather than assuming them forever.

Use an independent external client for SSH, TCP reachability and mail checks:

- Intended public ports before Fredy: 22, 25, 80, 465, 993. The Fredy
  candidate adds HTTPS 443 after its approved staged activation. Keep direct
  Fredy 9998 and quota-status 12340 nonpublic.
- Validate TLS chain, hostname and expiry on SMTP STARTTLS 25, submission 465 and
  IMAPS 993; check MX/A/AAAA, sender PTR/forward identity, SPF, DKIM and DMARC.
- Send controlled messages to the primary account and alias, verify IMAPS receipt
  and private readability, then authenticated outbound submission and actual
  external receipt with SPF/DKIM/DMARC. An accepted submission is not proof of delivery.
- Reconcile synthetic message IDs across folders before/after; retain only sanitized
  metadata. Confirm password SSH and mail authentication if credentials changed.
- Check IPv4 and IPv6 from capable clients. Unavailable IPv6 checks remain incomplete
  unless a new scoped deferral is explicitly accepted; the old deferral is not a pass.

Measure interruption, report failures and missing messages, and do not call deployment
complete on service status alone. Source: [2026-09-28 postboot service and external
mail checks](archive/01-checkup/EVIDENCE.md#us-06-controlled-reboot-and-initial-postboot-checks-2026-09-28t202115z202212z),
not a fresh runtime inspection.

## Generation recovery

Confirm installed/target tool syntax, the recorded old generation, data compatibility
and recovery authorization before using these commands. Software rollback does not
undo mutable data writes. Recheck the same host acceptance afterward.

Mac: `sudo darwin-rebuild --switch-generation "$MAC_OLD_GEN"`; if PATH is broken,
use `sudo "$MAC_OLD/sw/bin/darwin-rebuild" --switch-generation "$MAC_OLD_GEN"`
from a tested recovery shell. Active and selected paths must match `MAC_OLD`.

VPS after `test`, only with compatible state:
`sudo "$VPS_OLD/bin/switch-to-configuration" test`.
After persistent selection, restore selected and active generation explicitly:

```sh
sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation "$VPS_OLD_GEN"
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

Use the console if SSH fails; for boot failure select the recorded old boot-menu
entry. Kernel/boot transitions may require a reviewed reboot. For incompatible mail
state, stop generation downgrade and use the [restore assessment](vps-recovery.md#snapshot-recovery).

## desktop-pc bare-metal install

Installs `desktop-pc` beside Windows on the NVMe, following the
[layout decision](https://github.com/maurerf/nixos/issues/30) and the
[procedure decisions](https://github.com/maurerf/nixos/issues/43). First run
2026-11-11 at `fead80f` and accepted 2026-11-13 without changes to the commands
([run and results](https://github.com/maurerf/nixos/issues/45)). Running it
again needs explicit approval and the
[verified Windows backup](https://github.com/maurerf/nixos/issues/42),
including its copy of the ESP contents.

The Dell stays on HDMI for the install; the Niri output block matches the monitor
itself and takes the highest refresh rate the link offers. Record the reviewed
`main` commit as `CANDIDATE` before starting. Stop at each **checkpoint** if the
output differs from what is described.

### 1. Prepare on Windows

1. Download `latest-nixos-minimal-x86_64-linux.iso` and its `.sha256` file from
   `https://channels.nixos.org/nixos-26.05/`. Compare
   `Get-FileHash -Algorithm SHA256 <iso>` with the `.sha256` content, then write
   the ISO to a USB stick with Rufus in DD image mode. Keep the stick unchanged
   until install acceptance; it is also the rescue tool.
2. In an elevated PowerShell, turn off hibernation and Fast Startup, and make
   Windows keep the hardware clock in UTC:

   ```powershell
   powercfg /h off
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f
   ```

3. Shrink `C:` by 200 GiB. First check that the limit allows it; if `SizeMin`
   is too high, shrink by the largest amount offered instead:

   ```powershell
   $c = Get-Partition -DriveLetter C
   ($c.Size - (Get-PartitionSupportedSize -DriveLetter C).SizeMin) / 1GB   # must be at least 200
   Resize-Partition -DriveLetter C -Size ($c.Size - 200GB)
   (Get-Partition -DiskNumber $c.DiskNumber -PartitionNumber 1).Guid         # the ESP
   ```

   The last line must print `{66b88416-5d45-4cf6-8cf4-3c9a4523fc79}`, the
   PARTUUID in `hardware/desktop-pc.nix`. If it differs, stop and correct the
   hardware file by PR first.

**Checkpoint 1:** restart Windows. It must boot normally, `C:` must be about
730 GiB with about 200 GiB unallocated directly after it, and the clock must be
right (run `w32tm /resync` if it is off by the UTC offset after the switch).
Nothing outside Windows has changed yet; undoing this step is extending `C:`
again in Disk Management.

### 2. Boot the installer and connect from the Mac

1. Boot the stick through the ASRock boot menu (F11) and pick its UEFI entry.
2. At the console (US layout until `sudo loadkeys de`): connect Wi-Fi with
   `nmtui`, set a temporary password with `passwd`, and read the address from
   `ip -4 addr`.
3. From the Mac, `ssh nixos@<address>` and `sudo -i`. Paste the remaining
   commands there. If `ssh` reports `No route to host` while `ping` works, allow
   the terminal app under macOS Privacy & Security > Local Network
   ([observed 2026-11-13](https://github.com/maurerf/nixos/issues/45#issuecomment-6859354376)). The installer has `sshd`, NetworkManager, `git`, `sgdisk`,
   `efibootmgr` and btrfs tools on board.

**Checkpoint 2:** identify the disk and the gap before creating anything.

```sh
lsblk -d -o NAME,MODEL,SIZE
DISK=/dev/nvme0n1    # the Samsung 970 EVO from the line above
lsblk -o NAME,SIZE,FSTYPE,PARTLABEL,PARTUUID "$DISK"
parted "$DISK" unit MiB print free
```

Expected: ESP (100 MiB, PARTUUID `66b88416-…`), MSR, the NTFS `C:` partition,
then about 204800 MiB of free space, then the Recovery partition. No existing
partition is labelled `BOOT` or `nixos`. Only small alignment gaps besides the
big one.

### 3. Partition, format and mount

`sgdisk` with start `0` uses the largest free block, which is the gap.

```sh
sgdisk -n 0:0:+1G -t 0:ea00 -c 0:BOOT "$DISK"
sgdisk -n 0:0:0 -t 0:8300 -c 0:nixos "$DISK"
partprobe "$DISK"; udevadm settle
lsblk -o NAME,SIZE,PARTLABEL "$DISK"    # BOOT 1G and nixos about 199G, Windows partitions unchanged

mkfs.fat -F 32 -n BOOT /dev/disk/by-partlabel/BOOT
mkfs.btrfs -L nixos /dev/disk/by-partlabel/nixos
udevadm settle

mount /dev/disk/by-label/nixos /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
umount /mnt
```

The mounts below are also the first step of every rescue from the stick:

```sh
O=compress=zstd,noatime
mount -o subvol=@,$O /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/home /mnt/nix /mnt/boot /mnt/efi
mount -o subvol=@home,$O /dev/disk/by-label/nixos /mnt/home
mount -o subvol=@nix,$O /dev/disk/by-label/nixos /mnt/nix
mount -o fmask=0077,dmask=0077 /dev/disk/by-label/BOOT /mnt/boot
mount -o fmask=0077,dmask=0077 /dev/disk/by-partuuid/66b88416-5d45-4cf6-8cf4-3c9a4523fc79 /mnt/efi
```

**Checkpoint 3:** before anything is written to the ESP.

```sh
findmnt -R /mnt          # /, /home, /nix (btrfs subvolumes), /boot and /efi (vfat)
ls /mnt/efi/EFI          # Microsoft and Boot; no systemd directory
df -h /mnt/efi           # about 60 MB free
nixos-generate-config --root /mnt --show-hardware-config
```

The last command only prints. Compare its `availableKernelModules` with
`hardware/desktop-pc.nix`: if a module needed to reach the disk (`nvme`) is
missing from the file, fix it in the clone below before installing. Note any
other difference and fix it by PR after the first boot.

### 4. Install

Remove the stale firmware entries (one `Manjaro` and seven `Linux Boot Manager`
[observed 2026-11-10](https://github.com/maurerf/nixos/issues/27)), whose files
are absent from the ESP as checkpoint 3 showed. Never delete
`Windows Boot Manager` or the stick's own entry.

```sh
efibootmgr                 # list
efibootmgr -b 0003 -B      # repeat with each stale entry's number
```

Place the checkout, the login password hash and the Wi-Fi connection, then
install. The checkout lives in `~/Documents/git/nixos` on `desktop-pc` (the first
run used `~/git/nixos`; moved 2026-11-13). Copying the connection lets the installed system join Wi-Fi at first
boot, so SSH from the Mac works even if the desktop does not.

```sh
git clone https://github.com/maurerf/nixos /mnt/home/fdm/Documents/git/nixos
git -C /mnt/home/fdm/Documents/git/nixos checkout --detach "$CANDIDATE"

install -d -m 700 /mnt/etc/checkup-secrets
mkpasswd -m yescrypt > /mnt/etc/checkup-secrets/fdm-login.hash   # or: nix-shell -p mkpasswd --run 'mkpasswd -m yescrypt'
chmod 600 /mnt/etc/checkup-secrets/fdm-login.hash
grep -c '^\$y\$' /mnt/etc/checkup-secrets/fdm-login.hash          # 1

install -d -m 700 /mnt/etc/NetworkManager/system-connections
cp -p /etc/NetworkManager/system-connections/*.nmconnection /mnt/etc/NetworkManager/system-connections/

nixos-install --root /mnt --flake /mnt/home/fdm/Documents/git/nixos#desktop-pc --no-root-passwd --no-update-lock-file --no-write-lock-file
nixos-enter --root /mnt -c 'chown -R fdm:users /home/fdm'
```

Root stays locked; `fdm` with `sudo` is the way in, and the Mac's SSH key is
declared in `machines/desktop-pc.nix`. Unfree packages such as the NVIDIA driver
and Steam may build locally instead of coming from the binary cache, so the
install can take a while. In the first run (2026-11-11) the kernel and the NVIDIA
open module came from the cache; only small derivations such as `nvidia-x11` and
`nvidia-settings` built locally, beside a 4.6 GiB download over Wi-Fi ([observation](https://github.com/maurerf/nixos/issues/45#issuecomment-6859354376)). The hash
file is read only when `fdm` is first created; later password changes go through
`passwd`.

Check the result, then restart without the stick:

```sh
ls /mnt/efi/EFI                 # Microsoft, Boot and now systemd
cat /mnt/efi/loader/loader.conf # timeout 5, default nixos-generation-1.conf, editor off
ls /mnt/boot/EFI/nixos          # kernel and initrd
efibootmgr                      # Linux Boot Manager first, Windows Boot Manager present
umount -R /mnt && reboot
```

`bootctl install` also replaces the fallback loader `EFI/BOOT/BOOTX64.EFI` on
the ESP; the original is in the ESP copy of the backup. Its log reports
`Created directory "/efi/EFI"` and `"/efi/EFI/BOOT"` although both exist; FAT
ignores case, and the Windows files stayed intact in the first run
([observation](https://github.com/maurerf/nixos/issues/45#issuecomment-6859354376)).

### 5. First boot

The systemd-boot menu lists NixOS and Windows Boot Manager. Do not press `d` in
the menu and do not run `bootctl set-default`: either pins a default that
overrides `loader.conf`. Log in as `fdm` at tuigreet, remove the old host key on
the Mac (`ssh-keygen -R <address>`) and check `ssh fdm@<address>`. Then follow
[desktop-pc first login](#desktop-pc-first-login) and the
[install acceptance checks](https://github.com/maurerf/nixos/issues/44). Reach
Windows from the menu or with
`systemctl reboot --boot-loader-entry=auto-windows`. Pushing from the checkout
needs a GitHub login, set up after acceptance.

### Recovery

These are the stop-and-recover routes of the acceptance criteria; every other
failed check is fixed forward by PR and `nixos-rebuild` on the running system.

- **The machine boots straight into Windows** (also after a Windows update put
  itself first): pick Linux Boot Manager in the F11 menu, then restore the order
  from NixOS with `sudo efibootmgr -o <linux>,<windows>`.
- **NixOS reaches no login:** try a text console (Ctrl+Alt+F2) and SSH from the
  Mac first. Otherwise boot the stick, repeat the mounts of step 3 (never the
  `sgdisk` or `mkfs` commands), correct the checkout and run the `nixos-install`
  line again; it adds a generation and keeps `/home`. An older generation can be
  picked in the boot menu once one exists.
- **The login is rejected:** from the stick, after the mounts,
  `nixos-enter --root /mnt -c 'passwd fdm'`.
- **Windows does not start from the menu:** pick Windows Boot Manager in the F11
  menu, which bypasses systemd-boot. If the firmware entry is gone, recreate it
  from the stick: `efibootmgr -c -d "$DISK" -p 1 -L "Windows Boot Manager" -l '\EFI\Microsoft\Boot\bootmgfw.efi'`.
  If files on the ESP are damaged, mount it from the stick and copy them back
  from the ESP copy of the backup (fetch it on the Mac, then `scp` to the
  installer). If Windows itself is damaged, let its recovery environment run
  Startup Repair; a clean reinstall from the backup is the
  [accepted worst case](https://github.com/maurerf/nixos/issues/42).

### Back out

To remove NixOS again, from the stick with only the ESP mounted:

```sh
mount /dev/disk/by-partuuid/66b88416-5d45-4cf6-8cf4-3c9a4523fc79 /mnt
rm -r /mnt/EFI/systemd /mnt/loader
umount /mnt
efibootmgr                           # then -b <number> -B for Linux Boot Manager
lsblk -o NAME,PARTLABEL "$DISK"      # read the numbers of BOOT and nixos
sgdisk -d <nixos number> -d <BOOT number> "$DISK"
```

Then boot Windows, extend `C:` into the free space in Disk Management, and
restore `EFI\BOOT\BOOTX64.EFI` from the ESP copy if wanted. `powercfg /h on` and
deleting `RealTimeIsUniversal` return Windows to its earlier settings.

## Manual tools

Claude Code and the Codex CLI are installed by hand on each Workstation, not by
Nix ([decision](decisions.md)). Their official installers put them in
`~/.local/bin` and keep them updated; the Workstation module adds that directory
to `PATH`. Installers fetched 2026-11-10:

```sh
curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

Install Claude Code before a rebuild that removes a Nix copy, and check
`~/.local/bin/claude --version` and the existing login. Before installing Codex,
remove any Homebrew or npm `codex`, which its installer treats as a conflict.
After the rebuild, in a fresh shell, `which -a claude` and `which -a codex` must
each resolve to a single `~/.local/bin` copy; delete other script-installed copies.
On NixOS the binaries need `programs.nix-ld` enabled before the installers run;
see the [research notes](https://github.com/maurerf/nixos/issues/33). Nix does own
Claude's status-line setting; see [decisions](decisions.md).

### desktop-pc first login

Rehearsed in the [VM dry run](https://github.com/maurerf/nixos/issues/36)
(2026-11-10, Claude Code 2.1.322, Codex 0.167.0). After the first login at
tuigreet, in Ghostty:

1. Run both installers above; the Codex installer must not try to write
   `~/.zshrc`, which stays the Home Manager link (`readlink -f ~/.zshrc`).
2. In a new Ghostty window, `which -a claude codex` lists only the
   `~/.local/bin` copies, and `claude --version` and `codex --version` answer.
3. `ldd ~/.local/bin/claude` resolves `/lib64/ld-linux-x86-64.so.2` into the
   Nix store (`nix-ld`); `ldd` on the Codex binary reports it statically linked.
4. Log in to Claude Code and have it make one Bash tool call; the host has no
   `/bin/bash`, and the tool runs through the login shell instead.
5. On bare metal, the MX Master 3S runs on its USB receiver and needs no
   pairing. Click Bluetooth in Waybar to open `bluetui` in a floating Ghostty
   window. For AirPods, open the case and enter pairing mode (flashing white),
   ensure `bluetui` is scanning (`s` toggles scanning), use Tab to select the scanning pane, then
   select the AirPods and press Enter to pair/connect. Use `t` to trust them
   for subsequent connections. `bluetoothctl` is the fallback: `scan on`,
   `pair <address>`, `trust <address>`, `connect <address>`, then `scan off`.
   Discovery, bonding and connection with the default dual-mode BlueZ settings
   were observed on 2026-11-13 ([AirPods discovery and bar launcher](https://github.com/maurerf/nixos/issues/57));
   no controller-mode, privacy or WirePlumber overrides were needed.
   After switching from Windows, re-pair if the other OS replaced the link key
   ([Bluetooth limitations](https://github.com/maurerf/nixos/issues/26)).

There is no Dock to set up; apps start from fuzzel (Super+Space). Super+F1 shows
Niri's hotkey overlay and Super+Shift+Space searches and runs any bind.

### desktop-pc edit keys

After the edit-key remap ([decision](decisions.md)) is first activated, log out
with no other session open (SSH, TTY), wait at least 15 seconds at tuigreet, then
log back in (or reboot). xremap takes its groups from the systemd user manager,
which outlives a quick re-login (`UserStopDelaySec`, 10 s by default) and would
keep the old groups. `grep Groups /proc/$(systemctl --user show xremap -p MainPID
--value)/status` must include the `input` and `uinput` ids, and the service log
must list the keyboards, not "No input devices". Then `xremap --list-windows`
must list Niri windows, and `Super+C/V` must copy and paste in Firefox. Ghostty
handles its own `Super+C/V`, so it passing proves nothing about xremap; check
there that `Ctrl+C` still interrupts.

First activation on 2026-11-14 ([edit-key PR](https://github.com/maurerf/nixos/pull/83),
commit `d461478`): an immediate re-login left xremap without `input` and
`uinput`; Ghostty worked but `Super+C/V` did nothing in Firefox. After a
15-second wait the groups applied, and the user confirmed every key check. `xremap --list-windows`
listed Niri windows even though xremap 0.15.7 is built against niri-ipc 25.11
and Niri is 26.04 ([research](https://github.com/maurerf/nixos/issues/59)).
