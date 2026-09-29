# Architecture

[Knowledge index](README.md)

[flake.nix](../flake.nix) composes the hosts; [flake.lock](../flake.lock) pins the
inputs. Read those files for exact release branches and revisions. Home Manager,
nix-darwin and simple-nixos-mailserver follow the shared nixpkgs input.

| Host | Configuration relationship |
| --- | --- |
| `m2-macbook-air`, aarch64-darwin | [machine](../machines/m2-macbook-air.nix) + Home Manager [profile](../profiles/home-darwin.nix); nix-darwin owns system activation |
| `vps`, x86_64-linux | [machine](../machines/vps.nix) imports [Linux base](../modules/nixos-base.nix) and [Fredy](../modules/fredy.nix); flake adds [hardware](../hardware/vultr-vps.nix), mailserver and Home Manager [profile](../profiles/home-vps.nix) |
| `vps-fredy-bootstrap`, x86_64-linux | Same VPS configuration with external Fredy requests denied during first login; see [Fredy operations](fredy.md#first-login-and-public-switch). |

Both profiles import shared [Git](../modules/git.nix) and [Zsh](../modules/zsh.nix)
settings. Change one host's packages in its profile; shared modules can affect both.
Do not import the Linux base into Darwin. The Mac integrates Homebrew without
managing its manually installed packages; application ownership matters when
checking launches or contemplating removal.

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

Both outputs use `self.rev or null` for configuration revision. A clean committed
candidate is needed for meaningful deployment provenance; Git HEAD alone does not
prove what runs. Compare host revision and active/selected paths as described in
[deployment](deployment.md). Hardware declarations likewise do not prove a working
bootloader or recovery route.
