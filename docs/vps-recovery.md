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

The Fredy bootstrap `test` first started on 2026-09-30 and created
`/var/lib/fredy/conf` and `/var/lib/fredy/db` on the same root disk. The
SQLite database contains account hashes, a session signing secret,
jobs, listings and Telegram credentials. Treat a Fredy state copy as secret
material. A VPS snapshot includes it only if captured after Fredy state exists;
the historical snapshot above predates it.

## Fredy backup and recovery

No scheduled daily Fredy backup is configured for the initial trial. Before a
Fredy image upgrade, record the running digest and state paths, verify free
space and make a consistent protected copy of **both** `/var/lib/fredy/conf`
and `/var/lib/fredy/db`. The simplest route is an approved brief stop of
`podman-fredy.service`, then a root-only archive of all of `/var/lib/fredy`,
followed by a start of the same image and health checks. For an approved upgrade,
choose a new unique name and create the archive while the service is stopped:

```sh
sudo systemctl stop podman-fredy.service
sudo install -d -o root -g root -m 0700 /root/fredy-backups
sudo tar -C /var/lib -cpf /root/fredy-backups/fredy-preupgrade-YYYYMMDDTHHMMSSZ.tar fredy
sudo chmod 0600 /root/fredy-backups/fredy-preupgrade-YYYYMMDDTHHMMSSZ.tar
sudo tar -tf /root/fredy-backups/fredy-preupgrade-YYYYMMDDTHHMMSSZ.tar
sudo systemctl start podman-fredy.service
```

Replace the timestamp placeholder with a new timestamp before running any
command. The listing should contain `fredy/conf` and `fredy/db`; inspect it
without printing secret contents. Include SQLite WAL and SHM files; do not
copy only a live `listings.db`. Check archive readability, ownership and
retention before changing the pinned image. A same-disk copy helps with
application mistakes but cannot recover a lost VPS disk.

For a failed new image, stop Fredy and assess whether it wrote a new database
schema. If state remains compatible, restore the previously reviewed NixOS
generation and image, then check account, jobs and notifications. A NixOS
rollback alone does not reverse database writes. If the previous image cannot
read the changed data, ask for explicit approval before replacing current Fredy
state with the matching pre-upgrade copy; this discards all later Fredy changes.
After approval, use the matching pre-upgrade archive and a distinct name for
the failed state. Check that the archive contains only the expected `fredy/`
tree, then restore while Fredy is stopped:

```sh
sudo systemctl stop podman-fredy.service
sudo tar -tf /root/fredy-backups/fredy-preupgrade-YYYYMMDDTHHMMSSZ.tar
sudo mv -T /var/lib/fredy /root/fredy-backups/fredy-failed-YYYYMMDDTHHMMSSZ
sudo tar -C /var/lib -xpf /root/fredy-backups/fredy-preupgrade-YYYYMMDDTHHMMSSZ.tar
sudo chown -R root:root /var/lib/fredy
sudo chmod 0700 /var/lib/fredy /var/lib/fredy/conf /var/lib/fredy/db
```

Replace placeholders with the approved archive and new failed-state name;
confirm neither destination already exists. Do not extract untrusted archives
or silently overwrite live state. Restore the reviewed previous NixOS
generation and image using [generation recovery](deployment.md#generation-recovery)
before starting Fredy; that activation may itself start the service. Verify
the active unit references the previous digest, start it if necessary, and
repeat Fredy plus mail acceptance.
Do not restore the whole mail VPS snapshot just to repair Fredy without a
separate recovery decision. If Fredy harms mail or host resources during the
trial, stop `podman-fredy.service` within the approved incident scope and
diagnose before changing limits, deleting state or altering the VPS size.

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
