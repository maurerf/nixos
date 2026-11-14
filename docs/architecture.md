# Architecture

[Knowledge index](README.md)

[flake.nix](../flake.nix) composes the hosts; [flake.lock](../flake.lock) pins the
inputs. Read those files for exact release branches and revisions. Home Manager,
nix-darwin and simple-nixos-mailserver follow the shared nixpkgs input.

| Host | Configuration relationship |
| --- | --- |
| `m2-macbook-air`, aarch64-darwin | [machine](../machines/m2-macbook-air.nix) + Home Manager [profile](../profiles/home-darwin.nix), which imports the [Workstation module](../modules/home-workstation.nix); nix-darwin owns system activation |
| `vps`, x86_64-linux | [machine](../machines/vps.nix) imports [Linux base](../modules/nixos-base.nix) and [Fredy](../modules/fredy.nix); flake adds [hardware](../hardware/vultr-vps.nix), mailserver and Home Manager [profile](../profiles/home-vps.nix) |
| `vps-fredy-bootstrap`, x86_64-linux | Same VPS configuration with external Fredy requests denied during first login; see [Fredy operations](fredy.md#first-login-and-public-switch). |
| `desktop-pc`, x86_64-linux | [machine](../machines/desktop-pc.nix) imports the [Linux base](../modules/nixos-base.nix); flake adds hand-written [hardware](../hardware/desktop-pc.nix) and Home Manager [profile](../profiles/home-desktop-pc.nix), which imports the Workstation module. Installed beside Windows 2026-11-11, accepted 2026-11-13 ([run](https://github.com/maurerf/nixos/issues/45)). |

All profiles use shared [Git](../modules/git.nix) and [Zsh](../modules/zsh.nix)
settings: the VPS profile imports them directly, the Workstations through the
Workstation module. The Workstation module is the Home Manager setup for hosts the
user works at (the Mac and `desktop-pc`): the shared apps and fonts, Ghostty with
colours from the [palette](../modules/palette.nix), a fully declarative
[VS Code](../modules/vscode.nix) (read-only settings, only declared extensions)
and `~/.local/bin` on `PATH`.
Each profile keeps its per-OS exceptions, such as Notion, the Ghostty package and
the Darwin app copying on the Mac. Change one host's packages in its profile;
shared modules can affect several hosts. Do not import the Linux base into Darwin. The Mac integrates Homebrew without
managing its manually installed packages; application ownership matters when
checking launches or contemplating removal. Its `PATH` puts `~/.nix-profile/bin` ahead of
Homebrew only from the generated `.zshrc`, after the unmanaged `~/.zprofile` runs
`brew shellenv`; shells that skip `.zshrc` can resolve a command to
`/opt/homebrew/bin` first, so use explicit paths there and check for new
command-name overlaps when adding packages
([PATH cutover](archive/02-homebrew-migration/README.md#path-cutover-activation-2026-10-14)).

The Linux base keeps unfree packages off by default (`lib.mkDefault false`), and each
NixOS machine sets its own `system.stateVersion`; `desktop-pc` alone allows unfree.
`desktop-pc` is a Workstation with a Niri desktop and Steam, dual-booted beside
Windows. System-level parts live in its machine file: the bootloader (systemd-boot
on the Windows ESP at `/efi`, kernels on XBOOTLDR at `/boot`), NVIDIA, Niri started
by greetd + tuigreet, PipeWire, Bluetooth, Steam and `nix-ld` for the self-installed
coding tools. Per-user session parts (Waybar, fuzzel, mako, swaylock, swayidle)
live in its profile; there is no Dock. The Niri configuration is a KDL template in
[`profiles/desktop-pc/`](../profiles/desktop-pc/niri.kdl): the profile fills its
`@placeholders@` (palette colours, polkit agent), appends the binds rendered from
the Nix list in [`binds.nix`](../profiles/desktop-pc/binds.nix) with the modifier
key, and runs `niri validate` at build time. The same list feeds the hotkey-overlay
titles and the fuzzel command palette `niri-bind-palette`. The VM variant
(`config.system.build.vm`) is the same host with its own disk image, no NVIDIA, a
throwaway password, Alt as the Niri modifier and an OpenGL version override for
virgl; it is declared inline in the machine file. The disk layout reasons are in [decisions](decisions.md).

Claude Code and the Codex CLI are deliberately not managed by Nix, so their own
updaters deliver new releases immediately. They are installed manually into
`~/.local/bin`; see [manual tools](deployment.md#manual-tools) and the
[decision](decisions.md). The Workstation module still declares Claude Code's
[status line](../modules/claude-statusline.nix), merging only that key into
`~/.claude/settings.json`.

Home Manager copies apps from the Mac user's `home.packages` into
`~/Applications/Home Manager Apps` for Spotlight discovery. Its activation syncs
that directory from the current Nix packages on every rebuild. Older
`~/Applications/Home Manager Trampolines` applets came from a former Home Manager
activation mechanism and are not maintained by this configuration; check their
embedded destinations before using or retiring them.

The VPS exists to serve mail. The mailserver module supplies the mail stack;
nginx serves ACME HTTP challenges for the mail hostname. The Fredy
service adds a pinned Podman container with `/var/lib/fredy` persistence and a
loopback proxy behind HTTPS at `fredy.maurerf.com`. Its
[staged deployment](fredy.md#first-login-and-public-switch) gates external
access until the initial password is replaced. Explicit Postfix outbound
IPv4 overrides preserve inbound IPv6 while avoiding the historical sender-identity
failure; see [decisions](decisions.md). A listening port is not automatically a
public service requirement. Runtime credentials are absolute host-file references,
not Nix store contents; see [secret recovery](vps-recovery.md#runtime-secrets).

All outputs use `self.rev or null` for configuration revision. A clean committed
candidate is needed for meaningful deployment provenance; Git HEAD alone does not
prove what runs. Compare host revision and active/selected paths as described in
[deployment](deployment.md). Hardware declarations likewise do not prove a working
bootloader or recovery route.
