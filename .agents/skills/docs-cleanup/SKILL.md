---
name: docs-cleanup
description: Correct stale repository guidance, consolidate duplication and repair Markdown navigation while preserving historical evidence.
---

# Documentation cleanup

Read [the index](../../../docs/README.md) and relevant pages. Compare claims with
Nix declarations and dated evidence. Keep one canonical home for each maintained
fact/procedure; link instead of copying. Keep README useful to the maintainer,
AGENTS short, knowledge contextual and skills task-oriented.

Correct stale guidance, consolidate duplication and repair moved links/anchors.
Preserve original historical records, meaningful decisions, failures and scoped
waivers. Distinguish dated observations from today's runtime and never turn old
exceptions into standing approval. Ask when a material claim cannot be established;
do not inspect production merely to refresh documentation.

Create pages/supporting files only for demonstrated needs. Ordinary corrections need
no PRD, stories, audit log or Nix builds. Validate relative links, anchors, content
consistency and the full Git diff. Preserve unrelated work and keep temporary tools
outside the repository. Use `$nix-reviewer` before pushing under
[repository rules](../../../AGENTS.md).
