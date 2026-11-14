---
name: update-flake
description: Guide requested flake input updates through compatibility research, lock review, builds, deployment preparation and explicitly approved activation.
---

# Update flake

Follow [repository rules](../../../CLAUDE.md) and read applicable
[decisions](../../../docs/decisions.md). Establish requested input and host scope.
Do not update all inputs or deploy extra hosts by default; explain shared-input
effects when scope cannot isolate them.

Research current official release/migration guidance for selected inputs and actual
deployed versions, citing dated sources. Check nixpkgs, nix-darwin, Home Manager and
mailserver compatibility as applicable, including state formats, removed options and
required intermediate upgrades. Historical checkup research is not current support
evidence.

Update requested pins (for example `nix flake update INPUT`); review direct/transitive
lock changes and follows relationships, explaining unavoidable changes. Make any
needed compatibility fixes as scoped Nix changes, then run the
[evaluations and native builds](../../../docs/deployment.md#select-checks) and the
pre-push review. Tie review/build reuse to unchanged relevant inputs.

Prepare using [host procedures](../../../docs/deployment.md) and applicable
[VPS recovery](../../../docs/vps-recovery.md). Record clean source commit, lock hash,
outputs, closure comparison, recovery generation, migrations and timing. Keep later
documentation commits distinct from runtime source. Missing native builds or readiness
mean preparation is incomplete. A preparation-only request stops before activation.

Before activating **each production host**, obtain explicit user approval for the
concrete candidate and target host. Present build results, relevant changes, risks,
recovery route and timing constraints before asking. A general input-update request
grants no activation approval; changed candidates/routes need renewed approval.
Apply the linked procedure within that approval, run post-activation checks and
record dated sanitized outcomes. Stop failures for assessment; do not improvise
recovery or inherit historical waivers.

Update directly affected knowledge and report remaining work.
