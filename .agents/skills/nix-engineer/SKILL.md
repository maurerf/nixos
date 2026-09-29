---
name: nix-engineer
description: Implement scoped Nix configuration changes and validate affected hosts; use update-flake for input update workflows.
---

# Nix engineer

Read [repository rules](../../../AGENTS.md), relevant Nix files and
[architecture](../../../docs/architecture.md). Identify affected hosts through imports.
Make the smallest useful change, preserving requested scope and unrelated work.

Select evaluation and affected-host builds from [validation](../../../docs/deployment.md#select-checks);
report unavailable native platforms. For services, state, access or deployment,
consult applicable [deployment](../../../docs/deployment.md),
[VPS recovery](../../../docs/vps-recovery.md) and [decisions](../../../docs/decisions.md)
sections. Configuration edits do not imply activation approval.

Update directly affected knowledge. Summarize changes, validation and limitations
in the PR; ordinary package changes need no planning/audit files. Use `$nix-reviewer`
before pushing under repository rules. Route input updates to `$update-flake` and
broad documentation consolidation to `$docs-cleanup`.
