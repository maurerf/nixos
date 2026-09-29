# Decisions and limitations

[Knowledge index](README.md)

## Continuing decisions

- Prefer compatible supported stable inputs, sharing nixpkgs; use unstable packages
  only for a demonstrated need. The current pins are declarations in
  [flake.nix](../flake.nix) and [flake.lock](../flake.lock), not a claim of ongoing
  upstream support. Recheck release/migration compatibility for each update.
  [Original rationale](archive/01-checkup/EVIDENCE.md#interview-decisions).
- Keep manual Homebrew ownership separate from Nix apps. Disabled Spotify was
  retained because no approved use or working replacement was established. The
  explicit Dovecot `fileinto` workaround was removed because Dovecot 2.4 enables it
  and the old option failed evaluation. Reassess changes against actual use, not
  cosmetic cleanup. [Source preparation](archive/01-checkup/EVIDENCE.md#release-and-migration-matrix).
- Keep the Postfix outbound IPv4 override: the old source's Gmail delivery failed
  with `5.7.25` and an IPv6 sender without matching reverse/forward identity.
  Target delivery and SPF/DKIM/DMARC later passed. Changing that route requires
  sender identity and external delivery checks, not just reachability.
  [Candidate rationale](archive/01-checkup/EVIDENCE.md#operator-authorized-candidate-source-and-renewed-validation).
- Preserve original Mac generation 34, accepted Mac generations 35/36, original VPS
  generation 21 and accepted VPS generation 22 with their closures until an explicit
  retirement decision. Do not run GC or delete generations as incidental maintenance.
  Automatic GC evaluated false during the checkup; external cleanup was not proved
  absent. [Retention decision](archive/01-checkup/EVIDENCE.md#legacy-source-investigation-and-maintenance-decision-2026-09-29t090807z091606z).
- The operator's ongoing [snapshot and monthly/quarterly maintenance policy](vps-recovery.md#maintenance-and-preparation)
  remains applicable. Legacy entry points were retired with protected recovery copies;
  use [the canonical recovery procedure](vps-recovery.md#retained-legacy-source-recovery).

## Historical exceptions

These decisions applied to their recorded deployment scope, including explicitly
recorded downstream checkup acceptance. They grant no standing permission for a
future change. Establish fresh readiness or ask for a new scoped decision.

| Recorded exception | Meaning and remaining limitation |
| --- | --- |
| [Mac, 2026-09-26](archive/01-checkup/EVIDENCE.md#operator-revision-and-boundary) | Full backup and independent recovery-console test waived. Operator reported iCloud documents accessible elsewhere and offline Monero recovery material; neither was restore-tested. Some local app settings were accepted as disposable. Critical failure required a separate recovery decision, not automatic rollback. |
| [VPS snapshot, 2026-09-27](archive/01-checkup/EVIDENCE.md#us-05-snapshot-based-recovery-readiness-2026-09-27) | Isolated restore, live-capture consistency, measured duration and post-snapshot reconciliation waived. Possible newer-mail loss explicitly accepted for that checkup; zero loss and recovery within an hour were never proved. |
| [IPv6, 2026-09-28](archive/01-checkup/EVIDENCE.md#layer-1-resolution-and-explicit-ipv6-deferral) | External IPv6 SSH/mail/ACME/AAAA checks deferred; IPv4 acceptance does not establish IPv6 health. |
| [Old-source outbound, 2026-09-28](archive/01-checkup/EVIDENCE.md#operator-authorized-candidate-source-and-renewed-validation) | Failed Gmail baseline explicitly waived for the corrected candidate; target external delivery/authentication still required and later passed. |
| [D-Bus transition, 2026-09-28](archive/01-checkup/EVIDENCE.md#us-06-staged-vps-test-and-d-bus-failure-2026-09-28t194934z195928z) | `test` exited 4 and remains a failed step. A separately approved pinned `boot` and reboot superseded the planned `switch`; postboot checks passed. This was not a successful staged test or permission to reboot after any failure. |

The checkup also left historical installer lineage and original full deployment
source unknown. Mac Chromium cask inventory failed on `command_wrapper`; targeted
inventory and operator-confirmed application launches were accepted instead.
Bootloader declaration equivalence was not established merely from GRUB metadata.
These are unresolved historical limitations, not new defects found by this restructuring.
[Baseline exceptions](archive/01-checkup/EVIDENCE.md#us-01-completion-and-retained-exceptions-2026-09-26).

## Deployment provenance, not today's status

At the final 2026-09-29T09:56Z checkpoint, agent checks and operator transcripts
reported both hosts on runtime source `3f189047eab2f56735f104c822778818662e19c1`,
lock hash `sha256-SXw/9jciRkqk8p/Eb4pttg8U33OpUH8J8GLKzvfEDZ4=`.
The earlier accepted Mac source was `a6478f68937add6ef8026555d2a33ddd323ccb46` with
that same lock. Final Mac generation 36 aligned provenance after a VPS-only source
fix; VPS generation 22 had already been deployed. Native builds and exact output
paths are in the [source/alignment evidence](archive/01-checkup/EVIDENCE.md#source-mac-alignment-and-accepted-host-checks-2026-09-29t090630z091536z).

Later closeout documentation commit `a52e460` and merge `aade9a3` are not runtime
source commits. The [final result](archive/01-checkup/EVIDENCE.md#us-07-ordered-layer-and-final-acceptance-result-2026-09-29t095603z095607z)
records healthy services, accepted Mac workflows and retained recovery generations;
VPS external mail acceptance reuses the unchanged target's 2026-09-28 postboot checks.
The conservative interruption bound was 7 minutes 9 seconds and six controlled
inbound IDs were accounted for. Neither this nor a merged PR proves today's state
or preservation of every post-snapshot message. No hosts were inspected during the
documentation restructuring.
