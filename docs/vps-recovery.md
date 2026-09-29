# VPS recovery and maintenance

[Knowledge index](README.md) · [Deployment and acceptance](deployment.md)

## Maintenance and preparation

The operator owns a full-system Vultr snapshot before each major change. Retain the
existing recovery snapshot until a newer snapshot is verified and the operator
explicitly retires it. On the first of each month check snapshot availability,
independent console login/sudo, free space and mail health; quarterly review whether
an isolated restore rehearsal is feasible. First checks were scheduled for
2026-10-01 and 2026-12-01 respectively; no completion is inferred. Provider automatic
expiry/retention is unknown, so confirm availability rather than assuming retention.
This continuing policy comes from the [2026-09-29 maintenance decision](archive/01-checkup/EVIDENCE.md#legacy-source-investigation-and-maintenance-decision-2026-09-29t090807z091606z).

Before deployment, identify the exact backup, capture time, coverage and consistency,
current console/sudo access, retained generation/closure and free bytes/inodes.
Arrange preservation and reconciliation of mail accepted since capture. An isolated
restore rehearsal is the way to establish actual restore behavior and duration;
if it is unavailable, report the unmet checks and obtain a fresh risk decision.
Do not silently inherit the [historical snapshot waiver](decisions.md#historical-exceptions).
Do not solve capacity pressure by deleting retained recovery material.

The [2026-09-27 inventory](archive/01-checkup/EVIDENCE.md#layer-1--source-backup-console-and-recovery-design)
recorded these persistent paths on the root disk; rediscover actual paths/owners
before a new backup or restore:

| State | Recorded paths |
| --- | --- |
| Mail and delivery queues | `/var/vmail`, `/var/lib/postfix/queue` |
| Sieve and Dovecot | `/var/sieve`, `/var/lib/dovecot` |
| DKIM and ACME | `/var/dkim`, `/var/lib/acme` |
| Rspamd and Redis | `/var/lib/rspamd`, `/var/lib/redis-rspamd` |
| Target credentials | `/etc/checkup-secrets` plus persistent system account state |

`/run/dovecot2/passwd` and `userdb` were regenerated runtime files on tmpfs, not disk
backup contents. The old snapshot predates target secret provisioning. Never put
mail contents, private keys, passwords or hashes in Git, logs or the Nix store.

## Runtime secrets

The declared references are in [Linux users](../modules/nixos-base.nix) and
[mail accounts](../machines/vps.nix). Keep `/etc/checkup-secrets` root:root `0700`,
with `fdm-login.hash` and `mail-felix.hash` root:root `0600`, one nonempty hash line
each. Preserve known passwords for continuity; unknown passwords require an approved
rotation and client update. Old Git/store exposure was not erased by moving secrets;
rotation completion is not established by the archive.

After backup and independent console readiness, an operator can recreate a missing
file using an already available `mkpasswd`, privately and with tracing/recording off.
Run only the needed command; noclobber refuses an existing file. A damaged existing
file needs a deliberate protected replacement decision, not blind truncation.

```sh
sudo install -d -o root -g root -m 0700 /etc/checkup-secrets
sudo sh -c 'umask 077; set -C; mkpasswd -m yescrypt > /etc/checkup-secrets/fdm-login.hash'
sudo sh -c 'umask 077; set -C; mkpasswd -m yescrypt > /etc/checkup-secrets/mail-felix.hash'
sudo chown root:root /etc/checkup-secrets/fdm-login.hash /etc/checkup-secrets/mail-felix.hash
sudo chmod 0600 /etc/checkup-secrets/fdm-login.hash /etc/checkup-secrets/mail-felix.hash
sudo stat -c '%U:%G %a %n' /etc/checkup-secrets /etc/checkup-secrets/fdm-login.hash /etc/checkup-secrets/mail-felix.hash
```

Check command success and privately verify the one-line/nonempty invariant without
printing values. A failed generator can leave an empty file; do not activate on it.
Keep the original SSH session open and verify fresh password SSH plus controlled
IMAPS/submission after the intended activation. Key SSH alone cannot prove password
continuity. Source: [provisioning design](archive/01-checkup/EVIDENCE.md#us-02-runtime-secret-procedure)
and [successful provisioning checkpoint](archive/01-checkup/EVIDENCE.md#operator-authorized-candidate-source-and-renewed-validation).

## Snapshot recovery

The recorded snapshot is `pre-coding-agent`, ID
`9832d1f4-0ee1-4e78-9046-54c8049f4c39`, captured 2026-09-26T08:31:09Z live without
reported quiescence. Availability was last operator-confirmed on 2026-09-29;
restore, consistency and duration were never demonstrated. The provider instance
UUID was not recorded. This is a historical recovery input, not proof of availability now.

Before any destructive restore, bind the exact instance UUID to the intended VPS,
verify the chosen snapshot and current provider instructions, preserve newer mail
where feasible, and obtain explicit approval for target, data-loss risk and action.
The recorded UI route was Products → Compute → selected instance → Snapshots →
selected snapshot → Restore Snapshot; it was researched, not exercised.
See the [dated recovery design](archive/01-checkup/EVIDENCE.md#layer-4--documented-future-recovery-no-activation).

Full-disk restore overwrites newer mailboxes, queues, credentials and closures. No
post-snapshot preservation/import/reconciliation procedure has been tested, and no
measured recovery bound exists. A one-hour outage objective is not a restore guarantee.
Dovecot/Pigeonhole and Rspamd backward state readability was unverified after the
2026 upgrade; a generation switch alone is not safe evidence of recoverability.

After an approved restore, use console access to verify generation and paths, service
health, credentials and the full [VPS acceptance checks](deployment.md#vps-acceptance).
Account for mail since the snapshot and report missing data. Snapshot-era passwords
may return; re-provision target secret files only when reattempting the corresponding
target. Do not claim successful recovery before access and mail checks pass.

## Retained legacy source recovery

On 2026-09-29 the operator retired `/etc/nixos` and root's `nixos-23.05` channel after
consumer checks and a protected byte-compared copy. The recorded root:root `0700`
archive is `/root/checkup-us07-legacy-20260929`, containing `nixos-copy` and
`nixos-retired`. Both compared equal; root and user channel lists were empty.
See [retirement evidence](archive/01-checkup/EVIDENCE.md#legacy-source-investigation-and-maintenance-decision-2026-09-29t090807z091606z).

Future operations use pinned Git flakes. If specifically recovering the legacy entry
points, verify the protected copies still exist and `/etc/nixos` is absent before
`sudo mv /root/checkup-us07-legacy-20260929/nixos-retired /etc/nixos`.
`sudo nix-channel --add https://nixos.org/channels/nixos-23.05 nixos` restores only
registration; do not update or rebuild from this obsolete channel as incidental work.
The independent copy remains protected. Neither action restores mail or activates a system.
