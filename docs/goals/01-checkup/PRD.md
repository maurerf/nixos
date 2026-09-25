# Nix repository and deployed-system checkup

## 1. Summary

Restore a repeatable, supported maintenance path for the M2 MacBook Air and the Vultr mail VPS. Establish configuration provenance, select compatible stable inputs, validate both systems, and prepare recovery before deployment. Preserve working functionality and mail data. Implement on the Mac first, then the VPS in a separate window.

This document specifies later work. This session performed discovery and planning only. It did not update inputs, change Nix configuration, build, activate, or connect to the VPS.

## 2. Background and current state

Evidence was collected on 2026-09-25. Local command outputs and the user's VPS transcript are retained in this directory. F1-F9 refer to the evidence index in [EVIDENCE.md](EVIDENCE.md#evidence-index). I1-I8 refer to the user's recorded answers in [EVIDENCE.md](EVIDENCE.md#interview-decisions). Observations from the VPS are user-supplied, not independently executed by the agent.

### Repository

HEAD is `b335654465345dbc9bd283bfbaebb2ce31adb890`, committed on 2026-05-23. `flake.nix` defines `darwinConfigurations.m2-macbook-air` for aarch64-darwin and `nixosConfigurations.vps` for x86_64-linux. Host settings live in `machines/`, Home Manager profiles in `profiles/`, reusable settings in `modules/`, and VPS hardware settings in `hardware/`. [verified: file inventory, `git log`, static inspection; F1/F2]

The inputs track nixpkgs-unstable, nix-darwin master, Home Manager master, and the mailserver's unspecified default branch. Nixpkgs is shared through follows relationships. Locked commit ages are 125 days for nixpkgs and Home Manager, 131 for nix-darwin, and 127 for mailserver. Transitive pins are also recorded in EVIDENCE.md (F2). These ages do not measure the number of missing upstream commits. [verified: `flake.lock` and timestamp calculation; F1/F2]

There is no declared flake check or formatter output and no tracked CI configuration. README profile paths are stale. Spotify is commented out; the Dovecot Sieve workaround requires compatibility review before any removal. Credential settings exist directly in tracked Nix modules, including an initial password and a mail password hash. No agenix or sops integration was found. No secret values were retained in this audit. [verified: safe static inspection; F1/F2/F4]

The working tree already contained `targets.darwin.linkApps.enable = true` in `profiles/home-darwin.nix` and an untracked `AGENTS.md`. These must be preserved and explicitly accounted for in later work. [verified: `git status --short`, `git diff`; F1]

### Mac

The Mac runs macOS 26.6.2, Nix 2.34.7+1, and nix-darwin generation 34. Its nix-daemon is running; 32 build users have UIDs 351-382. Nix enables flakes and nix-command. Installer receipt metadata and a Determinate backup configuration file exist, but the original installer lineage and migration history are not conclusively established. Do not replace the installer or renumber build users based on these observations alone. [verified: `sw_vers`, `nix --version`, `launchctl`, `dscl`, safe metadata inspection; F2-F4]

The active generation reports nix-darwin revision `56c666e108467d87d13508936aade6d567f2a501` and nixpkgs revision `a0991c886dc83e6e9de01d5266e4842985b1850e`, both matching the lockfile. Its profile-link timestamp is 2026-05-23. `darwin-version --configuration-revision` reports that the configuration commit is unknown. Matching input revisions do not prove that the full configuration or Home Manager input matches HEAD. [verified: deployed version JSON, symlinks, `darwin-version`; F4]

User channels list as empty; root channels could not be read without a sudo password. A Home Manager generation 20 profile exists, although its command is absent from PATH. Its relationship to the integrated Home Manager configuration is unverified. Homebrew 5.1.15 and installed packages exist. The repo enables Homebrew integration with empty package lists and disables activation cleanup and updates; the package inventory is partial because Homebrew hit cache-access errors. [verified: channel commands, profile inspection, Homebrew commands; F2/F3/F4/F6]

### VPS

The VPS exists solely for mail, according to the user. It runs generation 21, Nix 2.31.2, and system label `26.05.20251129.59b6c96`. Its nixpkgs revision is `59b6c96beacc898566c9be1052ae806f3835f87d`, matching the historical lock at commit `8612229f7c2abc47ddc90e2f0e174962cf93ba9b`. That input is 300 days old. The configuration revision remains unknown; this match does not identify the deployment commit. The dated `26.05` label predates the stable release and must not be treated as proof of a stable deployment. [verified: user `nixos-version`, historical lock comparison; F8/F9; purpose: I1]

Zero failed units were reported. Postfix, Dovecot, Rspamd, Redis, nginx, SSH and resolver services run. Last recorded boot is 2026-07-13, with 74 days uptime. The 24G root filesystem has 9.4G available; the Nix store occupies 9.1G. This does not establish sufficient space for a new system closure alongside rollback generations. [verified: user `systemctl`, `who -b`, `uptime`, `df`, `du`; F8]

Host firewall rules allow incoming TCP 22, 25, 80, 465 and 993 over IPv4 and IPv6. Additional listeners on 443 and 12340 are not allowed by the shown host rules. Their purpose and provider firewall behavior remain unverified. External mail operation, TLS, DNS and authentication have not been tested. [verified: user `ss`, `iptables`, `ip6tables`; F8]

Root retains a nixos-23.05 channel. Both channel queries ran as root, so the login user's channels remain unknown. Flake and legacy configuration files under `/etc/nixos` have February 2024 timestamps; their presence does not establish the active source. No backup units matched the script's filter. The user reports taking full-system Vultr snapshots before major upgrades and having web-console access. Snapshot completion, coverage and restore testing are unverified. [verified: user transcript F8; user statements I6/I7]

### Drift table

| System | Deployed generation / revision | Repo HEAD | Gap |
| --- | --- | --- | --- |
| Mac | Generation 34; configuration revision unknown; nixpkgs `a0991c886dc8`, nix-darwin `56c666e10846` | `b335654465345dbc9bd283bfbaebb2ce31adb890`, plus existing profile edit | Those two inputs match; full configuration and Home Manager drift unknown |
| VPS | Generation 21; configuration revision unknown; nixpkgs `59b6c96beacc` | `b335654465345dbc9bd283bfbaebb2ce31adb890` | Nixpkgs matches a November 2025 historical lock rather than HEAD; exact configuration gap unknown |

[verified: F1/F4/F8/F9]

### Evaluation limitations

Metadata, output enumeration, and both toplevel drvPath evaluations were attempted with a read-only local store, offline settings, import-from-derivation disabled, no build jobs, and no lockfile writes. After enabling the command-local read-only-store feature, every attempt stopped before configuration evaluation:

```text
warning: Git tree '/Users/fdm/git/nixos' is dirty
error: opening lock file "/nix/store/11l5zyj8qzc3b6mcrjhgvrzwcva2da2b-source.lock": Operation not permitted
```

No successful evaluation or configuration deprecation result is available. This is an access/source-materialization failure, not evidence that either Nix configuration is invalid. The initial feature-enable error and complete commands are preserved in F5. A later implementation environment must permit normal Nix evaluation writes and authorized downloads. [verified: recorded Nix command attempts; F5]

## 3. Goals and non-goals

Goals are to produce successful evaluation and native-platform builds for both hosts; deploy from an identified clean source revision; preserve Mac workflows; preserve mail delivery, authentication and stored data; and demonstrate recovery within the accepted one-hour VPS outage limit. [I2-I8]

Use supported stable inputs with compatible module versions. At the audit date, NixOS 26.05 is supported until 2026-12-31 according to the [official announcement](https://nixos.org/blog/announcements/2026/nixos-2605/). Recheck support at implementation time. Exact target revisions and mailserver compatibility are implementation deliverables, not decisions already validated by this audit. [F7, I3]

Non-goals are broad refactoring, removing working features, moving mail to another provider, replacing the Mac's Nix installer, and treating state-version changes as routine upgrades. [I2/I5, planning constraints]

## 4. Requirements per system

All requirements apply to later implementation. Priority is must, should or could. Each source refers to a finding or interview answer above.

### Repository

| ID | Priority | Requirement | Source |
| --- | --- | --- | --- |
| R-REPO-01 | must | Select and record a mutually compatible supported stable input set for both platforms. Document any package-specific unstable exception. Keep shared nixpkgs unless a demonstrated compatibility need requires separation. | F1/F2/F7, I3/I5 |
| R-REPO-02 | must | Compare deployed baselines with the target release notes, including Nix, Home Manager and mailserver migrations. Choose direct upgrades unless a documented requirement calls for intermediate steps. Preserve existing system, home and mailserver state-version values unless a separate explicit migration decision is made. | F2/F4/F8/F9, I3, hard constraints |
| R-REPO-03 | must | Evaluate both toplevel drvPaths and run flake validation in an authorized environment. Record complete errors and warnings, resolve failures, and explain any retained warnings. Build both hosts on compatible platforms before activation. | F5, I2 |
| R-REPO-04 | must | Record the exact clean source commit and locked input revisions for each deployment and expose the configuration revision through the system version command. Preserve the existing profile edit and AGENTS.md; resolve their inclusion explicitly during implementation. | F1/F4/F8, I2 |
| R-REPO-05 | must | Replace tracked credential values with an appropriate runtime secret mechanism or protected external-file references. Document ownership, permissions, provisioning, recovery and rotation needs without putting values in Git, logs or the Nix store. Preserve mail login during the transition. | F2, I4/I5 |
| R-REPO-06 | should | Add lightweight PR CI that explicitly evaluates both host outputs with locked inputs and performs flake validation without deployment credentials. Require recorded native build results before deployment even when CI lacks a matching runner. | F1/F5, I2/I5 |
| R-REPO-07 | should | Correct repository layout documentation and document update, build, activation, validation and rollback procedures. Label historical deployment provenance as unknown where evidence remains insufficient. | F1/F4/F8, I2/I5 |
| R-REPO-08 | should | Review stale comments, the disabled Spotify entry and the Dovecot workaround against the selected target. Limit cleanup to verified obsolete material; do not remove currently used functionality. | F2, I2/I5 |

### Mac

| ID | Priority | Requirement | Source |
| --- | --- | --- | --- |
| R-MAC-01 | must | Capture the active generation, runtime Nix owner, daemon state, build-user identities, channels, Home Manager ownership and package inventory before changes. Preserve unknown historical installer details as unknown instead of assuming a migration is needed. | F2-F4/F6 |
| R-MAC-02 | must | Preserve generation 34 or the actual pre-change active generation and verify its closure and recovery entry points remain available. Record separate recovery for user data and mutable application settings. | F4, I4/I8 |
| R-MAC-03 | must | Build and validate the selected Darwin configuration before activation. After activation, verify login, daemon operation, Zsh/Git, application discovery and launch against a named user-approved application checklist. Verify the existing linkApps behavior. | F1/F3/F5, I2/I8 |
| R-MAC-04 | must | Preserve manually managed Homebrew packages and current no-cleanup/no-auto-update activation behavior. Identify duplicate ownership where it affects application resolution; do not migrate or remove packages as incidental cleanup. | F2/F6, I2/I5 |
| R-MAC-05 | must | Complete Mac acceptance and record its outcome before scheduling the VPS activation. Use a separate two-hour deployment window; stop and recover if critical workflows fail. | I5/I8 |

### VPS

| ID | Priority | Requirement | Source |
| --- | --- | --- | --- |
| R-VPS-01 | must | Inventory all mail-related persistent state and its actual paths before migration. Include mailboxes, delivery queues, Sieve configuration, account credentials, DKIM identity, ACME material and persistent Rspamd/Redis data where present. Record metadata only in project artifacts. | F2/F8, I1/I4/I6 |
| R-VPS-02 | must | Before activation, verify a completed full-system Vultr snapshot or equivalent off-host backup covers the inventory and is consistent enough to restore. Record its identifier, timestamp, coverage and retention. Restore it in an isolated environment without competing public mail delivery, and measure recovery time. Resolve any coverage or consistency gaps. | F8, I4/I6/I7 |
| R-VPS-03 | must | Test independent Vultr console access before the window. Preserve the pre-change system generation and closure, record how to select it through the console, and verify the recorded bootloader/hardware configuration against the deployed VPS before altering it. | F2/F8, I4/I7 |
| R-VPS-04 | must | Measure target closure and build-space needs against available storage while retaining rollback material and mail growth headroom. If space is insufficient, stop and agree a capacity plan before deployment. | F8, I4 |
| R-VPS-05 | must | Build the selected x86_64-linux system before the outage window. Check mailserver and Dovecot data-format and option migrations, and identify whether switching back remains safe after the new software has written state. | F2/F5/F8/F9, I3/I4 |
| R-VPS-06 | must | Establish a baseline and post-change check for SMTP reception, authenticated submission on the used port, IMAPS login and message access, outbound delivery to an external mailbox, aliases, TLS identity, and the domain's mail DNS/authentication records. Use user-controlled test accounts and protect credentials. | F2/F8, I1/I2 |
| R-VPS-07 | must | Preserve SSH and the required IPv4/IPv6 mail and ACME access. Identify the owners and purposes of ports 443 and 12340 and verify host/provider firewall behavior. Do not open extra ports merely because a listener exists. | F8, I1/I2 |
| R-VPS-08 | must | Verify both active and selected generations after deployment and any planned reboot. Require zero failed units, working mail services, and recorded configuration revision matching the approved deployment commit. | F8, I2/I4 |
| R-VPS-09 | must | Limit mail-service interruption to one hour within the separate two-hour VPS window. Use measured recovery duration to set an explicit rollback deadline before activation. Do not begin if recovery cannot fit the accepted outage bound. | I4/I7/I8 |
| R-VPS-10 | must | Preserve or reconcile messages accepted after the snapshot when recovering. Treat generation rollback and full-disk restoration as different operations; do not overwrite newer mail state with an old snapshot without a reviewed reconciliation plan. | I1/I4/I6/I7 |
| R-VPS-11 | should | Identify the authoritative configuration source and document the role of the root nixos-23.05 channel and February 2024 files. Retire legacy entry points only after proving they are unused and preserving recovery material. | F8/F9, I5 |
| R-VPS-12 | should | Document recurring backup ownership, retention, recovery checks and a maintenance cadence so another long deployment gap is detectable. | F1/F8, I2/I4/I5 |

## 5. Constraints and interview decisions

| Decision | User answer and interpretation |
| --- | --- |
| VPS purpose | Mail only; no other stateful workload is expected. Supporting mail services still require state inventory. I1 |
| Healthy | Accepted successful builds, recorded source commits, working Mac workflows and explicit VPS service checks. I2 |
| Release policy | Accepted supported stable inputs and necessary exceptions only. Use intermediate deployments when migration evidence requires them. I3 |
| Recovery | Accepted verified restoration, retained generations and no intentional data loss. This is a prerequisite, not proof of current backups. I4 |
| Scope and sequence | Accepted Mac first, focused compatibility/update work, secrets improvements, documentation and lightweight CI. Defer broad refactors and feature removal. I5 |
| Current backup practice | Full-system Vultr snapshot before major Nix upgrades. Exact snapshot and restore-test evidence is not supplied. I6 |
| Access and downtime | Vultr web console is available according to the user. Up to one hour of mail downtime is acceptable, superseding the proposed 30 minutes. I7 |
| Time budget and Mac validation | Accepted separate two-hour deployment windows, with backup/restore preparation separate; login, Zsh/Git, app discovery and launches must work. Total preparation effort is not capped. I8 |

During this planning session, writes are restricted to `docs/goals/01-checkup/`. No `.nix` file or lockfile may change. No activation, package installation/removal, garbage collection, channel update, Homebrew update, launchctl mutation, commit, push, stash or branch switch is permitted. Builds and large downloads require advance permission. No SSH is permitted without an explicit host and authorization. Secrets must not be printed, decrypted or copied. System stateVersion is not a routine upgrade variable.

These planning restrictions remain in force through delivery of this PRD. Requirements describing deployment and secret migration are specifications for a later authorized session.

## 6. Risks, blast radius, and rollback plan

### Repository and shared inputs

One input change can affect both platforms. Invalid or mutually incompatible module versions can block both builds; careless secret handling can expose credentials. Keep changes reviewable, prove both builds and retain the prior lockfile and source revision in Git history. A Git revert does not by itself revert either deployed host or credential state. [F1/F2/F5, I3-I5]

### Mac

Potential impact includes login shell, application links, Home Manager files, daemon behavior and package selection. Preserve the actual pre-change generation and its complete closure; verify a usable shell and local recovery access. If activation or acceptance fails, restore the previous generation using the verified nix-darwin procedure and repeat the critical workflow checks. Nix rollback does not recover documents or reverse every application data migration, so identify those recovery needs separately. Preserve manual Homebrew state throughout. [F2-F6, I2/I4/I8]

### VPS

Potential impact includes mail interruption, lost or duplicated messages, changed account authentication, broken TLS/ACME, DNS-related delivery failures, exhausted storage, or loss of SSH/boot access. Preserve generation 21 unless the pre-change inventory identifies a newer active baseline. Verify console access and generation selection before deployment. [F2/F8, I1/I4/I7]

Use generation rollback for service/configuration failures only when the new software has not made state incompatible with the old version. If restoration is necessary, use the verified snapshot and the mail reconciliation plan. An isolated restored instance must not send queued mail or receive production mail while the original is active. Restoring an earlier disk image can discard messages accepted since it was taken. [I1/I4/I6/I7; planning risk assessment]

The implementation runbook must set the latest recovery start time as the one-hour outage limit minus measured recovery duration and a stated safety margin. Build and backup preparation happen before the outage. Abort before activation if storage, snapshot, restore, console or rollback-duration prerequisites fail. A two-hour work window does not expand the one-hour mail outage allowance. [I4/I6-I8]

## 7. Success criteria

Each criterion is binary and requires retained evidence. The implementation commit and selected input revisions must be filled in before acceptance; they are not the current audit HEAD by default.

- **SC-01:** Both explicit host toplevel evaluations succeed, flake validation passes, and both native-platform builds succeed for the same approved source revision without unexpected lockfile changes. Retained warnings have an explicit disposition. R-REPO-01/02/03.
- **SC-02:** `darwin-version --configuration-revision` and `nixos-version --configuration-revision` each report the recorded deployment commit; active generation paths and locked inputs are archived. R-REPO-04, R-VPS-08.
- **SC-03:** The selected release set is supported on implementation day and its compatibility/migration review is complete without a routine state-version bump. R-REPO-01/02, R-VPS-05.
- **SC-04:** Current configuration contains no embedded credential values; required services obtain protected runtime secrets, recovery is documented, and no secret value appears in the PR or validation logs. R-REPO-05.
- **SC-05:** The named Mac acceptance checklist passes after activation; Nix daemon operation and application discovery work, and manual Homebrew packages are preserved. R-MAC-01/03/04.
- **SC-06:** Mac recovery material is available and Mac acceptance is recorded before VPS activation begins. R-MAC-02/05.
- **SC-07:** Before VPS activation, the state inventory, completed snapshot/backup record, isolated restore result, console test and capacity assessment all pass their documented checks. R-VPS-01/02/03/04.
- **SC-08:** Before and after the VPS change, controlled external mail tests demonstrate reception, authenticated submission, outbound delivery, IMAPS access, alias behavior and valid TLS/DNS configuration. SSH and intended firewall access pass; no unexplained port is opened. R-VPS-06/07.
- **SC-09:** The VPS reports zero failed units and the intended active/selected generation after deployment and any planned reboot. R-VPS-08.
- **SC-10:** Measured mail downtime is at most 60 minutes. The recovery deadline was recorded before activation, and the mailbox/queue reconciliation check finds no unexplained loss of accepted messages. R-VPS-09/10.
- **SC-11:** CI explicitly evaluates both hosts, the README matches actual paths, and deployment/recovery documentation identifies authoritative configuration sources and backup ownership. R-REPO-06/07, R-VPS-11/12.

These are completion criteria for implementation, not claims that this planning session has passed them.

## 8. Out of scope

- Fixes, builds, deployments, dependency updates and secret migration during this planning session.
- Broad module restructuring, unrelated package migrations and removal of currently used applications.
- Changing the mail provider, introducing additional VPS workloads or redesigning mail domains and accounts.
- Routine state-version changes, automatic deletion of old generations, or garbage collection as an assumed prerequisite.
- Replacement of the Mac Nix installer or blanket build-user UID changes without a demonstrated compatibility requirement.
- Assuming recovery from a snapshot is equivalent to generation rollback or that it guarantees zero lost mail.
- Detailed user stories and executable validation plans; these are the next session's deliverables.

## 9. Open questions

These questions are retained as requirements for implementation discovery rather than inferred answers.

| Question | Resolution gate |
| --- | --- |
| What completed Vultr snapshot will be used, what does it cover, and when was restoration last demonstrated? How long does restoration take? | R-VPS-02/09; before activation |
| What are the actual mail-state paths, backup retention and consistency guarantees, and how will post-snapshot mail be preserved? | R-VPS-01/02/10/12; before activation |
| Which exact Mac applications and user workflows are essential? What user-data recovery exists for mutable application state? | R-MAC-02/03; before Mac activation |
| What mutually compatible stable input revisions will be selected, and are any intermediate migrations necessary? | R-REPO-01/02, R-VPS-05; before target build |
| What errors or deprecations appear when evaluation runs in an environment that permits normal Nix store/cache writes? | R-REPO-03; before activation |
| Can either deployment be tied to a source commit? What was the active source for VPS generation 21? | R-REPO-04/07, R-VPS-11; preserve uncertainty if historical proof is unavailable |
| What owns the Mac's Home Manager generation 20 and current Nix runtime? What do root Mac and login-user VPS channels contain? | R-MAC-01, R-VPS-11; before ownership/source cleanup |
| What owns VPS listeners 443 and 12340, and what does Vultr's firewall permit? | R-VPS-07; before network changes |
| What runtime secret mechanism fits existing recovery/access arrangements, and which credentials require rotation? | R-REPO-05; before credential migration |
| Are two-hour deployment windows sufficient once builds and recovery rehearsals are measured? | R-MAC-05, R-VPS-09; reschedule preparation rather than weaken the one-hour outage limit |

Network activity during discovery consisted of official-release web research and Homebrew's attempted API/cache access. No successful Nix source download was observed. No SSH was run. See the archived `evidence-status.txt` record in [EVIDENCE.md](EVIDENCE.md) for the audit integrity comparison and Git status.
