# Fredy recovery and upgrade handoff

[Knowledge index](README.md) · [Operations](fredy.md) ·
[Deployment](deployment.md) · [Recovery](vps-recovery.md)

Prepared on 2026-10-03 for implementation in a separate Codex session using
Sol Medium. The user requested live diagnosis and a detailed implementation
plan. Production changes have not been authorized by that request.

## Objective and starting point

Restore reliable scheduled searches and Telegram listing delivery, and upgrade
Fredy to the latest stable release that passes compatibility and capacity checks.
Protect the existing mail service on the 1 GiB VPS. Keep the image pinned by
digest and resolve the Chromium child-process leak without simply increasing
resource limits.

Read `AGENTS.md`, the `nix-engineer` skill, `modules/fredy.nix`, and the linked
operations, deployment and recovery pages. Use `nix-reviewer` before the first
push. No flake input update is needed for this work; if one becomes necessary,
treat it as additional scope using `update-flake`.

The planning branch is `docs/fredy-recovery-upgrade-plan`, created from
`6299b6504c168dee58d1fc4670f19ae5f44527f8` on `feat/fredy-vps-hosting`.
Inspect the actual branch, working tree and PR base before starting; preserve
unrelated work. The diagnostic ZIP is untracked and must not be committed.
Continue implementation on this same feature branch, retaining the handoff
commit. The eventual PR should contain both the diagnosis/plan commit and the
implementation commits.

The live VPS reported source revision
`68c6cc671415117d7b06569ff125da6dbfaca7b2`. Its active and selected system was:

```text
/nix/store/85lhgp48pks17dl5fhi85755pywsnkzr-nixos-system-nixos-vps-26.05.20260925.f5c082a
```

Its booted system was the older retained closure:

```text
/nix/store/84wm9gcjc6whvj2g0hh22ixz0jfmmw77-nixos-system-nixos-vps-26.05.20260925.f5c082a
```

Recheck these paths before any activation. The declared image is 25.2.0 at
`sha256:74e075c34a38223faaef7705c4f7de637d1dafc683bd61dfa46bb391980c665b`.
The debug report also identifies 25.2.0. Rootful Podman inspection of the actual
image ID/digest remains to be done because `sudo -n` required a password.

## Confirmed diagnosis

Source: read-only SSH to `fdm@mail.maurerf.com` on 2026-10-03, principally
20:41:50 UTC, and the user-supplied debug ZIP. No searches, notification tests,
restarts or production writes were performed.

| Measurement | Observation |
| --- | --- |
| Runtime | Podman 5.8.7; Fredy active since 2026-09-29 22:50:06 UTC; zero systemd restarts |
| Container main process | Host PID 31134, `node`; namespace PID 1; 11 threads |
| Process population | 116 processes: Node plus 115 zombies, all zombies parented to Node |
| Zombies | 97 `chrome_crashpad`, 18 other defunct Chrome processes |
| PID controller | Current 126, maximum 128, recorded peak 129, `pids.events max=362` |
| Memory | Current 327,852,032 bytes; cap 469,762,048 (448 MiB); peak 469,782,528 |
| Memory events | `max=600`, `oom=0`, `oom_kill=0`, `oom_group_kill=0` |
| Container swap | Current 52,916,224 bytes; cap 134,217,728 (128 MiB) |
| Swap events | `high=0`, `max=19040`, `fail=19040` |
| Host memory | 584,200,192 bytes available; 268,697,600 bytes swap used at this sample |
| Root disk | 3,215,826,944 bytes available (about 2.995 GiB); 648,884 free inodes |
| Mail/access units | Postfix, Dovecot, Rspamd, nginx, sshd, redis-rspamd and kresd@1 active; no failed units |

The application log records 174 Chromium startup failures from October 1–3,
all failing to spawn the crashpad helper with errno 11. PID limit rejections
and the accumulated zombies establish the immediate browser startup failure.
The memory/swap counters also establish past pressure; absence of OOM kills does
not establish adequate browser capacity. Counter values are cumulative for this
container and do not date individual incidents.

The Podman service's own cgroup contained only `conmon` and reported one task.
The payload was in a separate cgroup:

```text
/machine.slice/libpod-8f2f9e2226c575de980b347ceeec24f5b9bc85ccbeb5d985d3f02115da9299e4.scope/container
```

Measure the payload cgroup, not only `systemctl show podman-fredy.service`.
Rediscover its path from the live process or Podman after every recreation.
For a read-only refresh, unprivileged SSH can read `ps`, `/proc/<pid>/cgroup`,
`/proc/<pid>/status`, and the payload's `pids.*`, `memory.*` controller files.
It can also read service status, free space and configuration revision. Avoid
dumping command arguments, environments or database contents containing secrets.
Rootful `podman inspect`, protected logs and state backup require operator sudo;
arrange an interactive terminal without putting the password in commands or files.

