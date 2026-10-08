# Homebrew migration assessment and handoff

[Knowledge index](README.md) · [Architecture](architecture.md) · [Deployment](deployment.md)

## Intent and authorization

The user requested an A–F assessment of moving every explicitly installed
Homebrew package to Nix on their M2 Mac. The assessment was delivered; on
2026-10-08 the user asked to persist the plan and context for a later return.
Migration has **not** been requested or approved. No packages, configuration,
lockfiles, or runtime state were changed as part of this assessment.

Grades assume actual Nix packages, not simply declaring Homebrew casks through
nix-darwin. A means straightforward; B minor adjustments; C moderate work;
D substantial work; E poor fit; F impractical. Grades include maintenance effort
and are estimates, not build or launch certifications.

## Evidence and scope

Source: live local Homebrew inventory and read-only Nix evaluation during the
2026-10-05 conversation, saved on 2026-10-08. Refresh before implementation.

- Target: `m2-macbook-air`, `aarch64-darwin`.
- Homebrew: `/opt/homebrew/bin/brew`.
- Explicit inventory: **21 formulas** with `installed_on_request: true` in
  `/opt/homebrew/Cellar/*/*/INSTALL_RECEIPT.json`, plus **7 installed casks**.
- `brew leaves` returned 19 formulas, omitting explicitly requested `autoconf`
  and `pkgconf` because other installed packages depend on them. Do not use
  leaves alone to reconstruct the requested scope.
- Commands included `HOMEBREW_NO_AUTO_UPDATE=1 brew leaves`,
  `brew list --formula --versions`, `brew list --cask --versions`, and
  `brew info --json=v2 --installed --formula` / `--cask` with the same environment.
  Formula receipts provided installation intent.
- The full cask listing succeeded. The historical Chromium `command_wrapper`
  inventory error in the checkup archive did not reproduce. Current casks also
  differ from that historical inventory; do not restore removed entries from it.
- Evaluated pinned nixpkgs revision:
  `f5c082a40f7571c266e74e80ae2e68aadd8a9fc7` from `flake.lock`.
  Its local source was
  `/nix/store/q6zfrswar6d0fkihnxc198vmkdxrmvq5-source`.
- All 19 formulas with identified equivalents evaluated to derivation paths,
  as did Claude Code and OpenSCAD. No builds, cache-availability checks, app
  launches, or consuming-project tests were performed.
- Evaluation used `system = "aarch64-darwin"` and `config.allowUnfree = true`,
  matching the host policy. An initial Claude Code evaluation without that
  policy failed; the corrected evaluation succeeded. This is not a package bug.
- Nix daemon access required sandbox escalation. Successful evaluations were
  read-only; no activation or package installation was performed.

## Formula assessment

Versions below are the observed installed Homebrew versions, not current release
claims. Nix version differences refer only to the revision above.

| Formula | Installed | Grade | Nix route and remaining work |
| --- | --- | :---: | --- |
| `autoconf` | 2.72 | A | `autoconf`; routine migration. |
| `autogen` | 5.18.16_3 | A | `autogen`; same upstream version. |
| `automake` | 1.18.1 | A | `automake`; same version. |
| `binutils` | 2.45.1 | B | `binutils`; check command naming and precedence against Apple tools. |
| `boost` | 1.90.0 | B | `boost` in project development environments; pinned default is 1.89.0. |
| `ccache` | 4.12.2 | B | `ccache`; check compiler integration and cache configuration. |
| `cmake` | 4.2.1 | B | `cmake`; pinned default 4.1.6 may not meet all project requirements. |
| `coreutils` | 9.9 | B | `coreutils`; check Homebrew `g` prefixes and PATH ordering. |
| `doxygen` | 1.15.0 | A | `doxygen`; routine migration. |
| `expat` | 2.7.3 | B | `expat`; expose headers/libraries through project development environments. |
| `ffmpeg` | 8.0.1 | B | `ffmpeg` or appropriate variant; verify required codecs and hardware acceleration. |
| `graphviz` | 14.1.1 | B | `graphviz`; pinned default 12.2.1 requires feature/rendering comparison. |
| `hidapi` | 0.15.0 | B | `hidapi`; same version, check build discovery and device access. |
| `libpgm` | 5.3.128 | C | No package found; custom derivation likely required, including Homebrew's ARM patch. |
| `libunwind-headers` | 201 | C | No exact equivalent; inspect consuming project before choosing SDK headers or custom packaging. |
| `libusb` | 1.0.29 | B | `libusb1`; same version, adjust project dependency discovery. |
| `miniupnpc` | 2.3.3 | B | `miniupnpc`; same version, adjust library paths in consuming projects. |
| `pkgconf` | 2.5.1 | B | `pkgconf` exists; Nix project builds generally use the `pkg-config` wrapper. |
| `protobuf` | 33.2 | B | `protobuf`; pinned default 34.1 requires matching compiler, generated code and runtime. |
| `tor` | 0.4.8.21 | B | `tor`; CLI easy, but any existing background service requires configuration and launchd migration. Service use was not inspected. |
| `yt-dlp` | 2025.12.8 | A | `yt-dlp`; check FFmpeg integration. |

For libraries, a project `devShell` is usually the useful migration target.
Adding libraries only to `home.packages` does not reproduce Homebrew's global
include/library discovery. The actual consuming projects and their required
versions have not been identified. Explicit installation metadata does not prove
that a package is still used.

