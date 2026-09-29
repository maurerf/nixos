# Repository rules

Read the configuration and [knowledge](docs/README.md) relevant to the task;
do not load the entire knowledge base or archive by default.

- Keep reusable settings in `modules/`, host settings in `machines/` and
  `profiles/`, and Linux-only modules out of Darwin imports. Follow existing
  two-space Nix style; avoid unrelated formatting.
- Preserve unrelated work. Use a feature branch and focused commits/PRs.
  Never add credentials or private keys; preserve state versions unless an
  intentional migration is requested and documented.
- Use [$nix-engineer](.agents/skills/nix-engineer/SKILL.md) for scoped Nix work
  and [$update-flake](.agents/skills/update-flake/SKILL.md) for input updates.
  Validate affected hosts per [deployment](docs/deployment.md); report platform
  limitations. Documentation-only changes need link/content/diff checks, no builds.
- Update directly affected knowledge as part of completing a change. Reserve
  broader consolidation for [$docs-cleanup](.agents/skills/docs-cleanup/SKILL.md).
  Nix is authoritative for declarations; knowledge owns context and procedures;
  skills own task workflows. Date/source runtime observations separately.
- Keep planning and evidence proportional to actual risk. No PRD, stories,
  separate validation document or command log is required by default. Summarize
  checks in the PR; retain detailed evidence only when needed for recovery or
  consequential decisions. Keep temporary tooling outside the repository.
- Follow [deployment approval and recovery boundaries](docs/deployment.md#deployment).
  Historical waivers grant no permission for future work.

## Local review before push

Before the first push, run [$nix-reviewer](.agents/skills/nix-reviewer/SKILL.md)
locally against the full proposed PR diff. Resolve blocking findings and review
corrections and their effects. Reuse review while relevant inputs remain unchanged;
further changes or a changed base require review of affected material, not a
mechanical repeat of all checks. If usage limits or missing prerequisites prevent
completion, report review as incomplete and wait for review availability or an
explicit user decision to proceed.

This is an agent convention using the existing local Codex session/authentication.
Do not add pre-push hooks, API credentials, GitHub AI review or required AI status
checks. Preserve the deterministic [Nix CI](.github/workflows/checkup.yml).
