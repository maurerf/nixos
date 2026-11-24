# CI stand-in for the private home flake input, which GitHub Actions cannot fetch.
# CI passes `--override-input home path:./ci/home-stub`. The real module registers
# the pinned Pocock skills in Claude Code's settings and is exercised locally.
{
  description = "CI stub for home";

  outputs = _: {
    homeManagerModules.default = { };
  };
}
