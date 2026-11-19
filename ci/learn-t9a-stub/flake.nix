# CI stand-in for the private learn-t9a flake input, which GitHub Actions cannot fetch.
# CI passes `--override-input learn-t9a path:./ci/learn-t9a-stub`; nixpkgs follows this
# repo's lock. The real app is built locally before activation (docs/t9a-tutor.md).
{
  description = "CI stub for learn-t9a";

  outputs = { nixpkgs, ... }: {
    packages.x86_64-linux.app =
      nixpkgs.legacyPackages.x86_64-linux.writeShellScriptBin "t9a-tutor" ''
        echo "learn-t9a CI stub, not the real app" >&2
        exit 1
      '';
  };
}