## Upstream findings and version choice

Direct GitHub API/source inspection on 2026-10-03 established:

- [29.2.1](https://github.com/orangecoding/fredy/releases/tag/29.2.1) is the latest
  stable release, published 2026-10-02 at 18:19:38 UTC. Its source commit is
  `9f6551ee7424` (resolve and record the full commit during preparation).
- Its [Dockerfile](https://github.com/orangecoding/fredy/blob/29.2.1/Dockerfile)
  installs `tini` and sets `ENTRYPOINT ["/usr/bin/tini", "-g", "--"]`, with
  `CMD ["node", "index.js"]`. The comments describe this exact Node-as-PID-1
  failure: orphaned Chromium helpers accumulate until the PID limit is reached.
  The image uses Debian trixie, exposes 9998, and retains `/conf` and `/db`.
  Tagged source is evidence of intended behavior; the registry image still
  needs to be checked.
- The [25.2.0 to 29.2.1 comparison](https://github.com/orangecoding/fredy/compare/25.2.0...29.2.1)
  includes SQL migrations 32 through 47. Migration 32 introduces configured
  notification adapters; other migrations affect working-hours timezones,
  commute filters, listing data, attachments and onboarding. This is a data
  migration, not just replacing a browser binary.
- [29.2.0](https://github.com/orangecoding/fredy/releases/tag/29.2.0) was published
  on September 28, before our September 29 choice of 25.2.0. The repository
  records the deliberate digest-pinning policy, but no reason for choosing
  that older version. Do not describe 25.2.0 as the latest release at deployment.

Recheck `/releases/latest` directly at implementation time. Search-engine release
indexes were stale during diagnosis and still showed 25.2.0. If a newer stable
release exists, review its additional changes and name the selected version
explicitly before preparing the candidate.

## Implementation sequence

### 1. Resolve access and capacity before preparing production

Refresh the measured counters, service/mail baseline, actual running image and
mounts. Do not restart first and lose the useful process/cgroup evidence.

The disk is already slightly below the required 3 GiB free floor. Calculate
headroom for the old image, new image's unpacked layers and writable layer,
Fredy backup, Nix closure and normal mail growth. Registry compressed sizes
alone do not establish required space. Prepare image/build verification on an
independent Linux system where possible. Do not download a large candidate to
the VPS until a concrete space budget is satisfied.

Inventory disk use with read-only tools if needed. Do not run broad Nix GC,
Podman prune, delete logs/mail/state, or remove retained recovery images and
generations to make room. Present a specific space-recovery proposal or obtain
an explicit capacity decision if the upgrade cannot fit.

### 2. Verify the release and migration route

Resolve the selected release tag to its source commit and registry digest.
Verify a Linux amd64 manifest exists, inspect its config for version/source,
entrypoint, command, user, health tooling, ports and volume contract, and test
image retrieval. Preserve the current image for recovery.

For 29.2.1, confirm the published image actually starts under `tini`. If it does,
use that built-in reaper and avoid adding a redundant init wrapper. Do not
override the entrypoint so that Node becomes PID 1 again.

Read the migration runner and migrations 32–47 in tagged source. Establish
whether direct 25.2.0 to target migration is supported, and whether rollback
requires the pre-upgrade state. Pay particular attention to converting existing
Telegram adapters into channels, preserving job/channel ownership and links,
working hours and timezone defaults, and startup backfills on the small host.
Review changed browser/provider code and newly enabled background work as well.

Test migration on isolated state if practicable. Use synthetic representative
25.2.0 data, or an approved protected copy of real state. Prevent the isolated
instance from running scheduled searches, delivering Telegram messages or
serving publicly; prefer disabled networking and documented test controls.
Never point it at the production bind mounts. Do not expose tokens in test
output. If representative migration rehearsal is unavailable, record that gap
in the deployment proposal rather than asserting compatibility was tested.

### 3. Prepare the focused Nix candidate

Update the version comment and image digest in `modules/fredy.nix`. Keep existing
state paths, loopback binding, HTTPS/login boundary, explicit Podman health
command and log cap. Start with the existing 448 MiB memory, 128 MiB additional
swap, 0.5 CPU and 128 PID limits; reaping the zombies addresses the measured
leak. Reassess limits only if the repaired workload still demonstrably fails.

If migration or disk preparation blocks a timely upgrade, prepare a separate
minimal candidate using the current image with Podman's `--init`. Verify the
locked Nixpkgs/Podman init binary and path are present in the generated runtime
configuration; do not assume a distribution-default path works on NixOS.
This fallback also requires recreation and deployment approval. Raising the PID
limit or scheduling periodic restarts would only delay this confirmed leak.

Update the operations guide for the selected release, process reaping,
notification-channel migration and revised acceptance checks. Keep dated
historical measurements distinct from new declarations and observations.

### 4. Validate and review before asking to deploy

Evaluate both `vps` and `vps-fredy-bootstrap` with locked inputs and run the
repository flake checks. Build both affected outputs on a compatible Linux
builder per `deployment.md`; do not call a Mac evaluation or a dry run a native
Linux build. Avoid heavy builds on the 1 GiB mail VPS. Report unavailable builder
capacity as an unmet gate and obtain an explicit decision if needed.

Inspect generated Podman arguments and image config together to establish which
init runs, check the retained mounts and limits, and verify the image can be
retrieved independently of the Nix build. A service-start image pull is not
validated merely by building the NixOS closure.

Run `git diff --check` and relevant Markdown link/content checks. Use the local
`nix-reviewer` skill against the complete proposed PR diff, resolve blocking
findings and review corrections before pushing. Establish the real PR base so
existing hosting commits are not accidentally included in an unrelated PR.
Record a clean candidate commit, lock hash, build results, closure differences,
image digest, remaining risks and recovery route.

### 5. Obtain approval and activate the concrete candidate

Present the completed candidate and evidence, VPS target, expected interruption,
space budget, backup/recovery readiness and remaining limitations. Follow
`deployment.md` for explicit production approval and `vps-recovery.md` for
fresh snapshot/console and generation readiness. This handoff authorizes
preparation; it does not authorize a restart, state migration or activation.

During the approved window, stop Fredy and make a consistent protected backup
of both `/var/lib/fredy/conf` and `/var/lib/fredy/db`, including SQLite WAL/SHM.
Verify the archive and old image/closure before starting the new image. Choose
and document the sequence so the backup corresponds to the final pre-migration
state. A same-disk archive does not protect against losing the VPS disk.

Use the approved `test`, acceptance, then `switch` sequence for public `#vps`.
The existing account is already initialized; do not repeat first-login bootstrap
activation or reset credentials. The bootstrap output still needs validation
because it shares the changed module. Remember that `test` starts services and
can migrate the database.

### 6. Accept behavior and observe beyond the original failure interval

- Confirm the expected release/digest and init as namespace PID 1, with Node as
  its child. Verify state, account login, jobs, schedule and Telegram channel
  associations survived migration. Check HTTPS and the existing access boundary.
- Take a fresh cgroup/process baseline after recreation. Follow several normal
  browser searches; zombies must be reaped, the idle task count must return near
  its baseline, and `pids.events max` must not grow. A transient exited child
  during a scrape is different from persistent accumulation after it finishes.
- Verify a representative existing search returns expected available listings.
  Zero genuinely new listings can be valid; distinguish that from browser errors
  and provider blocking. Validate Telegram delivery with an explicitly authorized
  test or real new listing and user confirmation. Do not delete listings to force
  deduplication to send them again, and do not send messages without authorization.
- Monitor memory/swap events and current/peak usage during searches, host memory
  pressure, restart counts and disk space. Zero OOM kills alone is insufficient:
  recurring swap-limit failures or browser failures require investigation.
- Repeat repository mail/access acceptance and reconcile any controlled mail
  tests. Active service status alone does not prove mail delivery.
- Observe at least 24 hours, preferably 48 hours because the original service
  failed after about a day. Record early acceptance as provisional until this
  finishes. Arrange an operator follow-up; a session that ends sooner must leave
  this check explicitly pending. Disable diagnostic verbosity after diagnosis
  when the operator no longer needs it.

If acceptance fails, stop the deployment sequence and assess state compatibility.
Follow the recovery guide: reverting the NixOS generation does not undo SQL
migrations. Restoring the matching pre-upgrade state requires explicit approval
because it discards later changes. Preserve the failed state for diagnosis and
do not restore the whole mail VPS to repair Fredy without a separate decision.

## Prompt for the next session

> Continue on `docs/fredy-recovery-upgrade-plan`. Read `AGENTS.md` and
> `docs/fredy-upgrade-plan.md`. Implement the Fredy repair and upgrade candidate
> described there, using the nix-engineer workflow.
> Start from the confirmed Chromium zombie/PID exhaustion diagnosis. Verify
> the newest stable image, its built-in init and database migration path;
> address the measured disk-space constraint before production preparation.
> Preserve the untracked debug archive and unrelated work. Complete the code,
> documentation, affected-host validation and local nix-reviewer review needed
> for a concrete deployment proposal. Commit the implementation on this branch
> and create a PR containing both the existing handoff commit and your commits,
> after completing local review before the first push. Ask for production
> approval only after the proposal is ready. Do not activate or restart the VPS
> from this prompt.

## Technical references

- [Podman init behavior](https://docs.podman.io/en/latest/markdown/podman-run.1.html#init):
  an init process forwards signals and reaps children; verify syntax and init path
  against the installed Podman version for the fallback candidate.
- [Linux cgroup v2 documentation](https://docs.kernel.org/admin-guide/cgroup-v2.html):
  controller counters and PID/memory limit behavior used in this diagnosis.
