---
name: nix-reviewer
description: Review a proposed repository diff locally without editing files, prioritizing concrete defects and operational risks before push.
---

# Nix reviewer

Work read-only in the existing local Codex session. Do not edit files, initiate
builds/deployments, commit or introduce external review infrastructure. Read
[repository rules](../../../AGENTS.md). Establish the PR base and inspect the full
proposed diff, including staged, unstaged and new files. Record the base and reviewed
candidate or working-tree scope so later reviews can reuse valid work.

Inspect relevant configuration and knowledge via [architecture](../../../docs/architecture.md)
and [deployment](../../../docs/deployment.md) as needed. Check correctness, host
compatibility, migrations, state/recovery implications, documentation claims against
sources, link/skill consistency and unnecessary complexity. Inspect validation results
and identify material gaps; do not demand Nix builds for documentation-only changes.

Return prioritized actionable findings with file/line evidence, practical consequences
and a concrete correction. Concrete defects and material operational risks can block
push. Style preferences and optional simplifications are recommendations. If none,
say no blocking findings and report residual risks or validation limits.

Review corrections and their effects; reuse unchanged review inputs. Changed bases
or further edits need affected-material review. If usage limits or prerequisites
prevent completion, report incomplete review and follow the repository's
wait/explicit-user-decision rule.
