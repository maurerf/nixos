# Fredy hosting implementation plan

[Knowledge index](README.md)

Status: candidate prepared on 2026-09-29; the operator added dedicated Fredy
DNS and approved staged activation on 2026-09-30. The bootstrap and public
stages were activated and selected in sequence that day; the public stage was
running from source revision `68c6cc671415117d7b06569ff125da6dbfaca7b2`
at the [dated post-switch check](fredy.md#candidate-and-measured-budget). The
[Fredy operations guide](fredy.md) gives the measured baseline, selected image,
first-login, DNS and Telegram steps. This plan remains the design record.
The operator confirmed actual Telegram listing notifications on 2026-09-30.
Authenticated event-stream inspection and sustained trial observation remain
pending.

## Goal and agreed requirements

Host [Fredy](https://github.com/orangecoding/fredy) on the existing Vultr NixOS VPS
for the operator and his girlfriend to find a rental flat in Hamburg. They are
not in a rush and want a useful longer-running search. Apartment criteria,
neighbourhoods, portals and search count are configured later in Fredy's UI;
do not require those decisions to implement the hosting infrastructure.

| Area | Agreed decision |
| --- | --- |
| Browser access | Public HTTPS at `fredy.maurerf.com`, protected by login |
| Accounts | One shared Fredy account |
| Notifications | A new Telegram bot and a new shared group; include operator setup instructions |
| Deployment | Upstream container pinned by digest, managed declaratively by NixOS using Podman |
| Host capacity | Trial on the existing 1024 MB RAM, 1 vCPU VPS |
| Capacity priority | Protect existing mail services; constrain Fredy and stop/reassess if the trial is unsuccessful |
| Upgrade VPS | Not initially; operator reports downsizing later would require recreating the VPS |
| Persistence | Configuration and database outside the disposable container |
| Backups | Consistent Fredy backup before upgrades; no scheduled daily Fredy backup initially |
| Data-loss tolerance | Rare loss of listings is acceptable; old rental listings quickly lose value |
| Updates | Deliberate, reviewed image changes rather than automatic tracking of a moving tag |
| DNS | Operator manages domain through Epik and will add a record using concrete instructions |
| Paid dependencies | None initially; revisit only if useful portals are blocked |

The operator understands that database loss can also lose searches, account and
Telegram configuration. Normal restarts, container replacement and NixOS rebuilds
must preserve these. Existing VPS snapshot policy remains applicable; it is not a
daily Fredy backup or a guarantee of recoverability.

## Repository context and authority

Read [repository rules](../AGENTS.md), the
[nix-engineer skill](../.agents/skills/nix-engineer/SKILL.md),
[architecture](architecture.md), [deployment](deployment.md),
[VPS recovery](vps-recovery.md) and applicable [decisions](decisions.md).
Those documents remain authoritative for workflows, activation approval and
recovery boundaries. Do not copy historical exceptions into this deployment.

Relevant configuration:

- [flake.nix](../flake.nix) composes `nixosConfigurations.vps` for `x86_64-linux`.
- [machines/vps.nix](../machines/vps.nix) declares mail, nginx and ACME.
- [modules/nixos-base.nix](../modules/nixos-base.nix) contains shared Linux settings.
- [hardware/vultr-vps.nix](../hardware/vultr-vps.nix) describes VPS hardware.

At planning time the VPS configuration serves mail, nginx handles ACME for
`mail.maurerf.com`, and Fredy/Podman are not declared. The acceptance procedure
currently keeps port 443 nonpublic unless a new requirement justifies it; this
public HTTPS application is that new requirement. Update the affected guidance
as part of implementation. Preserve mail DNS, outbound IPv4 policy, credentials,
state versions and retained recovery generations.

Use a feature branch, preserve unrelated work, keep reusable service settings in
`modules/` and VPS choices in `machines/vps.nix`. Do not import this Linux service
into Darwin. No flake input update is needed by default. Follow the local
nix-reviewer workflow before the first push. No push or activation is requested
by the creation of this planning document.

## Research findings and limitations

Source inspection on 2026-09-29 established the following. Recheck against the
specific release selected for implementation; upstream `master` links can change.

- At planning time, the pinned nixpkgs had neither `pkgs.fredy` nor a built-in
  Fredy service module. The implementation adds a local
  `services.fredy.bootstrapOnly` option; it is not an upstream NixOS module.
  Online research found no community package, which is not proof that none
  exists. Building a custom native package is outside this plan.
- The [upstream README](https://github.com/orangecoding/fredy#readme) documents
  container deployment, application port `9998`, `/conf` and `/db` volumes,
  SQLite persistence and default `admin` / `admin` credentials. Most application
  settings and uploaded documents are stored in the database.
- The selected [25.2.0 Dockerfile](https://github.com/orangecoding/fredy/blob/25.2.0/Dockerfile)
  includes Node.js, native SQLite support and a CloakBrowser Chromium binary;
  it does not declare a separate init process. This dependency stack favours
  the upstream image over a new native Nix packaging project. Its HTTP health
  check alone does not prove that searches or notifications work.
- [Provider documentation](https://github.com/orangecoding/fredy/blob/master/doc/providers.md)
  describes datacenter-IP blocking for some browser-based portals. A working UI
  is not proof that the VPS can fetch listings. ImmoScout uses a separate mobile
  API path; this is not a guarantee of availability. No proxy subscription is
  included. Report blocked portals and revisit with the operator if needed.
- [Telegram's tutorial](https://core.telegram.org/bots/tutorial) documents
  creating bots with BotFather. Check Fredy's selected-version Telegram adapter
  for its exact fields and group setup procedure.

At planning time no runtime capacity check or Fredy load test had occurred.
The later [dated baseline](fredy.md#candidate-and-measured-budget) still cannot
establish browser-load feasibility. A 1 GB VPS running mail may have
insufficient headroom; feasibility must be demonstrated. Do not present
2 GB or any other size as a measured minimum. Resource limits reduce risk but do
not completely isolate shared CPU, memory, disk and network contention.

## Intended architecture

```text
Browsers -> HTTPS :443 -> nginx -> localhost-only published port -> Fredy/Podman
                                                                    |
                                              persistent /conf and /db
                                                                    |
                                        property portals + Telegram API
```

Use `virtualisation.oci-containers` with the Podman backend, verifying the options
in the repository's pinned nixpkgs. Put reusable configuration in a focused module
such as `modules/fredy.nix`; avoid an elaborate abstraction for one instance.

- Select a stable upstream version, inspect its release/migration information,
  verify an `linux/amd64` image exists, and record its immutable registry digest
  in Nix alongside a readable version reference. Do not deploy `master` or
  `latest` as an unpinned image. Verify the selected digest can actually be pulled;
  a NixOS system build may not fetch an OCI image pulled at service startup.
- Publish the application only on loopback, for example
  `127.0.0.1:9998:9998`, after checking for port conflicts. Do not expose port 9998
  publicly, enable host networking or grant privileged container mode.
- Configure nginx with ACME, HTTPS redirect, appropriate forwarded headers and
  support for Fredy's live event stream if required by the selected release.
  Verify proxy trust, application base URL and session behaviour for HTTPS.
- Persist data under a dedicated location such as `/var/lib/fredy/conf` and
  `/var/lib/fredy/db`, mapped to `/conf` and `/db`. Confirm container UID/GID and
  directory permissions. Avoid blanket world-writable permissions. Inspect the
  release's configuration bootstrap before mounting or generating config files.
- Keep passwords and Telegram tokens in protected runtime state, never literal
  Nix values, Git, store files, command histories or diagnostic output. Treat
  database backups as secret-bearing files.
- Set a hard memory cap, bounded swap use if supported, CPU allocation and a PID
  limit after measuring headroom and browser behaviour. Ensure limits cover
  browser children. Do not choose a PID cap so low that ordinary browser startup
  fails. Bound log growth and restart retries to avoid a crash loop consuming
  resources indefinitely. Do not automatically add swap as a substitute for
  proving capacity.
- Use the existing systemd/journal facilities for operation. Keep diagnostics
  focused on failures, resource pressure and search/notification success; avoid
  adding a separate monitoring stack for this trial.

## Implementation sequence

### 1. Establish baseline and choose the trial budget

Inspect current host state through the normal authorized access route without
printing credentials or mail contents. Record available RAM, swap configuration,
CPU load, free disk/inodes, existing service health and intended listeners.
Useful tools include `free -m`, `swapon --show`, `df -h`, `df -i`, `systemctl
--failed` and appropriate service/cgroup statistics. Use current observations,
not archived host measurements.

Reserve headroom for mail and the operating system. Choose explicit Fredy limits
and explain their basis. If no plausible browser budget fits, report this before
activation; the operator's request to test 1 GB is not permission to jeopardize
mail. Account for image storage, browser peaks, database growth and build load.
Prefer a compatible external Linux builder if building on the small VPS would
itself create unacceptable pressure; report if none is available.

### 2. Prepare configuration and operator instructions

Implement the architecture above, inspect selected-version authentication and
bootstrap behaviour, and establish a concrete first-login procedure. The default
credentials must never be reachable on the public endpoint. One possible sequence
is to keep the Fredy virtual host unavailable externally while accessing the
loopback application through an SSH tunnel, replace the initial credentials, and
then enable public access. Verify this works with the selected release and include
every activation involved in the deployment proposal.

No additional SSO system is requested. Check how signup, password changes and
unauthenticated routes behave so that the shared-account intent is met. Disable
unneeded public registration if applicable. Do not assume that nginx alone adds
application authentication.

### 3. DNS instructions for the operator

First verify authoritative nameservers: registration at Epik does not by itself
prove Epik hosts DNS. Confirm the VPS public IPv4 address from current host/provider
information, rather than copying an old address. Give the operator the actual
value before asking them to add the record.

In Epik, select `maurerf.com` and open its DNS host-record editor. Confirm the
current UI labels at implementation time, then add:

| Field | Value |
| --- | --- |
| Record type | `A` |
| Host/name | `fredy` (or `fredy.maurerf.com` if the UI requires a full name) |
| Address/target | Verified public IPv4 address of this Vultr VPS |
| TTL | 300 seconds if supported, otherwise the available default |

Save the added record while preserving existing records and nameservers. Do not
replace the DNS zone: mail depends on its existing MX, A/AAAA and TXT records.
Check for a conflicting `fredy` CNAME or stale address first. Do not add an AAAA
record until end-to-end IPv6 access has been verified; this does not remove the
repository's existing IPv6 acceptance requirements for mail. Check authoritative
and public DNS resolution, ACME reachability and any existing CAA restriction.
Allow HTTPS through both host and applicable Vultr firewalls; preserve HTTP-01
challenge reachability on port 80.

### 4. Telegram instructions for the operator

1. Open the official verified `@BotFather` in Telegram, use `/newbot`, and choose
   a display name and available bot username.
2. Store the issued token privately. Do not paste it into the implementation
   conversation, Git or shell commands that will be recorded.
3. Create a private Telegram group containing the operator and his girlfriend,
   add the bot, and permit it to send messages. Grant only permissions required
   for notifications; do not grant administrator access by default.
4. Follow the selected Fredy version's instructions to obtain the group's chat ID.
   If using Telegram's API, use a private local workflow that does not expose the
   token in terminal history/logs or to third-party chat-ID services. A bot command
   addressed to the bot can provide an update while retaining privacy mode.
   Verify the signed group ID, including any supergroup prefix, is preserved.
5. In Fredy's UI, create a Telegram notification channel using that token and chat
   ID. Attach it to the initial search job and confirm receipt in the shared group.

Check both a notification test, if supported, and an actual search result. The
operator supplies search criteria at this stage; no apartment criteria need to be
encoded in Nix. Fredy should contact Telegram outbound; do not add an inbound
Telegram webhook endpoint unless inspection demonstrates it is necessary.

### 5. Validate, review and prepare deployment

Follow [select checks](deployment.md#select-checks): evaluate and build the affected
VPS configuration with locked inputs, run the applicable flake checks and
`git diff --check`. A Mac evaluation is not a native Linux build. Report unavailable
builders explicitly. Inspect the generated unit, port mapping, limits, data paths
and nginx configuration. Verify the image separately as noted above.

Run the [nix-reviewer](../.agents/skills/nix-reviewer/SKILL.md) workflow against the
full proposed diff before pushing, resolve blocking findings and review corrections.
Use focused commits/PRs and summarize validation and limits there. No new PRD,
command log or separate evidence document is needed unless an actual consequential
decision requires it.

Before production activation, present the concrete committed candidate, build
results, resource budget, image digest, bootstrap/public-access sequence, timing
and recovery route. Establish fresh backup/console/retained-generation readiness
under [deployment](deployment.md#deployment) and [VPS recovery](vps-recovery.md).
Obtain explicit operator approval. Planning approval is not activation approval;
`nixos-rebuild test` also activates services.

### 6. Execute and assess the trial

After approved activation, verify:

- Correct source/generation state and the repository's VPS mail/access acceptance
  checks before and after the change; DNS, firewall and nginx changes must not
  disrupt mail or ACME.
- Valid TLS and authenticated access from both users' devices; default credentials
  no longer work and port 9998 is unreachable externally.
- Persistence of account, job and channel through a controlled container restart;
  inspect mount configuration to establish persistence across replacement too.
- At least one representative Hamburg rental search fetches actual listings and
  sends a notification to the shared Telegram group.
- Repeated cycles, including browser-based searches if intended, stay within the
  agreed resource budget without host OOM events, repeated container OOM kills,
  sustained swap thrashing, restart loops or mail degradation.

Start with a small workload and conservative scheduling. Measure browser peaks,
not just idle UI memory. Propose an observation window covering several scheduled
cycles, preferably a day of ordinary use, and label initial acceptance provisional
until that observation finishes. Do not claim all portals work from one successful
provider or confuse an IP block with memory exhaustion.

If mail is affected or Fredy cannot operate reliably within its budget, stop Fredy
and diagnose within the approved recovery scope. Do not automatically raise limits,
resize the VPS, buy a proxy or relax exposure controls. Present alternatives to the
operator. Availability of a subset of useful portals may be acceptable, but record
the limitation and ask before declaring the reduced scope successful.

## Backup, upgrades and recovery

For the initial installation there is no existing Fredy database to back up; host
recovery preparation still applies. Before subsequent Fredy upgrades:

1. Record the current image digest, configuration and data location.
2. Make a consistent backup of both configuration and database. A brief Fredy stop
   and protected copy of the full state is the simplest option; otherwise use a
   verified SQLite backup method. Do not copy just a live database file while
   ignoring WAL state. Check backup readability and available disk space.
3. Keep backup permissions restrictive and agree reasonable retention without
   deleting repository-mandated host recovery material. A same-disk backup helps
   with application mistakes but does not protect against losing the VPS disk.
4. Review release migrations, update the pinned image, and repeat relevant checks.

A NixOS generation rollback or container downgrade does not undo database writes.
If the previous application cannot read the migrated data, recovery needs a stopped
service, the compatible previous image and its matching pre-upgrade state. Restoring
that state loses later Fredy changes. Document the exact recovery procedure and
obtain approval for destructive restoration. Do not restore the entire mail VPS
snapshot merely to repair Fredy without a separate explicit recovery decision.

## Completion and handoff

The implementation is complete when the agreed service is deployed with approval,
both users can log in, a representative search delivers Telegram results, state
persists, and the constrained trial demonstrates acceptable mail and host health.
Report unresolved portal/capacity/platform limitations explicitly.

Update [architecture](architecture.md) with the new service relationship,
[deployment](deployment.md) with the justified HTTPS exposure and Fredy acceptance
checks, and [VPS recovery](vps-recovery.md) with actual state paths and upgrade/restore
procedures. Keep Nix authoritative for exact declarations. Replace this plan's
pending status with an implementation outcome and links when work completes;
date runtime observations separately from design decisions.

Also document how to retire Fredy when the flat search ends: disable its service
and virtual host, review whether 443 remains needed, remove the dedicated DNS
record and revoke the Telegram bot token. Delete persistent state/images/backups
only after an explicit retention decision. Do not alter mail or resize the VPS as
part of retirement by default.
