# Issue tracker: GitHub

[Knowledge index](../README.md)

Issues, wayfinder maps and their tickets live as GitHub issues in
`maurerf/nixos`. Use the `gh` CLI for every operation; inside this clone it
infers the repository. Agent sandboxes must allow network access for `gh`.

## Conventions

- **Create**: `gh issue create --title "..." --label "..." --body-file <file>`;
  write multi-line bodies to a file outside the repository (or a heredoc).
- **Read**: `gh issue view <n> --comments`.
- **List**: `gh issue list --state open --json number,title,labels,assignees`
  with `--label`/`--state` filters.
- **Comment**: `gh issue comment <n> --body "..."`.
- **Labels**: `gh issue edit <n> --add-label "..."` / `--remove-label "..."`.
- **Close**: `gh issue close <n>`.

Issues and pull requests share one number space: resolve a bare `#42` with
`gh pr view 42`, falling back to `gh issue view 42`. External pull requests are
not a request surface.

When a skill says "publish to the issue tracker", create an issue. When it says
"fetch the relevant ticket", run `gh issue view <n> --comments`.

## Wayfinding operations

Used by `wayfinder`. The labels `wayfinder:map`, `wayfinder:research`,
`wayfinder:prototype`, `wayfinder:grilling` and `wayfinder:task` already exist.

- **Map**: one issue labelled `wayfinder:map` whose body holds Destination,
  Notes, Decisions so far, Not yet specified and Out of scope. Edit it by
  fetching the body (`gh issue view <map> --json body --jq .body > <file>`),
  changing the file and writing it back (`gh issue edit <map> --body-file <file>`);
  other sessions may edit it concurrently, so re-fetch right before writing.
- **Ticket**: a GitHub sub-issue of the map, labelled `wayfinder:<type>`, body
  `## Question` plus a closing `Part of the map: #<map>` line. Attach it with
  `gh api -X POST repos/maurerf/nixos/issues/<map>/sub_issues -F sub_issue_id=<id>`,
  where `<id>` is the child's numeric database id
  (`gh api repos/maurerf/nixos/issues/<n> --jq .id`), not its number or `node_id`.
- **Blocking**: native issue dependencies, wired after all tickets exist:
  `gh api -X POST repos/maurerf/nixos/issues/<blocked>/dependencies/blocked_by -F issue_id=<blocker-id>`
  with the blocker's database id. List with
  `gh api repos/maurerf/nixos/issues/<n>/dependencies/blocked_by`.
  `issue_dependencies_summary.blocked_by` counts open blockers only.
- **Frontier**: open sub-issues with no open blocker and no assignee, first in
  map order wins:
  `gh api --paginate repos/maurerf/nixos/issues/<map>/sub_issues --jq '.[] | select(.state == "open" and (.assignees | length) == 0 and .issue_dependencies_summary.blocked_by == 0) | "\(.number) \(.title)"'`.
- **Claim**: `gh issue edit <n> --add-assignee @me`, the session's first write.
  Every agent session acts as `maurerf`, so an assignee shows that a ticket
  is taken, not which session took it.
- **Resolve**: post the answer as a resolution comment, `gh issue close <n>`,
  then add one line (linked name and gist) to the map's Decisions so far.
  When the map's Notes carry an execution override, the comment also links the
  merged pull request.
- **Research assets**: findings go on a throwaway, pushed `research/<name>`
  branch (never merged); the resolution comment links the file on that branch.
