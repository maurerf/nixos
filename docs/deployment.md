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

PR CI evaluates both outputs and checks the flake; it does not replace native builds.
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

## VPS acceptance

Before and after activation, verify the candidate/baseline revision with
`nixos-version --configuration-revision`; compare `/run/current-system`,
`/nix/var/nix/profiles/system` and, after reboot, `/run/booted-system` to expected
closures. During `test`, the old selected/booted paths are expected to differ.
Check zero failed units, required services, queue depth, free space/inodes, intended
listeners and host/provider firewall rules. The 2026-09-28 service names were
`postfix dovecot rspamd nginx sshd redis-rspamd kresd@1`; verify actual names for
the candidate rather than assuming them forever.

Use an independent external client for SSH, TCP reachability and mail checks:

- Intended public ports: 22, 25, 80, 465, 993. Keep 443 and quota-status 12340
  nonpublic unless a new requirement justifies a change.
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
complete on service status alone. Source: [dated service/mail checks](archive/01-checkup/EVIDENCE.md#us-06-next-day-stability-checkpoint-2026-09-29t085934z)
and preceding US-06 evidence, not a fresh runtime inspection.

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
