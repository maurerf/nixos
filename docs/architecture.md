# Architecture

[Knowledge index](README.md)

[flake.nix](../flake.nix) composes the hosts; [flake.lock](../flake.lock) pins the
inputs. Read those files for exact release branches and revisions. Home Manager,
nix-darwin and simple-nixos-mailserver follow the shared nixpkgs input.

| Host | Configuration relationship |
| --- | --- |
| `m2-macbook-air`, aarch64-darwin | [machine](../machines/m2-macbook-air.nix) + Home Manager [profile](../profiles/home-darwin.nix); nix-darwin owns system activation |
| `vps`, x86_64-linux | [machine](../machines/vps.nix) imports [Linux base](../modules/nixos-base.nix); flake adds [hardware](../hardware/vultr-vps.nix), mailserver and Home Manager [profile](../profiles/home-vps.nix) |

Both profiles import shared [Git](../modules/git.nix) and [Zsh](../modules/zsh.nix)
settings. Change one host's packages in its profile; shared modules can affect both.
Do not import the Linux base into Darwin. The Mac integrates Homebrew without
managing its manually installed packages; application ownership matters when
checking launches or contemplating removal.

Home Manager copies apps from the Mac user's `home.packages` into
`~/Applications/Home Manager Apps` for Spotlight discovery. Its activation syncs
that directory from the current Nix packages on every rebuild. Older
`~/Applications/Home Manager Trampolines` applets came from a former Home Manager
activation mechanism and are not maintained by this configuration; check their
embedded destinations before using or retiring them.

The VPS exists to serve mail. The mailserver module supplies the mail stack;
nginx serves ACME HTTP challenges for the mail hostname. Explicit Postfix outbound
IPv4 overrides preserve inbound IPv6 while avoiding the historical sender-identity
failure; see [decisions](decisions.md). A listening port is not automatically a
public service requirement. Runtime credentials are absolute host-file references,
not Nix store contents; see [secret recovery](vps-recovery.md#runtime-secrets).

Both outputs use `self.rev or null` for configuration revision. A clean committed
candidate is needed for meaningful deployment provenance; Git HEAD alone does not
prove what runs. Compare host revision and active/selected paths as described in
[deployment](deployment.md). Hardware declarations likewise do not prove a working
bootloader or recovery route.
