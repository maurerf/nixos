# Self-updating Claude Code and Codex on NixOS

[Knowledge index](README.md) · [Architecture](architecture.md) · [Deployment](deployment.md)

Research for [issue #33](https://github.com/maurerf/nixos/issues/33), part of the
[`desktop-pc` map](https://github.com/maurerf/nixos/issues/21). Researched
2026-11-10 from primary sources: the two install scripts as served that day,
the release binaries they download, vendor docs, upstream source and nixpkgs.
**Nothing was installed or executed.** Release binaries were downloaded to a
temporary directory on Windows and only their ELF headers and strings were
read. Claims are marked *sourced* (stated by the linked source), *inspected*
(read from a downloaded release file) or *inferred* (reasoning that the VM dry
run must confirm).

Versions inspected: Claude Code **2.1.322** (`latest` channel; `stable` was
2.1.311) and Codex **0.167.0** (`rust-v0.167.0`, published 2026-11-06).

## Answer

**Both official self-updating installs are workable on NixOS 26.05 x86_64, and
`programs.nix-ld.enable = true;` with the default library set is enough for the
core CLIs and their updaters.**

- **Claude Code** downloads a glibc-linked executable whose loader is
  `/lib64/ld-linux-x86-64.so.2` and whose only shared-library dependencies are
  glibc's own. It does not start on NixOS without `nix-ld`; with `nix-ld` and
  no extra libraries it has everything it links against. Every version the
  updater fetches is the same glibc build, so updates keep working.
- **Codex** downloads a static musl package: `codex`, its helpers, the bundled
  `rg` and the bundled `bwrap` have no ELF interpreter and no shared-library
  dependencies. It runs without `nix-ld`. Only the optional voice helper is a
  glibc executable, which `nix-ld` covers because its libraries ship alongside
  it.

Neither tool needs Node.js or a system `ripgrep`. Declare **`bubblewrap`** for
both tools' sandboxes and **`socat`** for Claude Code's sandbox. Add
**`alsa-lib`** to `programs.nix-ld.libraries` only if Claude Code voice
dictation is wanted. `~/.local/bin` must already be on `PATH` when the Codex
installer or updater runs. Otherwise the installer tries to append to
`~/.zshrc`, which Home Manager makes read-only.

Suggested `desktop-pc` declarations (untested):

```nix
programs.nix-ld.enable = true;
# Optional, for Claude Code voice dictation only. List definitions merge, so
# this adds to the module's default libraries instead of replacing them.
# programs.nix-ld.libraries = [ pkgs.alsa-lib ];

environment.systemPackages = with pkgs; [
  bubblewrap  # Claude Code and Codex sandboxes
  socat       # Claude Code sandbox network relay
  # wl-clipboard  # optional: Claude Code clipboard paste on Wayland
];
```

## Key facts

### Claude Code: installer

- *Sourced:* The documented install is `curl -fsSL https://claude.ai/install.sh | bash`.
  Native installs "automatically update in the background"
  ([Claude Code setup](https://code.claude.com/docs/en/setup)).
- *Sourced* ([`install.sh`](https://claude.ai/install.sh), fetched 2026-11-10):
  - It needs `curl` or `wget`, `sha256sum`, and optionally `jq` and `zstd`. It
    runs under `bash`, which the pipe supplies, so the `#!/bin/bash` shebang
    is never used.
  - It refuses to run under `sudo` and installs into `$HOME`.
  - It picks `linux-x64-musl` only if `/lib/libc.musl-x86_64.so.1` exists or
    `ldd /bin/ls` mentions musl. Otherwise it picks `linux-x64`.
  - It downloads the binary into `~/.claude/downloads`, checks it against
    `manifest.json`, then **executes the downloaded binary** (`claude install`)
    to set up the launcher.
- *Inferred:* NixOS has no `/bin/ls` and no musl loader in `/lib`, so the
  script selects the glibc `linux-x64` build. The `ldd` error text contains no
  "musl". Because the script executes the downloaded glibc binary,
  `programs.nix-ld` must already be enabled before the installer is run, not
  only before `claude` is first used.
- *Sourced:* NixOS's core packages include `bashInteractive`, `coreutils-full`
  (`sha256sum`), `curl`, `zstd`, `gnutar`, `gzip`, `gawk`, `procps` and glibc
  (`ldd`) ([`system-path.nix`, 26.05](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/config/system-path.nix)).
  Everything the installer calls is present on a stock NixOS system.
- *Sourced:* The installer does not change `PATH`. When `~/.local/bin` is
  missing from `PATH`, it reports this under "Setup notes" and prints the fix
  ([Troubleshoot installation](https://code.claude.com/docs/en/troubleshoot-install#verify-your-path)).
- *Sourced:* The install writes only under the home directory:
  - `~/.claude/downloads/`
  - `~/.local/bin/claude`, a launcher symlink
  - `~/.local/share/claude/versions/`
  - `~/.local/state/claude/`
  - `~/.cache/claude/`
  - `~/.claude.json`

  `XDG_*_HOME` values override the defaults
  ([Troubleshoot installation](https://code.claude.com/docs/en/troubleshoot-install#check-directory-permissions)).
  NixOS needs no FHS write location.

### Claude Code: binary

- *Inspected (`linux-x64` 2.1.322, SHA-256 matches `manifest.json`):*
  - ELF64 x86-64 executable with interpreter `/lib64/ld-linux-x86-64.so.2`.
  - `DT_NEEDED` lists only `librt.so.1`, `libc.so.6`, `ld-linux-x86-64.so.2`,
    `libpthread.so.0`, `libdl.so.2` and `libm.so.6`.
  - The highest symbol version it needs is `GLIBC_2.17`.
  - It does not link against `libstdc++` or `libgcc_s`.
- *Inspected:* The binary embeds two native add-ons. One needs only glibc. The
  other, `audio-capture.node`, also needs **`libasound.so.2`** (ALSA), for
  voice dictation.
- *Sourced:* nixpkgs packages the same upstream binary with `autoPatchelfHook`,
  and on Linux only prefixes `LD_LIBRARY_PATH` with `alsa-lib`. That matches the
  inspection: glibc plus ALSA for audio
  ([nixpkgs `claude-code` at `f5c082a`](https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/cl/claude-code/package.nix)).
- *Sourced:* The nixpkgs wrapper sets `DISABLE_AUTOUPDATER=1`,
  `DISABLE_INSTALLATION_CHECKS=1` and `USE_BUILTIN_RIPGREP=0`. It puts
  `procps`, `ripgrep` and, on Linux, `bubblewrap` and `socat` on `PATH` (same
  file).

  Of these, the native install needs only the sandbox pair. The installer
  provides its own `ripgrep`, the updater is meant to stay on, and NixOS core
  packages already provide `procps`.
- *Inspected:* `ripgrep` is built into the binary. When `USE_BUILTIN_RIPGREP` is
  unset, the binary re-executes itself with `argv0` `rg` ("embedded" mode) and
  falls back to `rg` on `PATH`. Its error text says to "use the native claude
  binary which embeds it". The docs agree: "Ripgrep is bundled with the native
  Claude Code binary"
  ([Sandboxing](https://code.claude.com/docs/en/sandboxing)). **No system
  `ripgrep` is needed.**
- *Sourced:* "The installed `claude` binary does not itself invoke Node"
  ([Claude Code setup](https://code.claude.com/docs/en/setup#install-with-npm)).
  **No Node.js is needed.**

### Claude Code: updater

- *Sourced:* Claude Code checks for updates on startup and periodically,
  installs them in the background, and applies them at the next start. The
  launcher `~/.local/bin/claude` is a symlink into
  `~/.local/share/claude/versions/`. Replacing it with your own script or
  symlink makes it a custom launcher, which the updater leaves alone
  ([Claude Code setup](https://code.claude.com/docs/en/setup#auto-updates)).
  It keeps the version the launcher points to, any version a local session is
  running, and the two newest versions
  ([Install on network storage](https://code.claude.com/docs/en/setup#install-on-network-storage)).
- *Inspected:* The updater chooses its download platform in-process. In the
  `linux-x64` build, `isMuslEnvironment` is compiled as `return false`, so
  updates always fetch `linux-x64` from
  `https://downloads.claude.ai/claude-code-releases`.
- *Inferred:* Every update is therefore the same kind of glibc executable, run
  through the same `nix-ld` loader. The updater spawns no shell script and
  writes only under the home directory, so it **keeps working on NixOS**. Do
  not wrap the launcher. A wrapper script would turn it into a custom launcher,
  which leaves old versions on disk.
- *Inspected:* The only "NixOS" string in the binary is in the embedded Bun
  runtime's `bun upgrade` error. It is not Claude Code's updater and does not
  apply.

### Claude Code: shell, sandbox and desktop helpers

- *Inspected:* Shell selection tries, in order:
  1. `CLAUDE_CODE_SHELL` and `$SHELL`, if they name bash or zsh
  2. `zsh` or `bash` found on `PATH`
  3. fixed paths under `/bin`, `/usr/bin`, `/usr/local/bin` and
     `/opt/homebrew/bin`

  On NixOS the first two steps resolve, for example to
  `/run/current-system/sw/bin/zsh`.
- *Inspected:* Two internal code paths name `/bin/bash` literally:
  - The sandbox runtime falls back to `/bin/bash` when it is given no shell.
  - A helper class spawns `/bin/bash --noprofile --norc`. It could not be
    traced to a user-visible feature.

  NixOS has `/bin/sh` but no `/bin/bash`. See
  [Open uncertainties](#open-uncertainties).
- *Sourced:* The Linux sandbox needs `bubblewrap` and `socat`; the seccomp
  filter is optional. Without them, Claude Code "runs commands without
  sandboxing" unless `sandbox.failIfUnavailable` is set
  ([Sandboxing](https://code.claude.com/docs/en/sandboxing)).
- *Inspected:* The binary finds `bwrap` and `socat` on `PATH`, or at the
  absolute paths set in `sandbox.bwrapPath` and `sandbox.socatPath`.
- *Sourced:* NixOS allows unprivileged user namespaces by default
  (`security.allowUserNamespaces` defaults to `true`;
  [`security/misc.nix`, 26.05](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/security/misc.nix)).
  The Ubuntu AppArmor user-namespace restriction that the vendor docs work
  around is not a NixOS default.
- *Inspected:* Clipboard reads on Linux call
  `xclip -selection clipboard … || wl-paste`, and the binary also references
  `wl-copy`. On a Niri session, `wl-clipboard` enables this. It is optional.

### Codex: installer

- *Sourced:* The documented install and update command is
  `curl -fsSL https://chatgpt.com/codex/install.sh | sh`
  ([Codex CLI docs](https://learn.chatgpt.com/docs/codex/cli),
  [Codex README](https://github.com/openai/codex/blob/main/README.md)). The
  only Linux release binaries are `x86_64-unknown-linux-musl` and
  `aarch64-unknown-linux-musl` (same README;
  [release `rust-v0.167.0`](https://github.com/openai/codex/releases/tag/rust-v0.167.0)).
- *Sourced* ([`install.sh`](https://chatgpt.com/codex/install.sh), fetched 2026-11-10):
  - It is POSIX `sh`. It requires `mktemp`, `tar`, `curl` or `wget`, `awk`,
    `fold`, `stat`, and one of `sha256sum`, `shasum` or `openssl`.
  - On Linux x86_64 it always selects
    `codex-package-x86_64-unknown-linux-musl.tar.gz`. It downloads from
    `releases.openai.com`, falls back to GitHub Releases, and verifies the
    archive against `codex-package_SHA256SUMS`.
  - It unpacks to `~/.codex/packages/standalone/releases/<version>-<target>`.
    It points the `current` symlink there and links `~/.local/bin/codex` to
    `current/bin/codex`.
  - Before switching, it checks that the release contains `codex-path/rg` and,
    on Linux, `codex-resources/bwrap`.
- *Sourced:* `/proc` is used to detect releases still in use. `/usr/sbin/lsof`
  is used only on macOS (same script).
- *Sourced:* If `~/.local/bin` is not on `PATH`, or a Homebrew or npm `codex`
  conflicts, the script appends an `export PATH=…` block to a shell file.
  - Linux with zsh: `~/.zshrc`
  - Linux with bash: `~/.bashrc`
  - macOS with zsh: `~/.zprofile`
  - macOS with bash: `~/.bash_profile`
  - anything else: `~/.profile`

  It runs under `set -eu` (same script).
- *Inferred:* With Home Manager's `programs.zsh`, `~/.zshrc` is a read-only
  link into the Nix store. If `~/.local/bin` is missing from the installer's
  `PATH`, the append fails and the script exits with an error after it has
  already switched `current` and the `codex` link. The Workstation module's
  `home.sessionPath = [ "$HOME/.local/bin" ]` prevents this, provided the
  shell that runs the installer has loaded the Home Manager session variables.
- *Inferred:* Everything the script calls is in NixOS's core packages
  ([`system-path.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/config/system-path.nix)).
  It assumes no FHS path on Linux.

### Codex: binaries

- *Inspected (`codex-package-x86_64-unknown-linux-musl.tar.gz` 0.167.0):*
  - `codex-package.json` declares target `x86_64-unknown-linux-musl`.
  - `bin/codex`, `bin/codex-code-mode-host`, `bin/codex-exec-server`,
    `codex-path/rg` and `codex-resources/bwrap` are **static-PIE** ELF
    executables. They have no `PT_INTERP` and no `DT_NEEDED` entries, so they
    run on NixOS without `nix-ld`.
- *Inspected:* `codex-resources/voice/bin/codex-voice-host` is the exception.
  - Its `voice/manifest.json` gives `voiceTarget` as
    `x86_64-unknown-linux-gnu`.
  - It is a glibc executable (`/lib64/ld-linux-x86-64.so.2`, up to
    `GLIBC_2.28`) with `RUNPATH` `$ORIGIN/../lib`.
  - It needs GLib, GStreamer and Opus libraries, all shipped in
    `voice/lib/`. Apart from glibc's own libraries (`libresolv`, `libc`,
    `libm` and others), none of these resolves outside the bundle.
  - *Inferred:* `nix-ld` with default libraries is enough to start it. It is
    needed only for voice.
- *Sourced:* nixpkgs builds Codex from source and wraps it with `ripgrep` and,
  on Linux, `bubblewrap` on `PATH`
  ([nixpkgs `codex` at `f5c082a`](https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/co/codex/package.nix)).
  The standalone package bundles both, so neither is required.
- *Inferred:* Codex is Rust with embedded V8 (`codex-code-mode-host`). **No
  Node.js is needed.**

### Codex: updater

- *Sourced:* The TUI checks GitHub's latest release at most every 20 hours,
  unless `check_for_update_on_startup` is off
  ([`tui/src/updates.rs`](https://github.com/openai/codex/blob/b32ada5320b043bde03a10edab6b88fc126812b4/codex-rs/tui/src/updates.rs)).
- *Sourced:* For a standalone Unix install it then offers "Update now", which
  runs:

  ```sh
  sh -c 's=$(curl -fsSL https://chatgpt.com/codex/install.sh) && CODEX_NON_INTERACTIVE=1 eval "$s"'
  ```

  ([`tui/src/update_action.rs`](https://github.com/openai/codex/blob/b32ada5320b043bde03a10edab6b88fc126812b4/codex-rs/tui/src/update_action.rs),
  [`update_prompt.rs`](https://github.com/openai/codex/blob/b32ada5320b043bde03a10edab6b88fc126812b4/codex-rs/tui/src/update_prompt.rs)).
  It is a prompted re-run of the installer, not a silent background update.
- *Inferred:* The update needs only `sh` and `curl` on `PATH`, both present on
  NixOS. It installs the same static musl package, so **updates keep working**.
  The `PATH` and read-only `~/.zshrc` caveat above applies to every update,
  because the update runs with the environment of the `codex` process.

### Codex: sandbox

- *Sourced:* "Codex uses the first `bwrap` executable it finds on `PATH`." If
  none is found, it falls back to a bundled helper that "requires support for
  unprivileged user namespace creation". Installing the distribution's `bwrap`
  "keeps this setup reliable"
  ([Codex sandboxing](https://learn.chatgpt.com/docs/sandboxing)).
- *Inspected:* `codex` contains Landlock and seccomp code and verifies the
  bundled `bwrap` digest before running it. Its error text when both are
  missing is: "no system bwrap was found on PATH and no bundled
  codex-resources/bwrap binary was found next to the Codex executable".
- *Inferred:* On NixOS unprivileged user namespaces are allowed by default, so
  even the bundled static `bwrap` should work. Declaring `pkgs.bubblewrap`
  follows the vendor's recommendation and also serves Claude Code. Landlock
  and seccomp are kernel features and need no package.

### `nix-ld`

- *Sourced:* The module sets `environment.ldso` to the `nix-ld` shim. NixOS
  links that shim to `/lib64/ld-linux-x86-64.so.2`. Without it, the default is
  a stub loader that prints "Could not start dynamically linked executable"
  ([`nix-ld.nix`, 26.05](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/programs/nix-ld.nix),
  [`ldso.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/config/ldso.nix),
  [`stub-ld.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/config/stub-ld.nix)).
  The module is identical at the pinned `f5c082a`
  ([pinned `nix-ld.nix`](https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/nixos/modules/programs/nix-ld.nix)).
- *Sourced:* The default libraries are `zlib`, `zstd`, `stdenv.cc.cc`, `curl`,
  `openssl`, `attr`, `libssh`, `bzip2`, `libxml2`, `acl`, `libsodium`,
  `util-linux`, `xz` and `systemd`, with glibc's loader as the real `ld.so`.
  They are set as an ordinary definition inside `config`, not as the option
  default (same file).
- *Inferred:* A host definition of `programs.nix-ld.libraries = [ pkgs.alsa-lib ];`
  is therefore concatenated with the defaults rather than replacing them.
- *Sourced:* The module exports `NIX_LD` and `NIX_LD_LIBRARY_PATH` as session
  variables (same file). `nix-ld` turns `NIX_LD_LIBRARY_PATH` into
  `LD_LIBRARY_PATH` for the program it starts. It falls back to
  `/run/current-system/sw/share/nix-ld/lib` when the variables are unset
  ([nix-ld README](https://github.com/nix-community/nix-ld/blob/main/README.md)).
- *Inferred:* `alsa-lib` is absent from the defaults, so the Claude Code
  audio add-on cannot load `libasound.so.2` until it is added. Nothing else
  either tool links against is missing.

### macOS (aarch64-darwin)

- *Sourced:* The Claude Code installer maps an arm64 Mac, or an x64 shell under
  Rosetta, to `darwin-arm64` ([`install.sh`](https://claude.ai/install.sh)).
  The binaries are signed by "Anthropic PBC" and notarized
  ([Claude Code setup](https://code.claude.com/docs/en/setup#platform-code-signatures)).
- *Sourced:* The Codex installer maps the same cases to `aarch64-apple-darwin`.
  On macOS it also links `~/.local/bin/codex-code-mode-host` and uses
  `/usr/sbin/lsof`, which ships with macOS
  ([`install.sh`](https://chatgpt.com/codex/install.sh)).
- *Sourced:* The Codex installer flags an existing `codex` under
  `/opt/homebrew/*` or `/usr/local/*`, or an npm `codex` script, as a
  conflicting install. In that case it writes a `PATH` block to `~/.zprofile`,
  even when `~/.local/bin` is already on `PATH`, and warns that `PATH` order
  decides which one runs (same script).
- *Inferred:* The Mac profile's `.zshrc` snippet
  `path=("$HOME/.nix-profile/bin" $path)` runs after Home Manager's session
  variables, so `~/.nix-profile/bin` stays ahead of `~/.local/bin`.
  - This is harmless once `claude-code` leaves `home.packages` and no Nix
    `codex` exists.
  - It would shadow the self-updating copies if either tool ever returned to
    Nix.
  - The `which -a claude` / `which -a codex` check planned in
    [Shared home module and desktop-pc host structure](https://github.com/maurerf/nixos/issues/29)
    covers this.
- *Inferred:* If Home Manager manages `~/.zprofile`, it is read-only too, so
  remove any Homebrew or npm `codex` before running the Codex installer.

## Contradictions with earlier decisions

None. [Shared home module and desktop-pc host structure](https://github.com/maurerf/nixos/issues/29)
assumed `programs.nix-ld` with defaults on `desktop-pc`. That assumption holds
for Claude Code, and Codex does not need it at all. The packages above refine
the decision; they do not reverse it.

## Open uncertainties

Runtime proof belongs to the VM dry run.

1. **Literal `/bin/bash` in Claude Code.** Two internal code paths name
   `/bin/bash`, which NixOS lacks. The normal Bash tool resolves the shell from
   `$SHELL` and `PATH`, so this is expected to be harmless. If a feature fails
   with `spawn /bin/bash ENOENT`, set `CLAUDE_CODE_SHELL`. If that is not
   enough, consider `services.envfs`.
2. **Claude Code sandbox on NixOS.** Not run. The sandbox runs commands inside
   `bwrap`, and its mount layout must expose `/nix/store` and
   `/run/current-system` so that Nix-built tools work inside it. Check
   `/sandbox` in the VM.
3. **Voice features.** Claude Code dictation needs `alsa-lib` through
   `nix-ld`. On a PipeWire host, ALSA output also depends on
   `services.pipewire.alsa.enable`. Codex's voice host bundles GStreamer
   without a capture plugin, so how it gets audio is unknown. Both are
   optional and untested.
4. **Installer drift.** Both scripts are fetched live and change often. These
   findings describe the 2026-11-10 copies (Claude Code 2.1.322, Codex
   0.167.0). A future switch to a glibc Codex build, or new `DT_NEEDED`
   entries in Claude Code, would change the library answer. `ldd` on the
   installed binaries in the VM settles it.
5. **Environment of the Codex updater.** Whether `~/.local/bin` is on `PATH`
   inside a `codex` started from a Niri terminal depends on how the session
   loads Home Manager variables. Check `echo $PATH` in the VM before the first
   update.
6. **TLS roots and name resolution** for the static musl Codex were not
   examined. NixOS provides `/etc/ssl/certs` and `/etc/resolv.conf`, which
   static binaries usually read.
7. **macOS `~/.zprofile` ownership** under Home Manager was not checked against
   the Home Manager source.
