# Repository rules

Read the configuration and [knowledge](docs/README.md) relevant to the task;
do not load the entire knowledge base or archive by default.

- Keep reusable settings in `modules/`, host settings in `machines/` and
  `profiles/`, and Linux-only modules out of Darwin imports. Follow existing
  two-space Nix style; avoid unrelated formatting.
- Preserve unrelated work. Use a feature branch and focused commits/PRs.
  Never add credentials or private keys; preserve state versions unless an
  intentional migration is requested and documented.
- For Nix changes, read [architecture](docs/architecture.md), find the affected
  hosts through imports and make the smallest useful change. Validate them per
  [select checks](docs/deployment.md#select-checks) and report unavailable
  native platforms. A configuration edit never implies activation approval.
- Use [/update-flake](.claude/skills/update-flake/SKILL.md) for input updates.
  Documentation-only changes need link/content/diff checks, no builds.
- Update directly affected knowledge as part of completing a change; keep one
  canonical home per fact and link instead of copying. Nix is authoritative for
  declarations; knowledge owns context and procedures; skills own task
  workflows. Date/source runtime observations separately.
- When correcting or consolidating documentation, preserve historical records,
  meaningful decisions, failures and scoped waivers; never turn an old exception
  into standing approval. Ask when a material claim cannot be established, and
  do not inspect production merely to refresh documentation.
- Keep planning and evidence proportional to actual risk. No PRD, stories,
  separate validation document or command log is required by default. Summarize
  checks in the PR; retain detailed evidence only when needed for recovery or
  consequential decisions. Keep temporary tooling outside the repository.
- Follow [deployment approval and recovery boundaries](docs/deployment.md#deployment).
  Historical waivers grant no permission for future work.

## Agent skills

### Issue tracker

GitHub issues in `maurerf/nixos`, including wayfinder maps as sub-issue trees
with native blocking. See [issue tracker](docs/agents/issue-tracker.md).

## Review before push

Before the first push, run `/mattpocock-skills:code-review` against `main` (the
full proposed PR diff). Its Standards axis uses this file, including the
checklist below; its Spec axis uses the originating issue, so reference it in
commit messages. The review only inspects: no edits, builds, deployments or
commits by its agents. Record the reviewed base and candidate commit in the PR
so later reuse has a basis. Resolve blocking findings and review corrections
and their effects. Reuse review while relevant inputs remain unchanged; further changes or
a changed base require review of affected material, not a mechanical repeat. If
the review cannot complete, report it as incomplete and wait for it or for an
explicit user decision to proceed.

Review checklist (hard standards; Fowler smells are judgement calls on Nix):

- Every affected host was identified and validated per
  [select checks](docs/deployment.md#select-checks); missing native builds are
  reported, not implied.
- Linux-base changes leave the VPS toplevel `drvPath` unchanged unless a VPS
  change is intended. `configurationRevision` comes from `self.rev`, so compare
  only trees with identical revision metadata, e.g. the candidate and a
  disposable worktree of `main`, both with an uncommitted change.
- No credentials, private keys or secrets; state versions unchanged unless a
  documented migration.
- Services, state, access or deployment changes are checked against
  [deployment](docs/deployment.md), [VPS recovery](docs/vps-recovery.md) and
  [decisions](docs/decisions.md): migrations, recovery route, approval needs.
- Documentation claims match the Nix sources; links and anchors resolve;
  directly affected knowledge is updated.
- No unnecessary complexity or scope beyond the issue.

Do not add pre-push hooks, API credentials, GitHub AI review or required AI
status checks. Preserve the deterministic [Nix CI](.github/workflows/checkup.yml).
