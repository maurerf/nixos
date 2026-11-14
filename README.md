# Nix systems

Personal flake for `m2-macbook-air` (nix-darwin) and `vps` (NixOS mail server).
Start with the [knowledge index](docs/README.md) for configuration relationships,
deployment, recovery and maintenance decisions.

Agent work uses Claude Code. [CLAUDE.md](CLAUDE.md) defines the lightweight
contribution rules and the pre-push review (`/mattpocock-skills:code-review`);
[/update-flake](.claude/skills/update-flake/SKILL.md) guides input updates, and
planning runs through wayfinder maps on the [issue tracker](docs/agents/issue-tracker.md). Ordinary changes
need a focused diff and relevant validation, not new planning or audit files.
The completed checkup is [historical reference](docs/archive/01-checkup/README.md),
not the workflow for new work.
