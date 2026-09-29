# Nix systems

Personal flake for `m2-macbook-air` (nix-darwin) and `vps` (NixOS mail server).
Start with the [knowledge index](docs/README.md) for configuration relationships,
deployment, recovery and maintenance decisions.

For Codex, use the repository skills:

- [$nix-engineer](.agents/skills/nix-engineer/SKILL.md): scoped configuration changes and validation.
- [$update-flake](.agents/skills/update-flake/SKILL.md): requested input updates through deployment.
- [$nix-reviewer](.agents/skills/nix-reviewer/SKILL.md): read-only local review before pushing.
- [$docs-cleanup](.agents/skills/docs-cleanup/SKILL.md): documentation corrections and consolidation.

[AGENTS.md](AGENTS.md) defines the lightweight contribution rules. Ordinary changes
need a focused diff and relevant validation, not new planning or audit files.
The completed checkup is [historical reference](docs/archive/01-checkup/README.md),
not the workflow for new work.
