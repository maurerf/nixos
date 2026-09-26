# Repository Guidelines

## Project Structure & Module Organization

This repository manages personal NixOS and nix-darwin systems through a Nix flake.

- `flake.nix` declares inputs and the `vps` (`x86_64-linux`) and `m2-macbook-air` (`aarch64-darwin`) configurations; `flake.lock` pins dependencies.
- `machines/` contains host-specific system settings and services.
- `hardware/vultr-vps.nix` contains VPS hardware configuration.
- `profiles/home-vps.nix` and `profiles/home-darwin.nix` define platform-specific Home Manager packages and settings.
- `modules/` contains shared Git and Zsh configuration plus the Linux-only `nixos-base.nix` module.

There are no separate application sources, assets, or test directories. Keep reusable settings in modules and host-specific settings in machines or profiles.

## Build, Test, and Development Commands

Run commands from the repository root with Nix flakes enabled:

- `nix flake check`: perform flake validation; this is not a substitute for building the affected host.
- `nix build .#nixosConfigurations.vps.config.system.build.toplevel`: build the VPS system without activating it.
- `nix build .#darwinConfigurations.m2-macbook-air.system`: build the macOS system without activating it.
- `sudo nixos-rebuild switch --flake .#vps`: apply the local configuration on the VPS.
- `sudo darwin-rebuild switch --flake .#m2-macbook-air`: apply the local configuration on the Mac.
- `nix flake update`: update dependency pins; review the resulting lockfile diff.

Build on the matching platform or use a compatible remote builder. Activate only on the intended host after reviewing the build.

## Coding Style & Naming Conventions

Use two-space indentation and existing Nix attribute-set conventions. Use descriptive, lowercase, hyphen-separated filenames such as `home-darwin.nix`. Keep Linux-only modules out of Darwin imports. No formatter or linter is configured; follow surrounding style and avoid unrelated reformatting.

## Testing Guidelines

No dedicated test framework or coverage threshold exists. Validate changes by building the affected configuration. For shared modules, validate both hosts when possible. Report commands run and platform limitations in the pull request.

## Commit & Pull Request Guidelines

Recent commits commonly use `fix:` and `chore:` prefixes, alongside older descriptive subjects. Prefer concise, imperative subjects and focused commits. Pull requests should explain the change, affected hosts, validation results, and any activation or migration steps. Link relevant issues when applicable.

## Configuration Safety

Do not add credentials or private keys. Preserve state-version values unless intentionally performing a documented migration. Review mailserver, SSH, and bootloader changes carefully before activation.

## Planning & Audit Artifacts

Keep each goal directory minimal: default to `PRD.md`, one consolidated `EVIDENCE.md` when evidence retention is required, and a user-facing script only when needed. Keep interview decisions and evidence references in those documents. Do not create separate logs per command, duplicate summaries, file indexes, or standalone one-off collectors.

Keep caches and temporary tooling outside the repository when permitted. If task constraints require temporary files inside the goal directory, remove them before handoff after preserving required evidence. Update links when consolidating. Review the final file list and Git status, preserving unrelated user changes. Ask when artifact requirements are unclear.
