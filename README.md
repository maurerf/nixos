# Nix systems

This flake defines `m2-macbook-air` (aarch64-darwin) and `vps` (x86_64-linux).
Both record the clean source commit as their configuration revision. The full
source revision of the historical deployed generations is unknown.

## Layout

- `flake.nix` and `flake.lock`: outputs and pinned inputs.
- `machines/`: host settings; `hardware/vultr-vps.nix`: VPS hardware settings.
- `profiles/home-darwin.nix` and `profiles/home-vps.nix`: Home Manager profiles.
- `modules/`: Git/Zsh settings and Linux-only `nixos-base.nix`.
- `docs/goals/01-checkup/`: deployment gates, evidence and rollback procedures.

## Update and validate

Work from a clean checkout. Update only the intended input, such as
`nix flake update nixpkgs`, and review the resulting lockfile diff.

```sh
nix eval --raw .#darwinConfigurations.m2-macbook-air.system.drvPath --no-update-lock-file --no-write-lock-file
nix eval --raw .#nixosConfigurations.vps.config.system.build.toplevel.drvPath --no-update-lock-file --no-write-lock-file
nix flake check --no-build --all-systems --no-update-lock-file --no-write-lock-file
git diff --check
```

Build each output on its native host from the same approved clean commit. PR
CI evaluates both outputs but does not replace a native build.

```sh
# Mac
darwin-rebuild build --flake .#m2-macbook-air --no-update-lock-file --no-write-lock-file
# VPS
nixos-rebuild build --flake .#vps --no-update-lock-file --no-write-lock-file
```

Record `realpath result`, then on each host compare the new closure with the
pre-change `realpath /run/current-system`:

```sh
nix store diff-closures "$OLD" "$NEW"
nix path-info --closure-size "$OLD" "$NEW"
```

Review service removals, version jumps, size and state formats. The VPS needs
the tested backup, console, secret and reconciliation gates in the checkup
stories before activation.

## Runtime credentials

The VPS uses `/etc/checkup-secrets/fdm-login.hash` for Linux login and
`/etc/checkup-secrets/mail-felix.hash` for mail. These protected host files
must never enter Git or the Nix store. The operator creates them privately
after backup and console gates, following the [US-02 provisioning and recovery
procedure](docs/goals/01-checkup/EVIDENCE.md#us-02-runtime-secret-procedure).
Old Git history and store paths may still expose prior credentials; removing
values from HEAD does not revoke them.

## Activate and recover

After the matching native build, reviewed diff and host-specific gates:

```sh
# Mac, in its own deployment window
sudo darwin-rebuild switch --flake .#m2-macbook-air --no-update-lock-file --no-write-lock-file
# VPS, in a later window: follow the reviewed story-specific activation route
sudo nixos-rebuild test --flake .#vps --no-update-lock-file --no-write-lock-file
sudo nixos-rebuild switch --flake .#vps --no-update-lock-file --no-write-lock-file
```

Keep a second SSH session and the Vultr console open for VPS activation.
Check version revision, active/selected paths, services, SSH and external mail
after each step as specified in US-04 and US-06. The 2026-09-28 VPS migration
used an explicitly approved `boot` and reboot route after `test` returned exit
4 during the D-Bus transition; see the [recorded exception and postboot
checks](docs/goals/01-checkup/EVIDENCE.md#us-06-boot-route-assessment-no-boot-action-2026-09-28t201331z201416z).
Do not treat that failed `test` as a general reason to select a new boot
generation. `test` can write mail state. If acceptance fails, use the exact
previously verified recovery procedures.
Mac: `sudo darwin-rebuild --switch-generation "$MAC_OLD_GEN"`. VPS after
`test`, only when state remains compatible:
`sudo "$VPS_OLD/bin/switch-to-configuration" test`. After `switch`, select
the recorded old generation and run its `switch-to-configuration switch`.
Incompatible mail state requires a reviewed restore and message reconciliation;
a generation rollback alone is insufficient. The current Vultr snapshot has
not been restore-tested, and its recovery duration and post-snapshot mail-loss
risk are [explicitly accepted](docs/goals/01-checkup/EVIDENCE.md#us-05-snapshot-based-recovery-readiness-2026-09-27),
not demonstrated away.
