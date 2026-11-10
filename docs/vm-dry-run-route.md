# VM dry-run route on Windows 11 Home

[Knowledge index](README.md) · [Architecture](architecture.md) · [Deployment](deployment.md)

Research for [issue #22](https://github.com/maurerf/nixos/issues/22), part of the
[`desktop-pc` map](https://github.com/maurerf/nixos/issues/21). Researched
2026-11-10 by reading primary sources only. **Nothing was installed or run**; the
recommended route is therefore sourced but untested on this machine. Claims are
marked *sourced* (stated by the linked source), *observed* (read from this
machine) or *inferred* (reasoning that the dry run must confirm).

## Answer

Use **NixOS-WSL on WSL2**, build the VM with
`nix build .#nixosConfigurations.desktop-pc.config.system.build.vm` (the flake
form of `nixos-rebuild build-vm`), and run the resulting QEMU script with **nested
KVM** and a **virtio-gpu device backed by virglrenderer**, displayed as a WSLg
window.

The deciding constraint is Niri, not Windows: Niri has no software renderer and
its maintainers require 3D acceleration in a VM. QEMU's default display adapter,
which `build-vm` uses on x86, will not show a Niri session. The VM variant must
add a GL-capable virtio-gpu device explicitly.

The one unverified link is whether QEMU's OpenGL display works through WSLg. A
fallback ladder is given under [Open uncertainties](#open-uncertainties).

## Key facts

### Windows and WSL2

- *Sourced:* WSL2 is available on Windows 11 Home. It needs two optional
  features, "Virtual Machine Platform" (a subset of Hyper-V) and "Windows
  Subsystem for Linux"
  ([WSL FAQ](https://learn.microsoft.com/en-us/windows/wsl/faq)).
- *Sourced:* `wsl --install` from an administrator PowerShell enables the needed
  features and installs Ubuntu by default; a restart is required
  ([Install WSL](https://learn.microsoft.com/en-us/windows/wsl/install)).
- *Sourced:* The full Hyper-V role (Hyper-V Manager) cannot be installed on
  Windows 11 Home
  ([Install Hyper-V](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/install-hyper-v)).
  A Hyper-V-managed VM is not an option here.
- *Sourced:* `nestedVirtualization` in `%UserProfile%\.wslconfig` defaults to
  `true` and is Windows 11 only. `memory` defaults to 50% of host RAM (8 GB
  here), `processors` to all logical processors, `guiApplications` (WSLg) to
  `true`
  ([WSL advanced settings](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)).
  No `.wslconfig` edit is required to get nested KVM.
- *Observed 2026-11-10 (read-only CIM query):* Windows 11 Home build 26200;
  `Win32_ComputerSystem.HypervisorPresent = True`;
  `Win32_Processor.VirtualizationFirmwareEnabled = False`.
- *Inferred:* a running hypervisor means VT-x is already enabled in firmware, and
  the `False` firmware flag is the usual masking of CPU virtualization flags once
  Windows itself runs under its hypervisor. If `wsl --install` reports that
  virtualization is disabled, enable Intel VT-x in the UEFI setup. Confirm inside
  WSL with `ls -l /dev/kvm`.

### NixOS-WSL versus Nix on another distro

- *Sourced:* NixOS-WSL installs from a `nixos.wsl` release file with
  `wsl --install --from-file nixos.wsl` (WSL 2.4.4 or later). The default user is
  `nixos`; run `sudo nix-channel --update` once before `nixos-rebuild`
  ([NixOS-WSL install](https://nix-community.github.io/NixOS-WSL/install.html)).
- *Sourced:* The NixOS-WSL module sets `hardware.graphics.enable = true`, and
  offers `wsl.useWindowsDriver` to link the Windows host GPU libraries
  ([`modules/wsl-distro.nix`](https://github.com/nix-community/NixOS-WSL/blob/main/modules/wsl-distro.nix)).
  nixpkgs Mesa builds the `d3d12` ("WSL emulated GPU"), `llvmpipe` and `virgl`
  Gallium drivers
  ([nixpkgs Mesa, 26.05](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/development/libraries/mesa/default.nix)).
- *Sourced:* A NixOS-WSL maintainer states the project aims to support anything
  that works on bare-metal NixOS, including KVM for VM tests, and that it is
  slower than bare metal because it is a VM inside a VM
  ([NixOS-WSL #309](https://github.com/nix-community/NixOS-WSL/issues/309)).
- *Inferred:* NixOS-WSL is the better choice. QEMU from nixpkgs needs host OpenGL
  drivers for virglrenderer; NixOS provides them at the path Nix-built programs
  expect, whereas Nix on Ubuntu does not without a wrapper such as
  [nixGL](https://github.com/nix-community/nixGL). Nix on Ubuntu remains fine for
  evaluation and building only.

### Building and running the VM

- *Sourced:* `nixos-rebuild build-vm` builds a QEMU VM script,
  `./result/bin/run-*-vm`. The VM has no host data; state lives in
  `$hostname.qcow2` in the working directory, which must be deleted when user
  settings change
  ([NixOS manual source, 26.05](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/doc/manual/installation/changing-config.chapter.md)).
- *Sourced:* VM-only settings go in `virtualisation.vmVariant`, and the script is
  also exposed as `config.system.build.vm`
  ([`build-vm.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/virtualisation/build-vm.nix)).
  This keeps the throwaway password and QEMU options out of the real host.
- *Sourced* ([`qemu-vm.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/virtualisation/qemu-vm.nix),
  [`qemu-common.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/lib/qemu-common.nix)):
  - Defaults are `memorySize = 1024` MiB, `cores = 1`, `resolution` 1024x768,
    `graphics = true`. A desktop needs these raised.
  - The script runs `qemu-system-x86_64 -machine accel=kvm:tcg -cpu max`. Without
    usable `/dev/kvm` it silently falls back to slow TCG emulation.
    `virtualisation.qemu.forceAccel = true` makes it fail instead.
  - On x86 the module adds no display adapter, so QEMU's default VGA is used.
    Extra flags go in `virtualisation.qemu.options`.
  - The host Nix store is mounted into the guest by default, so no disk image of
    the closure is built or copied.
- *Sourced:* nixpkgs QEMU enables GTK, SDL, OpenGL and virglrenderer by default
  ([QEMU package, 26.05](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/qe/qemu/package.nix)).

### Niri in a VM

- *Sourced:* "To run niri in a VM, make sure to enable 3D acceleration"
  ([Niri getting started](https://niri-wm.github.io/niri/Getting-Started.html)).
- *Sourced:* Niri has no software renderer
  ([niri #218](https://github.com/niri-wm/niri/issues/218), open). Maintainers
  repeat that 3D acceleration is mandatory in a VM, and a user reports Niri runs
  with a VirGL display but crashes with plain virtio-gpu, SPICE, VMware and VGA
  adapters ([niri #3501](https://github.com/niri-wm/niri/issues/3501)). On a
  Hyper-V VM without GPU acceleration Niri fails to start while Hyprland and
  COSMIC work ([niri #3527](https://github.com/niri-wm/niri/issues/3527)).
- *Sourced:* QEMU's default virtio-gpu is 2D only and leaves 3D to a guest
  software renderer. The `-gl` device variants use the host's virglrenderer to
  translate guest OpenGL to host OpenGL
  ([QEMU virtio-gpu](https://www.qemu.org/docs/master/system/devices/virtio/virtio-gpu.html)).
  The GTK and SDL displays take `gl=on`; `egl-headless` renders on a local device
  and must be paired with VNC or SPICE
  ([QEMU invocation](https://www.qemu.org/docs/master/system/invocation.html)).
- *Sourced:* By default `Mod` is `Super` when Niri runs on a TTY; `mod-key` can
  change it since Niri 25.05
  ([Niri input configuration](https://niri-wm.github.io/niri/Configuration%3A-Input.html)).
- *Inferred:* Windows intercepts many `Win`-key shortcuts before the QEMU window
  sees them, so the VM variant should set `mod-key "Alt"`.
- *Sourced:* A mismatch between the system Mesa and the Mesa Niri was built
  against gives a black screen on NixOS (same getting-started page). Take Niri
  from the same nixpkgs as the system.

### WSLg

- *Sourced:* WSLg runs a Weston compositor in a system distro and exposes
  `DISPLAY` and `WAYLAND_DISPLAY` to the user distro; windows are remoted to
  Windows over RDP. Accelerated OpenGL comes from Mesa's `d3d12` driver; an
  up-to-date vendor GPU driver on Windows is recommended
  ([WSLg README](https://github.com/microsoft/wslg)).
- *Sourced:* Running Niri itself as a nested window under WSLg is a poor
  experience, with an unresolved crash on resize
  ([niri #2415](https://github.com/niri-wm/niri/issues/2415)). It would also skip
  the greeter and boot path. Not a substitute for the VM.

## Routes compared

| Route | Enable on Windows | Niri renders? | Assessment |
| --- | --- | --- | --- |
| **A. NixOS-WSL, `build-vm`, nested KVM, virgl, WSLg window** | WSL2 only | Expected yes with `virtio-vga-gl`; no with the default adapter | **Recommended.** One tool, fast iteration, shared Nix store, matches the map's standing decision. GL display through WSLg is untested. |
| B. Build a VirtualBox image in WSL2, boot it in VirtualBox on Windows | WSL2, VirtualBox, Windows Hypervisor Platform | Plausible: a Niri maintainer reports users running Niri in VirtualBox (niri #3501) | Fallback. Needs VirtualBox 3D acceleration and guest additions. With Hyper-V active VirtualBox uses it as the engine and warns of "significant performance degradation" ([VirtualBox manual](https://www.virtualbox.org/manual/topics/AdvancedTopics.html)). Every change needs a full image build (`virtualbox` variant in [`images.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/image/images.nix)) and re-import. |
| C. Build a QEMU image in WSL2, boot it in QEMU for Windows with WHPX | WSL2, QEMU, Windows Hypervisor Platform | Unknown | Not recommended. WHPX itself is documented ([QEMU WHPX](https://www.qemu.org/docs/master/system/whpx.html)), but no primary source was found for virglrenderer in Windows QEMU builds, and without it Niri cannot render. |
| D. Hyper-V Manager VM | Not possible on Home | No (niri #3527) | Excluded. |
| E. Nix on Ubuntu in WSL2 instead of NixOS-WSL | WSL2 only | Same as A if host GL is wired up | Works for building; running QEMU with GL needs extra GL plumbing. Prefer NixOS-WSL. |

## Recommended setup

Steps 1 to 3 change Windows and need the user's approval when the dry run is
executed. Nothing here was run.

1. **Install WSL2.** In an administrator PowerShell: `wsl --install --no-distribution`
   ([WSL commands](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)), then restart. Run `wsl --update` and
   check `wsl --version` is 2.4.4 or later.
2. **Install NixOS-WSL.** Download `nixos.wsl` from the
   [latest release](https://github.com/nix-community/NixOS-WSL/releases/latest),
   then `wsl --install --from-file nixos.wsl`, `wsl -d NixOS`, and
   `sudo nix-channel --update`.
3. **Optional `.wslconfig`.** Defaults already give nested virtualization and
   WSLg. With 16 GB host RAM, consider `memory=10GB` under `[wsl2]` so a 4 GB
   guest and the build fit; apply with `wsl --shutdown`.
4. **Prepare the WSL distro** in `/etc/nixos/configuration.nix`, then
   `sudo nixos-rebuild switch`:
   - `nix.settings.experimental-features = [ "nix-command" "flakes" ];`
   - `users.users.nixos.extraGroups = [ "kvm" ];`
   - `environment.systemPackages = [ pkgs.git ];`
   - optionally `wsl.useWindowsDriver = true;` for GPU-backed host OpenGL.

   Restart the distro (`wsl --terminate NixOS`) and check `ls -l /dev/kvm` shows
   the device as readable and writable for the user.
5. **Clone the repository inside the WSL filesystem** (for example `~/nixos`),
   not under `/mnt/c`.
6. **Give `desktop-pc` a VM variant** (owned by the host-configuration ticket).
   A starting point, untested:

   ```nix
   virtualisation.vmVariant = {
     virtualisation = {
       memorySize = 4096;
       cores = 4;
       qemu.forceAccel = true;
       qemu.options = [
         "-vga none"
         "-device virtio-vga-gl"
         "-display gtk,gl=on"
       ];
     };
     # plus: throwaway password, Niri `mod-key "Alt"`, and no NVIDIA driver
   };
   ```

   The guest has a virtio GPU, so the NVIDIA driver settings of the real host
   must not apply inside the VM variant.
7. **Build and run:**

   ```sh
   nix build .#nixosConfigurations.desktop-pc.config.system.build.vm
   ./result/bin/run-desktop-pc-vm
   ```

   A QEMU window should appear on the Windows desktop through WSLg. Delete
   `desktop-pc.qcow2` between runs when user or password settings change.

## Open uncertainties

1. **QEMU OpenGL display through WSLg is untested.** No primary source confirms
   `-display gtk,gl=on` with virglrenderer under WSLg. If it fails, try in order:
   `-display sdl,gl=on`; host software GL for QEMU only
   (`LIBGL_ALWAYS_SOFTWARE=1 ./result/bin/run-desktop-pc-vm`, virgl on llvmpipe,
   slower but still gives the guest a 3D device); `wsl.useWindowsDriver` toggled
   the other way; `-display egl-headless` with `-vnc` and a VNC viewer on
   Windows; finally route B.
2. **`/dev/kvm` access in NixOS-WSL.** No primary source states which group owns
   `/dev/kvm` under NixOS-WSL or whether NixOS's `kvm` group matches it; an
   unattributed search snippet claimed a group-ID mismatch. `forceAccel` makes a
   permission problem visible instead of silently slow. Check `ls -l /dev/kvm`
   first; a per-boot `chown`/`chmod` of the device is the likely workaround.
3. **Nested guest hang under the Windows hypervisor.** An open nixpkgs issue
   reports that a KVM guest nested under Hyper-V hangs at boot when the Linux
   host running KVM uses kernel 6.18 or later, with kernel 6.12 unaffected
   ([nixpkgs #571838](https://github.com/NixOS/nixpkgs/issues/571838); reported
   on a 10th-generation Intel CPU in the linked
   [Discourse thread](https://discourse.nixos.org/t/issue-running-nixostest-in-nested-virtualization-case-on-hyper-v/80358)).
   Under WSL2 that host kernel is Microsoft's WSL kernel, not NixOS's, so whether
   it applies depends on the installed WSL kernel version (`uname -r`). The
   reporter's workaround is
   `QEMU_OPTS="-cpu max,-kvmclock" QEMU_KERNEL_PARAMS="lapic=notscdeadline"`,
   both of which the `build-vm` script honours.
4. **Firmware VT-x state is inferred**, not read from the firmware. `wsl --install`
   succeeding and `/dev/kvm` existing confirm it.
5. **Performance.** Nested KVM plus virgl plus RDP remoting will be slow. This
   route proves "builds and boots to a usable desktop"; it says nothing about
   gaming, NVIDIA, VRR or 4K at 120 Hz, which the map already scopes to bare
   metal.
6. **Whether Niri would run on guest llvmpipe with plain virtio-gpu** was not
   tested; upstream statements and reports say no, so the route does not rely on
   it.
7. **Display manager or greeter** behaviour on virtio-gpu depends on the session
   decision in another ticket and was not researched here.
8. **NordVPN on Windows** may interfere with WSL networking (the WSL FAQ lists
   firewall products that block WSL traffic; NordVPN is not among them). Not
   researched further.