The installed Homebrew recipe for `libpgm` uses OpenPGM release `5-3-128`,
Autoconf/Automake/Libtool, an ARM fix at upstream commit
`8d507fc0af472762f95da44036fb77662ff4cd2a`, and a pkg-config filename adjustment.
The recipe can be inspected under its Cellar version's `.brew/libpgm.rb`.

Homebrew's `libunwind-headers` recipe installs public and internal headers from
Apple's `libunwind-201`. Nix's Darwin `libunwind` only creates a compatibility
pkg-config file and relies on libSystem for linking; it is not a replacement
for that complete header bundle. See pinned
`pkgs/os-specific/darwin/by-name/li/libunwind/package.nix`.

## Cask assessment

| Cask | Installed | Grade | Nix route and remaining work |
| --- | --- | :---: | --- |
| `chromium` | latest | D | Pinned `chromium` supports Linux only. Custom macOS binary package and ongoing browser update maintenance required. `latest` does not establish the installed binary version. |
| `claude` | 0.14.10,fe3f5688c1c2a4b648d1bf6d9784d62ef9fc336a | C | No `claude-desktop` attribute. Packaging the official Mac app is plausible; download pinning, updater behavior and integration remain untested. |
| `claude-code` | 2.0.69 | A | Existing Apple Silicon `claude-code` package evaluates; pinned version 2.1.223. Package disables its self-updater so Nix owns updates. |
| `monero-wallet` | 0.18.4.5 | D | `monero-gui` 0.18.5.2 fails evaluation through `monero-cli` 0.18.5.1, whose metadata supports Linux and excludes aarch64-darwin. Package official Mac binary or repair source build. |
| `openscad` | 2021.01 | C | `openscad` 2021.01 evaluates and explicitly installs a Darwin `.app`; native build and launch still needed. Historical repo evidence records Qt5 trouble. |
| `steam` | 4.0 | D | Existing Nix package provides no usable macOS route. Custom Mac bootstrap must accommodate writable updater and app layout. |
| `tor-browser` | 15.0.3 | D | Pinned `tor-browser` supports i686/x86_64 Linux only. Custom official Mac bundle packaging and update/data behavior need work. |

Do not infer working support solely from `meta.platforms`: Monero GUI advertises
broad support but its dependency fails; Steam's permissive/empty metadata also
did not produce a usable derivation. `tor-browser-bundle-bin` is a throwing
renamed alias; use `tor-browser` when querying.

Relevant primary sources:

- [Pinned nixpkgs tree](https://github.com/NixOS/nixpkgs/tree/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7), especially `pkgs/by-name/{cl/claude-code,mo/monero-gui,mo/monero-cli,op/openscad,to/tor-browser,st/steam-unwrapped}/package.nix` and `pkgs/applications/networking/browsers/chromium/browser.nix`.
- [Steam Darwin dependency issue](https://github.com/NixOS/nixpkgs/issues/411274).
- [Claude Desktop package request](https://github.com/NixOS/nixpkgs/issues/366213); external Linux repackaging is not evidence of a working Mac package.
- Historical OpenSCAD migration/reversal is recorded in
  [checkup evidence](archive/01-checkup/EVIDENCE.md) around commits
  `baa80bd5f8b5ca2b0834239a4a0ac06b68482645` and
  `4d2ef692a57011f6dc49e20ee2d6dd7444e71d6b`; it is not a fresh build result.

## Recommended sequence when resumed

1. Refresh explicit Homebrew inventory, installed versions, current lock revision,
   and package ownership. Read the current host/profile and relevant knowledge;
   this snapshot must not override newer Nix declarations or runtime evidence.
2. Confirm which migration scope the user now wants. The recommendation was to
   start with A-grade packages: Autoconf, AutoGen, Automake, Doxygen, yt-dlp and
   Claude Code. OpenSCAD is the strongest next GUI candidate for a build trial.
3. Identify consuming projects before migrating development libraries. Move
   their toolchains and dependencies together into development environments;
   check minimum versions and avoid accidental downgrades.
4. Use the `nix-engineer` skill for implementation on a focused feature branch.
   Put host package declarations in `profiles/home-darwin.nix`, reusable settings
   in `modules/`, and any host settings in `machines/m2-macbook-air.nix`.
5. Evaluate and build the affected Darwin host with locked inputs, then prepare
   command/app acceptance checks, ownership transition and recovery. Metadata
   and derivation evaluation alone do not establish successful builds or launches.
6. Follow [deployment approval boundaries](deployment.md#deployment) before
   activation. Obtain appropriate authorization for removing Homebrew ownership;
   preserve app data and verify Nix replacements before removal. Assess each
   custom GUI package separately instead of assuming an immutable app bundle
   accepts the vendor's updater behavior.
7. Before first push, run the repository's `nix-reviewer` workflow against the
   full proposed diff. Update directly affected docs with dated results.

At assessment time, `machines/m2-macbook-air.nix` enabled Homebrew with empty
`brews`/`casks`, `cleanup = "none"`, and updates/upgrades disabled on activation.
`profiles/home-darwin.nix` already enabled `targets.darwin.linkApps` and declared
other Nix GUI apps. Keep those ownership details in mind when planning PATH and
application discovery changes; consult the current files for authoritative values.

This is a completed assessment with deferred implementation, not an active
deployment plan or authorization to migrate packages.
