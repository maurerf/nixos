# Checkup evidence

Collected on 2026-09-25. This file consolidates the original command outputs and interview answers. Original filenames label archived records below; they are not separate files. Raw record contents are preserved. Findings and requirements live in [PRD.md](PRD.md).

## Evidence index

| Reference | Archived records |
| --- | --- |
| F1 | evidence-repo.txt |
| F2 | evidence-static.txt |
| F3 | evidence-mac.txt |
| F4 | evidence-provenance-0.txt, evidence-mac-privileged.txt, evidence-provenance-extra.txt |
| F5 | evidence-metadata.txt, evidence-show.txt, evidence-eval-darwin.txt, evidence-eval-vps.txt |
| F6 | evidence-brew.txt, plus Caskroom inventory in F2 |
| F7 | evidence-web-releases.json |
| F8 | evidence-vps-user.txt, supplied by the user |
| F9 | evidence-history-match.txt |

The privileged read-only command was `/bin/bash -c 'dscl . -list /Users UniqueID | rg nixbld; sudo -n nix-channel --list; darwin-version --configuration-revision; nix-env --list-generations -p /nix/var/nix/profiles/system'`. Its output is in F4. Generation listing failed to open its profile lock. Collector source is archived at the end to make the inspection commands reproducible without retaining standalone tooling.

## Interview decisions

The recommendations below describe later implementation. They do not authorize implementation during this planning session.

### First round

- **I1, VPS purpose:** User: "The mail server is the only purpose of the VPS currently. There shouldnt be anything else that is stateful." The user provided the complete discovery-script transcript, retained in `evidence-vps-user.txt`.
- **I2, healthy:** User answered "ok" to both configurations building, deployments identifying their source commit, Mac applications and shell working, and VPS services passing explicit operational checks. Preserve currently used features. An exact Mac application list was not supplied.
- **I3, release policy:** User answered "ok" to supported stable releases with compatible Home Manager, nix-darwin, and mailserver inputs; use unstable packages only where needed. Intermediate deployment steps are required only when deployed versions or migration requirements justify them.
- **I4, recovery policy:** User answered "ok" to verified restoration and console access before VPS activation, preserving rollback generations, and no intentional data loss. This accepts a prerequisite; it does not establish that backup or restore testing has already happened.
- **I5, scope and order:** User answered "ok" to Mac first, necessary compatibility fixes and updates, credential-management improvements, accurate documentation, and lightweight CI. Broad refactoring and feature removal are deferred. Use separate maintenance windows.

### Second round

- **I6, backups:** User: "The VPS is hosted on Vultr. There is do a full system snapshop before any major Nix upgrade." Interpret as the user's stated practice of taking a full-system snapshot before major upgrades. No snapshot identifier, completion date, retention policy, or successful restore-test evidence was supplied. The question recommended a verified, restorable off-host backup of all mail-related state; whether the Vultr snapshot satisfies all required coverage and consistency checks remains to be established.
- **I7, console and downtime:** User: "Yes. I can access a console via the Vultr Web interface. Mail service downtime of up to 1 hour is acceptable." This overrides the suggested 30-minute outage limit. Console access is user-confirmed, not independently tested by this audit.
- **I8, implementation windows and Mac checks:** User answered "ok" to separate two-hour Mac and VPS deployment windows, with backup/restore preparation budgeted separately; test login, Zsh/Git, app discovery and launch, and every application currently relied upon. Total preparation effort and the exact application inventory remain unspecified.

### Questions retained as implementation gates

1. Which completed Vultr snapshot and isolated restore test establish recovery, and what is the measured restore duration?
2. Which mail-related paths and identities must be restored or reconciled, including messages accepted after the snapshot?
3. Which named Mac applications and workflows comprise the final acceptance checklist?
4. Which exact mutually compatible supported input revisions will be selected, and what migration steps do they require?
5. Can historical configuration provenance be established beyond matching nixpkgs revisions? If not, preserve the uncertainty and record exact source revisions on future deployments.

No further planning decisions are required to write the PRD. These questions must not silently be treated as answered before their dependent implementation steps.

## Raw command outputs

### evidence-brew.txt

````text
$ HOMEBREW_NO_AUTO_UPDATE=1 brew --version; HOMEBREW_NO_AUTO_UPDATE=1 brew list --versions; HOMEBREW_NO_AUTO_UPDATE=1 brew tap
Homebrew 5.1.15
✘ JSON API formula.jws.json
Error: Operation not permitted @ dir_s_mkdir - /Users/fdm/Library/Caches/Homebrew
✘ JSON API formula_tap_migrations.jws.json
Error: Operation not permitted @ dir_s_mkdir - /Users/fdm/Library/Caches/Homebrew
✘ JSON API cask.jws.json
Error: Operation not permitted @ dir_s_mkdir - /Users/fdm/Library/Caches/Homebrew
✘ JSON API cask_tap_migrations.jws.json
Error: Operation not permitted @ dir_s_mkdir - /Users/fdm/Library/Caches/Homebrew
✘ JSON API cask_tap_migrations.jws.json
Error: Operation not permitted @ dir_s_mkdir - /Users/fdm/Library/Caches/Homebrew
Error: Operation not permitted @ dir_s_mkdir - /Users/fdm/Library/Caches/Homebrew
abseil 20250814.1
aom 3.13.1
aribb24 1.0.4
autoconf 2.72
autogen 5.18.16_3
automake 1.18.1
bdw-gc 8.2.10
binutils 2.45.1
blake3 1.8.2
boost 1.90.0
brotli 1.2.0
ca-certificates 2025-12-02
cairo 1.18.4
ccache 4.12.2
certifi 2025.11.12
cjson 1.7.19
cmake 4.2.1
coreutils 9.9
dav1d 1.5.2
deno 2.6.0
doxygen 1.15.0
expat 2.7.3
ffmpeg 8.0.1
flac 1.5.0
fmt 12.1.0
fontconfig 2.18.1
freetype 2.14.3
frei0r 2.5.1
fribidi 1.0.16
gd 2.3.3_6
gdk-pixbuf 2.44.6
gettext 1.0
giflib 5.2.2
glib 2.88.1
gmp 6.3.0
gnutls 3.8.11
graphite2 1.3.15
graphviz 14.1.1
gts 0.7.6_3
guile 3.0.11
harfbuzz 14.2.1
hidapi 0.15.0
highway 1.3.0
hiredis 1.3.0
icu4c@78 78.3
imath 3.2.2
jasper 4.2.8
jpeg-turbo 3.1.4.1
jpeg-xl 0.11.1_3
lame 3.100
leptonica 1.86.0
libarchive 3.8.4
libass 0.17.4
libavif 1.3.0
libb2 0.98.1
libbluray 1.4.0_1
libdatrie 0.2.14
libdeflate 1.25
libevent 2.1.12_1
libidn2 2.3.8
libmicrohttpd 1.0.2
libnghttp2 1.68.0
libogg 1.3.6
libpgm 5.3.128
libpng 1.6.58
librist 0.2.11_1
librsvg 2.62.3
libsamplerate 0.2.2
libscrypt 1.22
libsndfile 1.2.2_1
libsodium 1.0.20
libsoxr 0.1.3
libssh 0.11.3
libtasn1 4.20.0
libthai 0.1.30
libtiff 4.7.1_1
libtool 2.5.4
libudfread 1.2.0
libunibreak 6.1
libunistring 1.4.2
libunwind-headers 201
libusb 1.0.29
libvidstab 1.1.1
libvmaf 3.0.0
libvorbis 1.3.7
libvpx 1.15.2
libx11 1.8.13
libxau 1.0.12
libxcb 1.17.0
libxdmcp 1.1.5
libxext 1.3.7
libxrender 0.9.12
little-cms2 2.17
lz4 1.10.0
lzo 2.10
m4 1.4.20
mbedtls@3 3.6.5
miniupnpc 2.3.3
mpdecimal 4.0.1
mpg123 1.33.3
netpbm 11.02.19_1
nettle 3.10.2
opencore-amr 0.1.6
openexr 3.4.4
openjpeg 2.5.4
openjph 0.26.0
openssl@3 3.6.0
opus 1.6
p11-kit 0.25.10
pango 1.57.1
pcre2 10.47_1
pixman 0.46.4
pkgconf 2.5.1
protobuf 33.2
python@3.14 3.14.2
rav1e 0.8.1
readline 8.3.3
rubberband 4.0.0
sdl2 2.32.10
snappy 1.2.2
speex 1.2.1
sqlite 3.51.1
srt 1.5.4
svt-av1 3.1.2
tesseract 5.5.1_1
theora 1.2.0
tor 0.4.8.21
unbound 1.24.2
webp 1.6.0
x264 r3222
x265 4.1
xorgproto 2025.1
xvid 1.3.7
xxhash 0.8.3
xz 5.8.3
yt-dlp 2025.12.8
zeromq 4.3.5_2
zimg 3.0.6
zstd 1.5.7_1
gromgit/fuse
homebrew/bundle

[exit 0]
````

### evidence-eval-darwin.txt

````text
$ nix --offline --store 'local?read-only=true' --option allow-import-from-derivation false --option eval-cache false --option max-jobs 0 --option builders '' eval --no-write-lock-file --raw '.#darwinConfigurations.m2-macbook-air.system.drvPath'
error: experimental Nix feature 'read-only-local-store' is disabled; add '--extra-experimental-features read-only-local-store' to enable it

[exit 1]
$ nix --extra-experimental-features read-only-local-store --offline --store 'local?read-only=true' --option allow-import-from-derivation false --option eval-cache false --option max-jobs 0 --option builders '' eval --no-write-lock-file --raw '.#darwinConfigurations.m2-macbook-air.system.drvPath'
warning: Git tree '/Users/fdm/git/nixos' is dirty
error: opening lock file "/nix/store/11l5zyj8qzc3b6mcrjhgvrzwcva2da2b-source.lock": Operation not permitted

[exit 1]
````

### evidence-eval-vps.txt

````text
$ nix --offline --store 'local?read-only=true' --option allow-import-from-derivation false --option eval-cache false --option max-jobs 0 --option builders '' eval --no-write-lock-file --raw '.#nixosConfigurations.vps.config.system.build.toplevel.drvPath'
error: experimental Nix feature 'read-only-local-store' is disabled; add '--extra-experimental-features read-only-local-store' to enable it

[exit 1]
$ nix --extra-experimental-features read-only-local-store --offline --store 'local?read-only=true' --option allow-import-from-derivation false --option eval-cache false --option max-jobs 0 --option builders '' eval --no-write-lock-file --raw '.#nixosConfigurations.vps.config.system.build.toplevel.drvPath'
warning: Git tree '/Users/fdm/git/nixos' is dirty
error: opening lock file "/nix/store/11l5zyj8qzc3b6mcrjhgvrzwcva2da2b-source.lock": Operation not permitted

[exit 1]
````

### evidence-history-match.txt

````text
$ python3 docs/goals/01-checkup/compare-history.py
$ git status --short
 M profiles/home-darwin.nix
?? AGENTS.md
?? docs/

[exit 0]
$ git log --all --format=%H %cI %s -- flake.lock
b335654465345dbc9bd283bfbaebb2ce31adb890 2026-05-23T20:09:52+02:00 chore: upate flake.lock
8612229f7c2abc47ddc90e2f0e174962cf93ba9b 2025-11-29T14:02:42+01:00 fix: previous squashed commit reverted some changes
f62ba5635730ce93eac567443c17c36b93cb1cf5 2025-11-29T13:32:49+01:00 chore: further general cleanup
d01bf47799d4d4d62811d7938b473a8160558a85 2025-11-28T16:24:22+01:00 Fix Homebrew integration: disable channels, add conservative Homebrew config, fix syntax compatibility
456ec00eee14152cd64c205a93211c2b0fad4591 2025-11-28T15:39:53+01:00 Fix compatibility issues: update nerd-fonts syntax, zsh autosuggestion config, add Darwin user
12439e567223fc362df103abea89901ba3eabbba 2025-11-28T15:37:23+01:00 Refactor: Remove obsolete configs, create shared modules, standardize on unstable
9cb9adab0d6b69eec7c5533cb9a215723c90307f 2024-02-23T14:27:27+01:00 feat: new structure, flake update, minor fixes
2e65c568fdbbb073875cde7b15a9921273dd63e6 2023-12-05T17:41:54+01:00 chore: update flake.lock
39d6f5935bfbafb3e1c1caf4261edbd00bb809aa 2023-11-07T11:27:50+01:00 chore: clean up new flake structure
15899c54e8499522cba41ee387b291a5c7c3265c 2023-11-06T16:26:39+01:00 feat: mailserver/vps flake
2bf29a53c24e6b0da7c60caf7c3ac699a79fb4d1 2023-08-29T13:36:20+02:00 update: desktop config

[exit 0]
MATCH: 8612229f7c2abc47ddc90e2f0e174962cf93ba9b node nixpkgs
$ git show 8612229f7c2abc47ddc90e2f0e174962cf93ba9b:flake.lock
{
  "nodes": {
    "blobs": {
      "flake": false,
      "locked": {
        "lastModified": 1604995301,
        "narHash": "sha256-wcLzgLec6SGJA8fx1OEN1yV/Py5b+U5iyYpksUY/yLw=",
        "owner": "simple-nixos-mailserver",
        "repo": "blobs",
        "rev": "2cccdf1ca48316f2cfd1c9a0017e8de5a7156265",
        "type": "gitlab"
      },
      "original": {
        "owner": "simple-nixos-mailserver",
        "repo": "blobs",
        "type": "gitlab"
      }
    },
    "flake-compat": {
      "flake": false,
      "locked": {
        "lastModified": 1761588595,
        "narHash": "sha256-XKUZz9zewJNUj46b4AJdiRZJAvSZ0Dqj2BNfXvFlJC4=",
        "owner": "edolstra",
        "repo": "flake-compat",
        "rev": "f387cd2afec9419c8ee37694406ca490c3f34ee5",
        "type": "github"
      },
      "original": {
        "owner": "edolstra",
        "repo": "flake-compat",
        "type": "github"
      }
    },
    "git-hooks": {
      "inputs": {
        "flake-compat": [
          "simple-nixos-mailserver",
          "flake-compat"
        ],
        "gitignore": "gitignore",
        "nixpkgs": [
          "simple-nixos-mailserver",
          "nixpkgs"
        ]
      },
      "locked": {
        "lastModified": 1763988335,
        "narHash": "sha256-QlcnByMc8KBjpU37rbq5iP7Cp97HvjRP0ucfdh+M4Qc=",
        "owner": "cachix",
        "repo": "git-hooks.nix",
        "rev": "50b9238891e388c9fdc6a5c49e49c42533a1b5ce",
        "type": "github"
      },
      "original": {
        "owner": "cachix",
        "repo": "git-hooks.nix",
        "type": "github"
      }
    },
    "gitignore": {
      "inputs": {
        "nixpkgs": [
          "simple-nixos-mailserver",
          "git-hooks",
          "nixpkgs"
        ]
      },
      "locked": {
        "lastModified": 1709087332,
        "narHash": "sha256-HG2cCnktfHsKV0s4XW83gU3F57gaTljL9KNSuG6bnQs=",
        "owner": "hercules-ci",
        "repo": "gitignore.nix",
        "rev": "637db329424fd7e46cf4185293b9cc8c88c95394",
        "type": "github"
      },
      "original": {
        "owner": "hercules-ci",
        "repo": "gitignore.nix",
        "type": "github"
      }
    },
    "home-manager": {
      "inputs": {
        "nixpkgs": [
          "nixpkgs"
        ]
      },
      "locked": {
        "lastModified": 1764361670,
        "narHash": "sha256-jgWzgpIaHbL3USIq0gihZeuy1lLf2YSfwvWEwnfAJUw=",
        "owner": "nix-community",
        "repo": "home-manager",
        "rev": "780be8ef503a28939cf9dc7996b48ffb1a3e04c6",
        "type": "github"
      },
      "original": {
        "owner": "nix-community",
        "ref": "master",
        "repo": "home-manager",
        "type": "github"
      }
    },
    "nix-darwin": {
      "inputs": {
        "nixpkgs": [
          "nixpkgs"
        ]
      },
      "locked": {
        "lastModified": 1764161084,
        "narHash": "sha256-HN84sByg9FhJnojkGGDSrcjcbeioFWoNXfuyYfJ1kBE=",
        "owner": "LnL7",
        "repo": "nix-darwin",
        "rev": "e95de00a471d07435e0527ff4db092c84998698e",
        "type": "github"
      },
      "original": {
        "owner": "LnL7",
        "ref": "master",
        "repo": "nix-darwin",
        "type": "github"
      }
    },
    "nixpkgs": {
      "locked": {
        "lastModified": 1764384123,
        "narHash": "sha256-UoliURDJFaOolycBZYrjzd9Cc66zULEyHqGFH3QHEq0=",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "59b6c96beacc898566c9be1052ae806f3835f87d",
        "type": "github"
      },
      "original": {
        "owner": "NixOS",
        "ref": "nixpkgs-unstable",
        "repo": "nixpkgs",
        "type": "github"
      }
    },
    "root": {
      "inputs": {
        "home-manager": "home-manager",
        "nix-darwin": "nix-darwin",
        "nixpkgs": "nixpkgs",
        "simple-nixos-mailserver": "simple-nixos-mailserver"
      }
    },
    "simple-nixos-mailserver": {
      "inputs": {
        "blobs": "blobs",
        "flake-compat": "flake-compat",
        "git-hooks": "git-hooks",
        "nixpkgs": [
          "nixpkgs"
        ]
      },
      "locked": {
        "lastModified": 1764381008,
        "narHash": "sha256-s+/BuhPPSJHpPRcylqfW+3UFyYsHjAhKdtPSxusYn0U=",
        "owner": "simple-nixos-mailserver",
        "repo": "nixos-mailserver",
        "rev": "76bd7a85e78a9b8295782a9cf719ec3489d8eb55",
        "type": "gitlab"
      },
      "original": {
        "owner": "simple-nixos-mailserver",
        "repo": "nixos-mailserver",
        "type": "gitlab"
      }
    }
  },
  "root": "root",
  "version": 7
}

[exit 0]
$ git log --format=%H %cI %s 8612229f7c2abc47ddc90e2f0e174962cf93ba9b..HEAD
b335654465345dbc9bd283bfbaebb2ce31adb890 2026-05-23T20:09:52+02:00 chore: upate flake.lock
2e38cb0fd1951c32c7428ed5ce35d0e9502e9c3c 2026-05-23T20:08:50+02:00 fix: clean up, add Notion
e886ece100d9b21e594a37316d15ccfa2888fc8d 2025-11-29T14:15:22+01:00 chore: resolve divergence
f881a29139be9332bcd68475a18e7723199ca298 2025-11-29T13:42:46+01:00 chore: update; clean up repo structure
0d1bc3046d740f6a8e808e35e74055e5e1038e91 2025-11-28T01:01:39+01:00 chore: update mailserver to new dovecot version

[exit 0]
Matched nixpkgs locked timestamp: 2025-11-29T02:42:03+00:00
Deployed nixpkgs age in whole days on 2026-09-25T17:47:22Z: 300
````

### evidence-mac-privileged.txt

````text
_nixbld1                 351
_nixbld10                360
_nixbld11                361
_nixbld12                362
_nixbld13                363
_nixbld14                364
_nixbld15                365
_nixbld16                366
_nixbld17                367
_nixbld18                368
_nixbld19                369
_nixbld2                 352
_nixbld20                370
_nixbld21                371
_nixbld22                372
_nixbld23                373
_nixbld24                374
_nixbld25                375
_nixbld26                376
_nixbld27                377
_nixbld28                378
_nixbld29                379
_nixbld3                 353
_nixbld30                380
_nixbld31                381
_nixbld32                382
_nixbld4                 354
_nixbld5                 355
_nixbld6                 356
_nixbld7                 357
_nixbld8                 358
_nixbld9                 359
sudo: a password is required
/run/current-system/sw/bin/darwin-version: configuration commit hash is unknown
error: opening lock file "/nix/var/nix/profiles/system.lock": Permission denied
````

### evidence-mac.txt

````text
$ sw_vers; uname -m; nix --version; command -v nix darwin-version darwin-rebuild home-manager brew; darwin-version; readlink /run/current-system; darwin-rebuild --list-generations; nix-channel --list; sudo -n nix-channel --list; home-manager generations; launchctl print system/org.nixos.nix-daemon; launchctl print system/systems.determinate.nix-daemon; dscl . -list /Users UniqueID | rg "nixbld"; ls -ld /nix/var/nix/profiles/system* /nix/var/nix/profiles/per-user/root/channels* /nix/var/nix/profiles/per-user/fdm/* /etc/nix/* /etc/static /etc/nix-darwin /etc/nixos /nix/receipt.json /usr/local/bin/determinate-nixd 2>/dev/null
ProductName:		macOS
ProductVersion:		26.6.2
BuildVersion:		25G83
arm64
nix (Nix) 2.34.7+1
/run/current-system/sw/bin/nix
/run/current-system/sw/bin/darwin-version
/run/current-system/sw/bin/darwin-rebuild
/opt/homebrew/bin/brew
26.05.56c666e
/nix/store/5vylcskg3kzqc55b9nb71x9hxkhnnx63-darwin-system-26.05.56c666e
error: opening lock file "/nix/var/nix/profiles/system.lock": Operation not permitted
zsh:1: operation not permitted: sudo
zsh:1: command not found: home-manager
system/org.nixos.nix-daemon = {
	active count = 1
	path = /Library/LaunchDaemons/org.nixos.nix-daemon.plist
	type = LaunchDaemon
	state = running

	program = /bin/sh
	arguments = {
		/bin/sh
		-c
		/bin/wait4path /nix/store && exec /nix/store/65ghpdw6n9vawhzx8bzqym2zmzrz4dmc-nix-2.34.7+1/bin/nix-daemon
	}

	default environment = {
		PATH => /usr/bin:/bin:/usr/sbin:/sbin
	}

	environment = {
		OSLogRateLimit => 64
		OBJC_DISABLE_INITIALIZE_FORK_SAFETY => YES
		NIX_SSL_CERT_FILE => /etc/ssl/certs/ca-certificates.crt
		XPC_SERVICE_NAME => org.nixos.nix-daemon
	}

	domain = system
	minimum runtime = 10
	exit timeout = 5
	runs = 1
	pid = 383
	immediate reason = speculative
	forks = 2
	execs = 3
	initialized = 1
	trampolined = 1
	started suspended = 0
	proxy started suspended = 0
	checked allocations = 0 (queried = 1)
	checked allocations reason = no host
	checked allocations flags = 0x0
	last exit code = (never exited)

	resource coalition = {
		ID = 397
		type = resource
		state = active
		active count = 1
		name = org.nixos.nix-daemon
	}

	jetsam coalition = {
		ID = 398
		type = jetsam
		state = active
		active count = 1
		name = org.nixos.nix-daemon
	}

	spawn type = daemon (3)
	jetsam priority = 40
	jetsam memory limit (active) = (unlimited)
	jetsam memory limit (inactive) = (unlimited)
	jetsamproperties category = daemon
	jetsam thread limit = 32
	cpumon = default
	resource limits = {
		maxfiles (soft) => 1048576
	}


	properties = keepalive | inferred program | managed LWCR | has LWCR
}
Bad request.
Could not find service "systems.determinate.nix-daemon" in domain for system
Operation failed with error: eServerError
zsh:1: no matches found: /nix/var/nix/profiles/per-user/root/channels*

[exit 1]
````

### evidence-metadata.txt

````text
$ nix --offline --store 'local?read-only=true' --option allow-import-from-derivation false --option eval-cache false --option max-jobs 0 --option builders '' flake metadata --no-write-lock-file .
error: experimental Nix feature 'read-only-local-store' is disabled; add '--extra-experimental-features read-only-local-store' to enable it

[exit 1]
$ nix --extra-experimental-features read-only-local-store --offline --store 'local?read-only=true' --option allow-import-from-derivation false --option eval-cache false --option max-jobs 0 --option builders '' flake metadata --no-write-lock-file .
warning: Git tree '/Users/fdm/git/nixos' is dirty
error: opening lock file "/nix/store/11l5zyj8qzc3b6mcrjhgvrzwcva2da2b-source.lock": Operation not permitted

[exit 1]
````

### evidence-provenance-0.txt

````text
$ cat /run/current-system/darwin-version.json
{
  "darwinLabel": "26.05.56c666e",
  "darwinRevision": "56c666e108467d87d13508936aade6d567f2a501",
  "nixpkgsRevision": "a0991c886dc83e6e9de01d5266e4842985b1850e"
}

[exit 0]
````

### evidence-provenance-1.txt

````text
$ nix --help
  │ Warning
  │ This program is experimental and its interface is
  │ subject to change.

Name

nix - a tool for reproducible and declarative configuration
management

Synopsis

nix [option...] subcommand

where subcommand is one of the following:

Help commands:

  · nix help - show help about nix or a particular
    subcommand
  · nix help-stores - show help about store types and their
    settings

Main commands:

  · nix build - build a derivation or fetch a store path
  · nix develop - run a bash shell that provides the build
    environment of a derivation
  · nix flake - manage Nix flakes
  · nix profile - manage Nix profiles
  · nix run - run a Nix application
  · nix search - search for packages

Main commands:

  · nix repl - start an interactive environment for
    evaluating Nix expressions

Infrequently used commands:

  · nix bundle - bundle an application so that it works
    outside of the Nix store
  · nix copy - copy paths between Nix stores
  · nix edit - open the Nix expression of a Nix package in
    $EDITOR
  · nix eval - evaluate a Nix expression
  · nix fmt - reformat your code in the standard style
  · nix formatter - build or run the formatter
  · nix log - show the build log of the specified packages
    or paths, if available
  · nix path-info - query information about store paths
  · nix registry - manage the flake registry
  · nix why-depends - show why a package has another
    package in its closure

Utility/scripting commands:

  · nix config - manipulate the Nix configuration
  · nix daemon - daemon to perform store operations on
    behalf of non-root clients
  · nix derivation - Work with derivations, Nix's notion of
    a build plan.
  · nix env - manipulate the process environment
  · nix hash - compute and convert cryptographic hashes
  · nix key - generate and convert Nix signing keys
  · nix nar - create or inspect NAR files
  · nix print-dev-env - print shell code that can be
    sourced by bash to reproduce the build environment of a
    derivation
  · nix realisation - manipulate a Nix realisation
  · nix store - manipulate a Nix store

Commands for upgrading or troubleshooting your Nix
installation:

  · nix upgrade-nix - upgrade Nix to the latest stable
    version

Examples

  · Create a new flake:

      │ # nix flake new hello
      │ # cd hello

  · Build the flake in the current directory:

      │ # nix build
      │ # ./result/bin/hello
      │ Hello, world!

  · Run the flake in the current directory:

      │ # nix run
      │ Hello, world!

  · Start a development shell for hacking on this flake:

      │ # nix develop
      │ # unpackPhase
      │ # cd hello-*
      │ # configurePhase
      │ # buildPhase
      │ # ./hello
      │ Hello, world!
      │ # installPhase
      │ # ../outputs/out/bin/hello
      │ Hello, world!

Description

Nix is a tool for building software, configurations and
other artifacts in a reproducible and declarative way. For
more information, see the Nix homepage https://nixos.org/
or the Nix manual https://nix.dev/manual/nix/stable/.

Installables

  │ Warning
  │ Installables are part of the unstable nix-command
  │ experimental feature, and subject to change without
  │ notice.

Many nix subcommands operate on one or more installables.
These are command line arguments that represent something
that can be realised in the Nix store.

The following types of installable are supported by most
commands:

  · Flake output attribute (experimental)
      · This is the default
  · Store path
      · This is assumed if the argument is a Nix store path
        or a symlink to a Nix store path
  · Nix file, optionally qualified by an attribute path
      · Specified with --file/-f
  · Nix expression, optionally qualified by an attribute
    path
      · Specified with --expr

For most commands, if no installable is specified, . is
assumed. That is, Nix will operate on the default flake
output attribute of the flake in the current directory.

### Flake output attribute

  │ Warning
  │ Flake output attribute installables depend on both the
  │ flakes and nix-command experimental features, and
  │ subject to change without notice.

Example: nixpkgs#hello

These have the form flakeref[#attrpath], where flakeref is
a flake reference and attrpath is an optional attribute
path. For more information on flakes, see the nix flake
manual page. Flake references are most commonly a flake
identifier in the flake registry (e.g. nixpkgs), or a raw
path (e.g. /path/to/my-flake or . or ../foo), or a full URL
(e.g. github:nixos/nixpkgs or path:.)

When the flake reference is a raw path (a path without any
URL scheme), it is interpreted as a path: or git+file: url
in the following way:

  · If the path is within a Git repository, then the url
    will be of the form
    git+file://[GIT_REPO_ROOT]?dir=[RELATIVE_FLAKE_DIR_PATH]
    where GIT_REPO_ROOT is the path to the root of the git
    repository, and RELATIVE_FLAKE_DIR_PATH is the path
    (relative to the directory root) of the closest parent
    of the given path that contains a flake.nix within the
    git repository. If no such directory exists, then Nix
    will error-out.

    Note that the search will only include files indexed by
    git. In particular, files which are matched by
    .gitignore or have never been git add-ed will not be
    available in the flake. If this is undesirable, specify
    path:<directory> explicitly;

    For example, if /foo/bar is a git repository with the
    following structure:

      │ .
      │ └── baz
      │   ├── blah
      │   │   └── file.txt
      │   └── flake.nix

    Then /foo/bar/baz/blah will resolve to
    git+file:///foo/bar?dir=baz

  · If the supplied path is not a git repository, then the
    url will have the form path:FLAKE_DIR_PATH where
    FLAKE_DIR_PATH is the closest parent of the supplied
    path that contains a flake.nix file (within the same
    file-system). If no such directory exists, then Nix
    will error-out.

    For example, if /foo/bar/flake.nix exists, then
    /foo/bar/baz/ will resolve to path:/foo/bar

If attrpath is omitted, Nix tries some default values; for
most subcommands, the default is packages.system.default
(e.g. packages.x86_64-linux.default), but some subcommands
have other defaults. If attrpath is specified, attrpath is
interpreted as relative to one or more prefixes; for most
subcommands, these are packages.system,
legacyPackages.*system* and the empty prefix. Thus, on
x86_64-linux nix build nixpkgs#hello will try to build the
attributes packages.x86_64-linux.hello,
legacyPackages.x86_64-linux.hello and hello.

If attrpath begins with . then no prefixes or defaults are
attempted. This allows the form flakeref[#.attrpath], such
as github:NixOS/nixpkgs#.lib.fakeSha256 to avoid a search
of packages.*system*.lib.fakeSha256

### Store path

Example:
/nix/store/10l19qifk7hjjq47px8m2prqk1gv4isy-hello-2.10

These are paths inside the Nix store, or symlinks that
resolve to a path in the Nix store.

A store derivation is also addressed by store path.

Example:
/nix/store/p7gp6lxdg32h4ka1q398wd9r2zkbbz2v-hello-2.10.drv

If you want to refer to an output path of that store
derivation, add the output name preceded by a caret (^).

Example:
/nix/store/p7gp6lxdg32h4ka1q398wd9r2zkbbz2v-hello-2.10.drv^out

All outputs can be referred to at once with the special
syntax ^*.

Example:
/nix/store/p7gp6lxdg32h4ka1q398wd9r2zkbbz2v-hello-2.10.drv^*

### Nix file

Example: --file /path/to/nixpkgs hello

When the option -f / --file path [attrpath...] is given,
installables are interpreted as the value of the expression
in the Nix file at path. If attribute paths are provided,
commands will operate on the corresponding values
accessible at these paths. The Nix expression in that file,
or any selected attribute, must evaluate to a derivation.

### Nix expression

Example: --expr 'import <nixpkgs> {}' hello

When the option --expr expression [attrpath...] is given,
installables are interpreted as the value of the of the Nix
expression. If attribute paths are provided, commands will
operate on the corresponding values accessible at these
paths. The Nix expression, or any selected attribute, must
evaluate to a derivation.

You may need to specify --impure if the expression
references impure inputs (such as <nixpkgs>).

## Derivation output selection

Derivations can have multiple outputs, each corresponding
to a different store path. For instance, a package can have
a bin output that contains programs, and a dev output that
provides development artifacts like C/C++ header files. The
outputs on which nix commands operate are determined as
follows:

  · You can explicitly specify the desired outputs using
    the syntax installable^output1,...,outputN — that is,
    a caret followed immediately by a comma-separated list
    of derivation outputs to select. For installables
    specified as Flake output attributes or Store paths,
    the output is specified in the same argument:

    For example, you can obtain the dev and static outputs
    of the glibc package:

      │ # nix build 'nixpkgs#glibc^dev,static'
      │ # ls ./result-dev/include/ ./result-static/lib/
      │ …

    and likewise, using a store path to a "drv" file to
    specify the derivation:

      │ # nix build '/nix/store/fpq78s2h8ffh66v2iy0q1838mhff06y8-glibc-2.33-78.drv^dev,static'
      │ …

    For --expr and -f/--file, the derivation output is
    specified as part of the attribute path:

      │ $ nix build -f '<nixpkgs>' 'glibc^dev,static'
      │ $ nix build --impure --expr 'import <nixpkgs> { }' 'glibc^dev,static'

    This syntax is the same even if the actual attribute
    path is empty:

      │ $ nix build --impure --expr 'let pkgs = import <nixpkgs> { }; in pkgs.glibc' '^dev,static'

  · You can also specify that all outputs should be used
    using the syntax installable^*. For example, the
    following shows the size of all outputs of the glibc
    package in the binary cache:

      │ # nix path-info --closure-size --eval-store auto --store https://cache.nixos.org 'nixpkgs#glibc^*'
      │ /nix/store/i2fn2mjgihz960bwa7ldab5ra5fhxznh-glibc-2.33-123                 33208200
      │ /nix/store/n2wnn3i47w6dbylh64hdjzgd5rrprdn8-glibc-2.33-123-bin             36142896
      │ /nix/store/v7dyz518sbkzl8x2a1sgk1lwsfd3d6gm-glibc-2.33-123-debug          155787312
      │ /nix/store/z4hv6ybyinqw9a3dwyl5k66a91aggylj-glibc-2.33-123-static          42488328
      │ /nix/store/lrjirf0j1rjnvif6amyp9pfcqr2km385-glibc-2.33-123-dev             44200560

    and likewise, using a store path to a "drv" file to
    specify the derivation:

      │ # nix path-info --closure-size '/nix/store/fpq78s2h8ffh66v2iy0q1838mhff06y8-glibc-2.33-78.drv^*'
      │ …

  · If you didn't specify the desired outputs, but the
    derivation has an attribute meta.outputsToInstall, Nix
    will use those outputs. For example, since the package
    nixpkgs#libxml2 has this attribute:

      │ # nix eval 'nixpkgs#libxml2.meta.outputsToInstall'
      │ [ "bin" "man" ]

    a command like nix shell nixpkgs#libxml2 will provide
    only those two outputs by default.

    Note that a store derivation doesn't have any
    attributes like meta, and thus this case doesn't apply
    to it.

  · Otherwise, Nix will use all outputs of the derivation.

Nix stores

Most nix subcommands operate on a Nix store. The various
store types are documented in the Store Types section of
the manual.

The same information is also available from the nix
help-stores command.

Shebang interpreter

The nix command can be used as a #! interpreter. Arguments
to Nix can be passed on subsequent lines in the script.

Verbatim strings may be passed in double backtick (``)
quotes. <!-- that's markdown for two backticks in inline
code. --> Sequences of n backticks of 3 or longer are
parsed as n-1 literal backticks. A single space before the
closing `` is ignored if present.

--file and --expr resolve relative paths based on the
script location.

Examples:

  │ #!/usr/bin/env nix
  │ #! nix shell --file ``<nixpkgs>`` hello cowsay --command bash
  │
  │ hello | cowsay

or with flakes:

  │ #!/usr/bin/env nix
  │ #! nix shell nixpkgs#bash nixpkgs#hello nixpkgs#cowsay --command bash
  │
  │ hello | cowsay

or with an expression:

  │ #! /usr/bin/env nix
  │ #! nix shell --impure --expr ``
  │ #! nix with (import (builtins.getFlake "nixpkgs") {});
  │ #! nix terraform.withPlugins (plugins: [ plugins.openstack ])
  │ #! nix ``
  │ #! nix --command bash
  │
  │ terraform "$@"

or with cascading interpreters. Note that the #! nix lines
don't need to follow after the first line, to accommodate
other interpreters.

  │ #!/usr/bin/env nix
  │ //! ```cargo
  │ //! [dependencies]
  │ //! time = "0.1.25"
  │ //! ```
  │ /*
  │ #!nix shell nixpkgs#rustc nixpkgs#rust-script nixpkgs#cargo --command rust-script
  │ */
  │ fn main() {
  │     for argument in std::env::args().skip(1) {
  │         println!("{}", argument);
  │     };
  │     println!("{}", std::env::var("HOME").expect(""));
  │     println!("{}", time::now().rfc822z());
  │ }
  │ // vim: ft=rust

Options

## Logging-related options

  · --debug

    Set the logging verbosity level to 'debug'.

  · --log-format format

    Set the format of log output; one of raw, internal-json,
    bar or bar-with-logs.

  · --print-build-logs / -L

    Print full build logs on standard error.

  · --quiet

    Decrease the logging verbosity level.

  · --verbose / -v

    Increase the logging verbosity level.

## Miscellaneous global options

  · --help

    Show usage information.

  · --offline

    Disable substituters and consider all previously
    downloaded files up-to-date.

  · --option name value

    Set the Nix configuration setting name to value
    (overriding nix.conf).

  · --refresh

    Consider all previously downloaded files out-of-date.

  · --version

    Show version information.

  │ Note
  │
  │ See man nix.conf for overriding configuration settings
  │ with command line flags.


[exit 0]
````

### evidence-provenance-2.txt

````text
$ darwin-version --help
darwin-version [--help|--darwin-revision|--nixpkgs-revision|--configuration-revision|--json]

[exit 0]
````

### evidence-provenance-extra.txt

````text
$ python3 docs/goals/01-checkup/collect-provenance.py
Installer receipt top-level keys: ['version', 'actions', 'planner']
version: 0.17.1
planner keys: ['planner', 'settings', 'encrypt', 'case_sensitive', 'volume_label', 'root_disk']
planner.planner: macos
/nix/var/nix/profiles/system-34-link: link_mtime=2026-05-23T17:51:27.598955+00:00 target=/nix/store/5vylcskg3kzqc55b9nb71x9hxkhnnx63-darwin-system-26.05.56c666e
/nix/var/nix/profiles/system-33-link: link_mtime=2026-05-23T17:28:21.609234+00:00 target=/nix/store/vag38lqycg2nrdd61j0jbxl2hsnny3l7-darwin-system-26.05.56c666e
DIRECTORY /Users/fdm/.local/state/nix/profiles
channels-1-link -> /nix/store/57904rflsfh46y7fxi62rzc7sidc9vmq-user-environment
home-manager -> home-manager-20-link
home-manager-20-link -> /nix/store/j6pm1y261zs5d3bhcilpfvlxfii4jl90-home-manager-generation
profile -> profile-14-link
profile-14-link -> /nix/store/dijbcyn6hmp7qpxfxyb1md0fjrqsdq62-user-environment
channels -> channels-1-link
DIRECTORY /Users/fdm/.local/state/home-manager
gcroots -> [entry]
DIRECTORY /run/current-system/user
Library -> [entry]
$ git log -1 --format=%H %cI %s -- machines/m2-macbook-air.nix
8612229f7c2abc47ddc90e2f0e174962cf93ba9b 2025-11-29T14:02:42+01:00 fix: previous squashed commit reverted some changes

[exit 0]
$ git log -1 --format=%H %cI %s -- machines/vps.nix
8612229f7c2abc47ddc90e2f0e174962cf93ba9b 2025-11-29T14:02:42+01:00 fix: previous squashed commit reverted some changes

[exit 0]
$ git log -1 --format=%H %cI %s -- modules/nixos-base.nix
8612229f7c2abc47ddc90e2f0e174962cf93ba9b 2025-11-29T14:02:42+01:00 fix: previous squashed commit reverted some changes

[exit 0]
$ git ls-files .github .gitlab-ci.yml .buildkite secrets .sops.yaml

[exit 0]
$ rg -l -i agenix|sops|password|secret|backup|restic|borg --glob *.nix .
./modules/nixos-base.nix
./machines/vps.nix
./machines/m2-macbook-air.nix

[exit 0]
````

### evidence-repo.txt

````text
$ date -u; git status --short; git rev-parse HEAD; git log -8 --format="%H %cI %s"; git log -1 --format="%H %cI %s" -- machines/m2-macbook-air.nix profiles/home-darwin.nix; git log -1 --format="%H %cI %s" -- machines/vps.nix profiles/home-vps.nix; rg --files --hidden -g "!.git/**" -g "!docs/goals/01-checkup/**"; cat AGENTS.md README.md flake.nix flake.lock; git diff -- profiles/home-darwin.nix
Fri Sep 25 17:38:11 UTC 2026
 M profiles/home-darwin.nix
?? AGENTS.md
?? docs/
b335654465345dbc9bd283bfbaebb2ce31adb890
b335654465345dbc9bd283bfbaebb2ce31adb890 2026-05-23T20:09:52+02:00 chore: upate flake.lock
2e38cb0fd1951c32c7428ed5ce35d0e9502e9c3c 2026-05-23T20:08:50+02:00 fix: clean up, add Notion
e886ece100d9b21e594a37316d15ccfa2888fc8d 2025-11-29T14:15:22+01:00 chore: resolve divergence
8612229f7c2abc47ddc90e2f0e174962cf93ba9b 2025-11-29T14:02:42+01:00 fix: previous squashed commit reverted some changes
f881a29139be9332bcd68475a18e7723199ca298 2025-11-29T13:42:46+01:00 chore: update; clean up repo structure
ecfadaf7358cd128103803db43a68a8e5feb80a4 2025-11-28T16:12:34+01:00 Successfully deploy package migration: obsidian and cmake now via Nix, homebrew temporarily disabled
4d2ef692a57011f6dc49e20ee2d6dd7444e71d6b 2025-11-28T16:11:17+01:00 Adjust package migration: move openscad back to Homebrew due to Qt5 build issues
baa80bd5f8b5ca2b0834239a4a0ac06b68482645 2025-11-28T16:08:31+01:00 Migrate packages: move obsidian, openscad, cmake to Nix; keep rar, steam in Homebrew
2e38cb0fd1951c32c7428ed5ce35d0e9502e9c3c 2026-05-23T20:08:50+02:00 fix: clean up, add Notion
2e38cb0fd1951c32c7428ed5ce35d0e9502e9c3c 2026-05-23T20:08:50+02:00 fix: clean up, add Notion
modules/git.nix
modules/nixos-base.nix
modules/zsh.nix
profiles/home-darwin.nix
profiles/home-vps.nix
AGENTS.md
machines/vps.nix
machines/m2-macbook-air.nix
flake.nix
README.md
hardware/vultr-vps.nix
flake.lock
# Repository Guidelines

## Project Structure & Module Organization

This repository manages personal NixOS and nix-darwin systems through a Nix flake.

- `flake.nix` declares inputs and the `vps` (`x86_64-linux`) and `m2-macbook-air` (`aarch64-darwin`) configurations; `flake.lock` pins dependencies.
- `machines/` contains host-specific system settings and services.
- `hardware/vultr-vps.nix` contains VPS hardware configuration.
- `profiles/home-vps.nix` and `profiles/home-darwin.nix` define platform-specific Home Manager packages and settings.
- `modules/` contains shared Git and Zsh configuration plus the Linux-only `nixos-base.nix` module.

There are no separate application sources, assets, or test directories. Keep reusable settings in modules and host-specific settings in machines or profiles.

## Build, Test, and Development Commands

Run commands from the repository root with Nix flakes enabled:

- `nix flake check`: perform flake validation; this is not a substitute for building the affected host.
- `nix build .#nixosConfigurations.vps.config.system.build.toplevel`: build the VPS system without activating it.
- `nix build .#darwinConfigurations.m2-macbook-air.system`: build the macOS system without activating it.
- `sudo nixos-rebuild switch --flake .#vps`: apply the local configuration on the VPS.
- `sudo darwin-rebuild switch --flake .#m2-macbook-air`: apply the local configuration on the Mac.
- `nix flake update`: update dependency pins; review the resulting lockfile diff.

Build on the matching platform or use a compatible remote builder. Activate only on the intended host after reviewing the build.

## Coding Style & Naming Conventions

Use two-space indentation and existing Nix attribute-set conventions. Use descriptive, lowercase, hyphen-separated filenames such as `home-darwin.nix`. Keep Linux-only modules out of Darwin imports. No formatter or linter is configured; follow surrounding style and avoid unrelated reformatting.

## Testing Guidelines

No dedicated test framework or coverage threshold exists. Validate changes by building the affected configuration. For shared modules, validate both hosts when possible. Report commands run and platform limitations in the pull request.

## Commit & Pull Request Guidelines

Recent commits commonly use `fix:` and `chore:` prefixes, alongside older descriptive subjects. Prefer concise, imperative subjects and focused commits. Pull requests should explain the change, affected hosts, validation results, and any activation or migration steps. Link relevant issues when applicable.

## Configuration Safety

Do not add credentials or private keys. Preserve state-version values unless intentionally performing a documented migration. Review mailserver, SSH, and bootloader changes carefully before activation.
[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

# nixos
This is my personal NixOS and Nix-Darwin configuration.

## Repository Structure
### /machines/
System configuration for my various hosts (both NixOS and Darwin). Each machine references a home-manager profile for module management.
### /hardware/
Hardware specifics for computers on which systems defined in /machines/ may be hosted.
### /profiles/
Home-manager configurations organized by platform:
- `/darwin/` - macOS-specific home-manager configuration
- `/vps/` - VPS-specific home-manager configuration
- `/shared/` - Shared base configuration used across platforms
### /modules/
Home-manager module configurations shared by all profiles (git, zsh, etc.).

## Installation

### NixOS
```bash
sudo nixos-rebuild switch --flake github:maurerf/nixos#vps
```

### Darwin (macOS)
```bash
darwin-rebuild switch --flake github:maurerf/nixos#m2-macbook-air
```


## Configurations
| Configuration               | Description                                                                                                                          | Type      |
|-----------------------------|--------------------------------------------------------------------------------------------------------------------------------------|-----------|
| `vps`                       | NixOS configuration for VPS hosting email server with mailserver module integration.                                                | NixOS     |
| `m2-macbook-air`            | Darwin configuration for M2 MacBook Air with development tools and desktop applications.                                            | Darwin    |
{
  description = "maurerf's personal NixOS and nix-darwin flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, simple-nixos-mailserver, nix-darwin }:
  let
    nixosSystem = "x86_64-linux";
    darwinSystem = "aarch64-darwin";
  in
  {
    nixosConfigurations = {
      "vps" = nixpkgs.lib.nixosSystem {
        system = nixosSystem;
        specialArgs = { inherit inputs; };
        modules = [
          ./machines/vps.nix
          ./hardware/vultr-vps.nix
          simple-nixos-mailserver.nixosModules.mailserver
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./profiles/home-vps.nix;
          }
        ];
      };
    };

    darwinConfigurations = {
      "m2-macbook-air" = nix-darwin.lib.darwinSystem {
        system = darwinSystem;
        modules = [
          ./machines/m2-macbook-air.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./profiles/home-darwin.nix;
          }
        ];
      };
    };
  };
}
{
  "nodes": {
    "blobs": {
      "flake": false,
      "locked": {
        "lastModified": 1604995301,
        "narHash": "sha256-wcLzgLec6SGJA8fx1OEN1yV/Py5b+U5iyYpksUY/yLw=",
        "owner": "simple-nixos-mailserver",
        "repo": "blobs",
        "rev": "2cccdf1ca48316f2cfd1c9a0017e8de5a7156265",
        "type": "gitlab"
      },
      "original": {
        "owner": "simple-nixos-mailserver",
        "repo": "blobs",
        "type": "gitlab"
      }
    },
    "flake-compat": {
      "flake": false,
      "locked": {
        "lastModified": 1767039857,
        "narHash": "sha256-vNpUSpF5Nuw8xvDLj2KCwwksIbjua2LZCqhV1LNRDns=",
        "owner": "NixOS",
        "repo": "flake-compat",
        "rev": "5edf11c44bc78a0d334f6334cdaf7d60d732daab",
        "type": "github"
      },
      "original": {
        "owner": "NixOS",
        "repo": "flake-compat",
        "type": "github"
      }
    },
    "git-hooks": {
      "inputs": {
        "flake-compat": [
          "simple-nixos-mailserver",
          "flake-compat"
        ],
        "gitignore": "gitignore",
        "nixpkgs": [
          "simple-nixos-mailserver",
          "nixpkgs"
        ]
      },
      "locked": {
        "lastModified": 1778507602,
        "narHash": "sha256-kTwur1wV+01SdqskVMSo6JMEpg71ps3HpbFY2GsflKs=",
        "owner": "cachix",
        "repo": "git-hooks.nix",
        "rev": "61ab0e80d9c7ab14c256b5b453d8b3fb0189ba0a",
        "type": "github"
      },
      "original": {
        "owner": "cachix",
        "repo": "git-hooks.nix",
        "type": "github"
      }
    },
    "gitignore": {
      "inputs": {
        "nixpkgs": [
          "simple-nixos-mailserver",
          "git-hooks",
          "nixpkgs"
        ]
      },
      "locked": {
        "lastModified": 1709087332,
        "narHash": "sha256-HG2cCnktfHsKV0s4XW83gU3F57gaTljL9KNSuG6bnQs=",
        "owner": "hercules-ci",
        "repo": "gitignore.nix",
        "rev": "637db329424fd7e46cf4185293b9cc8c88c95394",
        "type": "github"
      },
      "original": {
        "owner": "hercules-ci",
        "repo": "gitignore.nix",
        "type": "github"
      }
    },
    "home-manager": {
      "inputs": {
        "nixpkgs": [
          "nixpkgs"
        ]
      },
      "locked": {
        "lastModified": 1779507042,
        "narHash": "sha256-7wOwi8B6D0BYsieZCnHZZj2sNUzgJhLoIVSfkwB7lxQ=",
        "owner": "nix-community",
        "repo": "home-manager",
        "rev": "509ed3c603349a9d43de9e2ae6613baea6bd5b34",
        "type": "github"
      },
      "original": {
        "owner": "nix-community",
        "ref": "master",
        "repo": "home-manager",
        "type": "github"
      }
    },
    "nix-darwin": {
      "inputs": {
        "nixpkgs": [
          "nixpkgs"
        ]
      },
      "locked": {
        "lastModified": 1779036909,
        "narHash": "sha256-zXcwYQGCT6pzinK+1dBB2ekTVtfxGZAapb3Evdcu4fY=",
        "owner": "LnL7",
        "repo": "nix-darwin",
        "rev": "56c666e108467d87d13508936aade6d567f2a501",
        "type": "github"
      },
      "original": {
        "owner": "LnL7",
        "ref": "master",
        "repo": "nix-darwin",
        "type": "github"
      }
    },
    "nixpkgs": {
      "locked": {
        "lastModified": 1779475168,
        "narHash": "sha256-gm3D4FF9EcZlXK/ZnsC6IYzpEQplOoT+LPTurzOPyrk=",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "a0991c886dc83e6e9de01d5266e4842985b1850e",
        "type": "github"
      },
      "original": {
        "owner": "NixOS",
        "ref": "nixpkgs-unstable",
        "repo": "nixpkgs",
        "type": "github"
      }
    },
    "root": {
      "inputs": {
        "home-manager": "home-manager",
        "nix-darwin": "nix-darwin",
        "nixpkgs": "nixpkgs",
        "simple-nixos-mailserver": "simple-nixos-mailserver"
      }
    },
    "simple-nixos-mailserver": {
      "inputs": {
        "blobs": "blobs",
        "flake-compat": "flake-compat",
        "git-hooks": "git-hooks",
        "nixpkgs": [
          "nixpkgs"
        ]
      },
      "locked": {
        "lastModified": 1779379045,
        "narHash": "sha256-hm23mKusHpY1LdEm0ixJTZB7lOji8VAC68Kl2GkIr1g=",
        "owner": "simple-nixos-mailserver",
        "repo": "nixos-mailserver",
        "rev": "61e9c248c5b6296a1132e9b42811fce686bd9f7f",
        "type": "gitlab"
      },
      "original": {
        "owner": "simple-nixos-mailserver",
        "repo": "nixos-mailserver",
        "type": "gitlab"
      }
    }
  },
  "root": "root",
  "version": 7
}
diff --git a/profiles/home-darwin.nix b/profiles/home-darwin.nix
index b031e24..4673c29 100644
--- a/profiles/home-darwin.nix
+++ b/profiles/home-darwin.nix
@@ -24,4 +24,5 @@
     ../modules/zsh.nix
   ];
   fonts.fontconfig.enable = true;
+  targets.darwin.linkApps.enable = true;
 }

[exit 0]
````

### evidence-show.txt

````text
$ nix --offline --store 'local?read-only=true' --option allow-import-from-derivation false --option eval-cache false --option max-jobs 0 --option builders '' flake show --no-write-lock-file .
error: experimental Nix feature 'read-only-local-store' is disabled; add '--extra-experimental-features read-only-local-store' to enable it

[exit 1]
$ nix --extra-experimental-features read-only-local-store --offline --store 'local?read-only=true' --option allow-import-from-derivation false --option eval-cache false --option max-jobs 0 --option builders '' flake show --no-write-lock-file .
warning: Git tree '/Users/fdm/git/nixos' is dirty
error: opening lock file "/nix/store/11l5zyj8qzc3b6mcrjhgvrzwcva2da2b-source.lock": Operation not permitted

[exit 1]
````

### evidence-static.txt

````text
$ python3 docs/goals/01-checkup/inspect-static.py
FILE flake.nix
1: {
2:   description = "maurerf's personal NixOS and nix-darwin flake";
3:
4:   inputs = {
5:     nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
6:     nix-darwin = {
7:       url = "github:LnL7/nix-darwin/master";
8:       inputs.nixpkgs.follows = "nixpkgs";
9:     };
10:     home-manager = {
11:       url = "github:nix-community/home-manager/master";
12:       inputs.nixpkgs.follows = "nixpkgs";
13:     };
14:     simple-nixos-mailserver = {
15:       url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
16:       inputs.nixpkgs.follows = "nixpkgs";
17:     };
18:   };
19:
20:   outputs = inputs @ { self, nixpkgs, home-manager, simple-nixos-mailserver, nix-darwin }:
21:   let
22:     nixosSystem = "x86_64-linux";
23:     darwinSystem = "aarch64-darwin";
24:   in
25:   {
26:     nixosConfigurations = {
27:       "vps" = nixpkgs.lib.nixosSystem {
28:         system = nixosSystem;
29:         specialArgs = { inherit inputs; };
30:         modules = [
31:           ./machines/vps.nix
32:           ./hardware/vultr-vps.nix
33:           simple-nixos-mailserver.nixosModules.mailserver
34:           home-manager.nixosModules.home-manager
35:           {
36:             home-manager.useGlobalPkgs = true;
37:             home-manager.users.fdm = ./profiles/home-vps.nix;
38:           }
39:         ];
40:       };
41:     };
42:
43:     darwinConfigurations = {
44:       "m2-macbook-air" = nix-darwin.lib.darwinSystem {
45:         system = darwinSystem;
46:         modules = [
47:           ./machines/m2-macbook-air.nix
48:           home-manager.darwinModules.home-manager
49:           {
50:             home-manager.useGlobalPkgs = true;
51:             home-manager.users.fdm = ./profiles/home-darwin.nix;
52:           }
53:         ];
54:       };
55:     };
56:   };
57: }
FILE hardware/vultr-vps.nix
1: # Do not modify this file!  It was generated by ‘nixos-generate-config’
2: # and may be overwritten by future invocations.  Please make changes
3: # to /etc/nixos/configuration.nix instead.
4: { lib, ... }:
5:
6: {
7:   imports = [ ];
8:
9:   boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
10:   boot.initrd.kernelModules = [ ];
11:   boot.kernelModules = [ ];
12:   boot.extraModulePackages = [ ];
13:
14:   fileSystems."/" =
15:     { device = "/dev/disk/by-uuid/70cbc760-a105-4f62-81a1-8ba58f5982fa";
16:       fsType = "ext4";
17:     };
18:
19:   swapDevices =
20:     [ { device = "/dev/disk/by-uuid/148323ff-b2d9-4c11-aa06-d46d0684ce5a"; }
21:     ];
22:
23:   # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
24:   # (the default) this is the recommended approach. When using systemd-networkd it's
25:   # still possible to use this option, but it's recommended to use it in conjunction
26:   # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
27:   networking.useDHCP = lib.mkDefault true;
28:   # networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;
29:
30:   nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
31:   virtualisation.hypervGuest.enable = true;
32: }
FILE machines/m2-macbook-air.nix
1: { config, pkgs, ... }:
2:
3: {
4:   imports = [
5:     # Note: modules/nixos-base.nix is Linux-specific, so we don't import it for Darwin
6:   ];
7:
8:   services.openssh.enable = true;
9:
10:   nix.settings.experimental-features = "nix-command flakes";
11:   nix.channel.enable = false;
12:
13:   # Nix-darwin stateVersion - represents the nix-darwin release version when this config was first created
14:   # This helps maintain backwards compatibility during system upgrades
15:   system.stateVersion = 5;
16:
17:   nixpkgs.hostPlatform = "aarch64-darwin";
18:   nixpkgs.config.allowUnfree = true;
19:
20:   users.users.fdm = {
21:     name = "fdm";
22:     home = "/Users/fdm";
23:   };
24:
25:   system.primaryUser = "fdm";
26:   # Homebrew as backup utility - minimal integration to avoid changes during activation
27:   homebrew = {
28:     enable = true;
29:     # No packages managed by nix-darwin - use Homebrew manually when needed
30:     brews = [];
31:     casks = [];
32:     onActivation = {
33:       cleanup = "none";        # Never cleanup nix-darwin managed packages (preserves manual installs)
34:       upgrade = false;         # Sets HOMEBREW_BUNDLE_NO_UPGRADE=1 (same effect as --no-upgrade)
35:       autoUpdate = false;      # Prevents Homebrew itself from auto-updating during activation
36:     };
37:   };
38: }
FILE machines/vps.nix
1: { ... }:
2:
3: {
4:   imports =
5:     [
6:       ../modules/nixos-base.nix
7:     ];
8:
9:   networking.hostName = "nixos-vps";
10:
11:   boot.loader.grub.enable = true;
12:   boot.loader.grub.device = "nodev";
13:   #boot.loader.grub.efiSupport = true;
14:   #boot.loader.grub.useOSProber = true;
15:
16:   # https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/issues/275
17:   services.dovecot2.sieve.extensions = [ "fileinto" ];
18:
19:   # Mailserver
20:   mailserver = {
21:     enable = true;
22:     fqdn = "mail.maurerf.com";
23:     domains = [ "maurerf.com" ];
24:
25:     loginAccounts = {
26:       "felix@maurerf.com" = {
27: [credential-related line present; value omitted]
28:         aliases = ["contact@maurerf.com"];
29:         name = "Felix Maurer";
30:       };
31:     };
32:
33:     # Use Let's Encrypt certificates. Note that this needs to set up a stripped
34:     # down nginx and opens port 80.
35:     certificateScheme = "acme-nginx";
36:     stateVersion = 3;
37:   };
38:   security.acme.acceptTerms = true;
39:   security.acme.defaults.email = "contact@maurerf.com";
40: }
FILE modules/git.nix
1: { pkgs, lib, ... }:
2:
3: {
4:   programs.git = {
5:     enable = true;
6:     settings = {
7:       user.name = "Felix Maurer";
8:       user.email = "felix@maurerf.com";
9:       pull.rebase = false;
10:     };
11:   };
12: }
FILE modules/nixos-base.nix
1: { config, pkgs, ... }:
2:
3: {
4:   # NOTE: as this base module is hardware agnostic, you need to adjust boot loader settings locally before rebuilding
5:
6:   services.openssh.enable = true;
7:
8:   networking.networkmanager.enable = true;
9:
10:   time.timeZone = "Europe/Berlin";
11:   i18n.defaultLocale = "en_US.UTF-8";
12:   i18n.extraLocaleSettings = {
13:     LC_ADDRESS = "de_DE.UTF-8";
14:     LC_IDENTIFICATION = "de_DE.UTF-8";
15:     LC_MEASUREMENT = "de_DE.UTF-8";
16:     LC_MONETARY = "de_DE.UTF-8";
17:     LC_NAME = "de_DE.UTF-8";
18:     LC_NUMERIC = "de_DE.UTF-8";
19:     LC_PAPER = "de_DE.UTF-8";
20:     LC_TELEPHONE = "de_DE.UTF-8";
21:     LC_TIME = "de_DE.UTF-8";
22:   };
23:
24:   console.keyMap = "de";
25:
26:   programs.zsh.enable = true;
27:   users.defaultUserShell = pkgs.zsh;
28:
29:   users.users.fdm = {
30:     isNormalUser = true;
31: [credential-related line present; value omitted]
32:     extraGroups = [ "wheel" ];
33:    };
34:
35:   nixpkgs.config.allowUnfree = false;
36:
37:   nix.settings.experimental-features = [ "nix-command" "flakes" ];
38:   system.stateVersion = "24.05";
39: }
FILE modules/zsh.nix
1: { pkgs, lib, ... }:
2:
3: {
4:   programs.zsh = {
5:     enable = true;
6:     autosuggestion.enable = true;
7:     enableCompletion = true;
8:     oh-my-zsh = {
9:        enable = true;
10:     };
11:   };
12: }
FILE profiles/home-darwin.nix
1: { pkgs, config, lib, ... }:
2: {
3:   home.username = "fdm";
4:   home.stateVersion = "24.05";
5:   home.packages = with pkgs; [
6:     vim
7:     htop
8:     vscode
9:     # spotify  # Temporarily disabled due to hash mismatch
10:     keepassxc
11:     notion-app
12:     telegram-desktop
13:     obsidian
14:     anki-bin
15:     rar
16:     pkgs.nerd-fonts.fira-code
17:     pkgs.nerd-fonts.droid-sans-mono
18:   ];
19:   programs.home-manager = {
20:     enable = true;
21:   };
22:   imports = [
23:     ../modules/git.nix
24:     ../modules/zsh.nix
25:   ];
26:   fonts.fontconfig.enable = true;
27:   targets.darwin.linkApps.enable = true;
28: }
FILE profiles/home-vps.nix
1: { pkgs, config, ... }:
2: {
3:   home.username = "fdm";
4:   home.stateVersion = "24.05";
5:   home.packages = with pkgs; [
6:     vim
7:     htop
8:     pkgs.nerd-fonts.fira-code
9:     pkgs.nerd-fonts.droid-sans-mono
10:   ];
11:   programs.home-manager = {
12:     enable = true;
13:   };
14:   imports = [
15:     ../modules/git.nix
16:     ../modules/zsh.nix
17:   ];
18:   fonts.fontconfig.enable = true;
19: }
PIN blobs: 2cccdf1ca48316f2cfd1c9a0017e8de5a7156265 2020-11-10T08:01:41+00:00 age_days=2145 ref=unspecified
PIN flake-compat: 5edf11c44bc78a0d334f6334cdaf7d60d732daab 2025-12-29T20:24:17+00:00 age_days=269 ref=unspecified
PIN git-hooks: 61ab0e80d9c7ab14c256b5b453d8b3fb0189ba0a 2026-05-11T13:53:22+00:00 age_days=137 ref=unspecified
PIN gitignore: 637db329424fd7e46cf4185293b9cc8c88c95394 2024-02-28T02:28:52+00:00 age_days=940 ref=unspecified
PIN home-manager: 509ed3c603349a9d43de9e2ae6613baea6bd5b34 2026-05-23T03:30:42+00:00 age_days=125 ref=master
PIN nix-darwin: 56c666e108467d87d13508936aade6d567f2a501 2026-05-17T16:55:09+00:00 age_days=131 ref=master
PIN nixpkgs: a0991c886dc83e6e9de01d5266e4842985b1850e 2026-05-22T18:39:28+00:00 age_days=125 ref=nixpkgs-unstable
PIN simple-nixos-mailserver: 61e9c248c5b6296a1132e9b42811fce686bd9f7f 2026-05-21T15:57:25+00:00 age_days=127 ref=unspecified
CONFIG /etc/nix/nix.conf: exists=True symlink=True
allowed-users = *
auto-optimise-store = false
build-users-group = nixbld
[other setting omitted to avoid exposing credentials]
[other setting omitted to avoid exposing credentials]
experimental-features = nix-command flakes
[other setting omitted to avoid exposing credentials]
[other setting omitted to avoid exposing credentials]
sandbox = false
[other setting omitted to avoid exposing credentials]
[other setting omitted to avoid exposing credentials]
[other setting omitted to avoid exposing credentials]
[other setting omitted to avoid exposing credentials]
trusted-users = root
[other setting omitted to avoid exposing credentials]
CONFIG /etc/nix/nix.custom.conf: exists=False symlink=False
CONFIG /Users/fdm/.config/nix/nix.conf: exists=False symlink=False
DIRECTORY /nix/var/nix/profiles
default -> /nix/var/nix/profiles/per-user/root/profile
per-user -> [entry]
system -> system-34-link
system-1-link -> /nix/store/f9kmxiap1rpl9pc9s28rpj89jvyxkc3a-darwin-system-25.05.678b226
system-10-link -> /nix/store/snvf5fxs5lz44q56dwmskpid6k5ki05n-darwin-system-25.11.425c929
system-11-link -> /nix/store/xhpwljgv2l7s9mx06kdxqahwbd84w9gi-darwin-system-25.11.425c929
system-12-link -> /nix/store/z3pa9wv8x5sml63dqbv8cswmrgccj7ck-darwin-system-25.11.425c929
system-13-link -> /nix/store/x7n3syva47cwxnz9lwv03g9sziy75pzl-darwin-system-25.05.0b6f96a
system-14-link -> /nix/store/yq2jwksppppxpm3051x7crfryrmhjw8w-darwin-system-25.05.0b6f96a
system-15-link -> /nix/store/4ydh83c7z95d74m45fgwzxgf22l5m6z5-darwin-system-25.05.0b6f96a
system-16-link -> /nix/store/m2y5khg99x49kaiw4k1i3rc4hannqr1f-darwin-system-25.05.0b6f96a
system-17-link -> /nix/store/4dw0j0gfy12km2lfjg7mp5czmpqn900w-darwin-system-25.05.0b6f96a
system-18-link -> /nix/store/qqqkqflba9jv2jhx1j0sxwlzwkw2kd3y-darwin-system-25.05.0b6f96a
system-19-link -> /nix/store/yakfl9k6zm4c9387cmra8jfzf8wzp011-darwin-system-25.11.e95de00
system-2-link -> /nix/store/2kf0k02kjfgd0aj69mmqpwhqfch7ym5q-darwin-system-25.05.678b226
system-20-link -> /nix/store/ba7azkfkfqhghgf89pv08wza4l02x6qs-darwin-system-25.11.e95de00
system-21-link -> /nix/store/9bw8ky8frwdcdkaqrzf53nlsi26wyyyk-darwin-system-25.11.e95de00
system-22-link -> /nix/store/papxl9mxm7499v45v88jkvq3gvbrxcjg-darwin-system-25.11.e95de00
system-23-link -> /nix/store/swnzbnhi09z50kiyfqx41592acbqdwf0-darwin-system-25.11.e95de00
system-24-link -> /nix/store/hifa2syvl0wkc0jaj1hgyrdd97qfd1aw-darwin-system-25.11.e95de00
system-25-link -> /nix/store/swnzbnhi09z50kiyfqx41592acbqdwf0-darwin-system-25.11.e95de00
system-26-link -> /nix/store/chk75l1bybdfvclxrysqak96h366qb4x-darwin-system-25.11.e95de00
system-27-link -> /nix/store/xfwvkkm1jm7cnrk9bh8bkmh1cb8ylw66-darwin-system-25.11.e95de00
system-28-link -> /nix/store/cnkxni0hjqizqa5bzx186c1wnv9d7zqm-darwin-system-25.11.e95de00
system-29-link -> /nix/store/7xacvpm7wy0f885m9kci3g8sx2mq0jdw-darwin-system-25.11.e95de00
system-3-link -> /nix/store/8jkb7sndw2wr9m8r36ippz023i24311p-darwin-system-25.05.678b226
system-30-link -> /nix/store/cq1ksd5w8d0khxlcscivgj5dsidmjzxr-darwin-system-25.11.e95de00
system-31-link -> /nix/store/jj564pckmnm27a9f8zfffgzpszf6zh0w-darwin-system-25.11.e95de00
system-32-link -> /nix/store/5gv0rsx2nyi7ipcpxa496nj1mmjl2j1w-darwin-system-25.11.e95de00
system-33-link -> /nix/store/vag38lqycg2nrdd61j0jbxl2hsnny3l7-darwin-system-26.05.56c666e
system-34-link -> /nix/store/5vylcskg3kzqc55b9nb71x9hxkhnnx63-darwin-system-26.05.56c666e
system-4-link -> /nix/store/sh6sx2ajjhh3kb4km76znkfrcfcnl3bx-darwin-system-25.05.678b226
system-5-link -> /nix/store/hf2h759bmrl22fz36ar8d8m0v6b9fd2r-darwin-system-25.05.bb81755
system-6-link -> /nix/store/wc4afmy0sf89ghx9sysz7lxqrq9qmmmx-darwin-system-25.05.678b226
system-7-link -> /nix/store/pxibb3mg9zfpflikx7f7kc3w9miqfq10-darwin-system-25.05.bb81755
system-8-link -> /nix/store/3sk1c9qskv0rnws22zqvj9pjfcwzmwhf-darwin-system-25.05.bb81755
system-9-link -> /nix/store/n8g9sli9cpwwfg6pmmnfq0kn1kgkz6hz-darwin-system-25.05.bb81755
DIRECTORY /nix/var/nix/profiles/per-user/fdm
[Errno 2] No such file or directory: '/nix/var/nix/profiles/per-user/fdm'
DIRECTORY /nix/var/nix/profiles/per-user/root
profile -> profile-2-link
profile-1-link -> /nix/store/3z38jxq9s7916yalrq3q5h75h7b99ivn-user-environment
profile-2-link -> /nix/store/qmw5hflz7jrnsfhfw024b4744g0jnnj0-user-environment
DIRECTORY /etc/nix
nix.conf -> /etc/static/nix/nix.conf
nix.conf.before-nix-darwin -> [entry]
nix.conf.determinate.bak -> [entry]
registry.json -> /etc/static/nix/registry.json
DIRECTORY /run/current-system
Applications -> /nix/store/yw31is252rdj271bpghxp1612z0ky2wq-system-applications/Applications
Library -> [entry]
activate -> [entry]
activate-user -> [entry]
darwin -> [entry]
darwin-changes -> [entry]
darwin-version -> [entry]
darwin-version.json -> /nix/store/nrfk0cy0cjz2x5wqfxfq08f3fisw5p0x-darwin-version.json
etc -> /nix/store/x08v8a5mc5832ak1fwp0rig4844ky98a-etc/etc
patches -> /nix/store/4kf56vpj5wxg3r3algvhbgqf0pqkj2y7-patches/patches
sw -> /nix/store/k2rpk17mhl258ipixmsh5x6djx6ryax9-system-path
system -> [entry]
systemConfig -> [entry]
user -> [entry]
DIRECTORY /opt/homebrew/Caskroom
chromium -> [entry]
claude -> [entry]
claude-code -> [entry]
element -> [entry]
google-chrome -> [entry]
monero-wallet -> [entry]
openscad -> [entry]
steam -> [entry]
tor-browser -> [entry]
x2goclient -> [entry]
EXISTS /nix/receipt.json: True
EXISTS /usr/local/bin/determinate-nixd: False
EXISTS /nix/var/determinate: False
EXISTS /etc/nix-darwin: False
EXISTS /etc/nixos: False
EXISTS /Users/fdm/.nix-channels: True
EXISTS /var/root/.nix-channels: False
````

### evidence-status.txt

````text
$ python3 documentation structure, requirement traceability, and baseline integrity checks
PRD sections: 9
Requirements: 25; unique IDs, allowed priorities and evidence/answer references: PASS
Em dash check: PASS
Tracked files changed since audit baseline: []
$ git status --short
 M profiles/home-darwin.nix
?? AGENTS.md
?? docs/
````

### evidence-vps-user.txt

````text
Source: user-provided transcript, collected on the VPS; not independently executed by the auditing agent.
The user invoked the whole script with sudo. Both channel queries therefore describe root.

fdm@nixos-vps:~/ > sudo ./vps-discovery.sh

$ date -u
Fr 25. Sep 17:47:22 UTC 2026
[exit 0]

$ hostname
nixos-vps
[exit 0]

$ uname -m
x86_64
[exit 0]

$ nix --version
nix (Nix) 2.31.2
[exit 0]

$ nixos-version --json
{"nixosVersion":"26.05.20251129.59b6c96","nixpkgsRevision":"59b6c96beacc898566c9be1052ae806f3835f87d"}
[exit 0]

$ nixos-version --configuration-revision
/run/current-system/sw/bin/nixos-version: configuration revision is unknown
[exit 1]

$ readlink -f /run/current-system
/nix/store/yhczh27iwxqsbikj51c4lkb4gpwzzmwh-nixos-system-nixos-vps-26.05.20251129.59b6c96
[exit 0]

$ readlink -f /nix/var/nix/profiles/system
/nix/store/yhczh27iwxqsbikj51c4lkb4gpwzzmwh-nixos-system-nixos-vps-26.05.20251129.59b6c96
[exit 0]

$ bash -c for\ p\ in\ /nix/var/nix/profiles/system-\*-link\;\ do\ \[\ -L\ \"\$p\"\ \]\ \|\|\ continue\;\ stat\ -c\ \"%n\ %y\"\ \"\$p\"\;\ readlink\ \"\$p\"\;\ done
/nix/var/nix/profiles/system-10-link 2023-11-07 11:25:30.660419195 +0100
/nix/store/vz7dincw8z0axbw54wn0087j36w6av0z-nixos-system-nixos-vps-23.11.20230814.87c5a6a
/nix/var/nix/profiles/system-11-link 2023-11-08 15:33:57.042465926 +0100
/nix/store/fqgjf80pmcqsxis2amhd0jsbjwgcwyz3-nixos-system-nixos-vps-23.11.20230814.87c5a6a
/nix/var/nix/profiles/system-12-link 2024-02-27 12:23:45.468827132 +0100
/nix/store/5iag2v7skvgbklx1b1p89d09kls0cdpp-nixos-system-nixos-fdm-24.05.20240223.b13bb49
/nix/var/nix/profiles/system-13-link 2024-02-27 12:28:07.689085113 +0100
/nix/store/fqgjf80pmcqsxis2amhd0jsbjwgcwyz3-nixos-system-nixos-vps-23.11.20230814.87c5a6a
/nix/var/nix/profiles/system-14-link 2024-02-27 12:39:13.996378724 +0100
/nix/store/5iag2v7skvgbklx1b1p89d09kls0cdpp-nixos-system-nixos-fdm-24.05.20240223.b13bb49
/nix/var/nix/profiles/system-15-link 2024-02-27 12:43:19.984673552 +0100
/nix/store/fqgjf80pmcqsxis2amhd0jsbjwgcwyz3-nixos-system-nixos-vps-23.11.20230814.87c5a6a
/nix/var/nix/profiles/system-16-link 2024-02-27 12:52:10.212348981 +0100
/nix/store/5iag2v7skvgbklx1b1p89d09kls0cdpp-nixos-system-nixos-fdm-24.05.20240223.b13bb49
/nix/var/nix/profiles/system-17-link 2024-02-27 12:53:36.958132204 +0100
/nix/store/fqgjf80pmcqsxis2amhd0jsbjwgcwyz3-nixos-system-nixos-vps-23.11.20230814.87c5a6a
/nix/var/nix/profiles/system-18-link 2024-02-27 13:18:16.405659825 +0100
/nix/store/l33admrk7w4b068rkwx7v1z5vjwcdigc-nixos-system-nixos-fdm-24.05.20240223.b13bb49
/nix/var/nix/profiles/system-19-link 2024-02-27 15:32:49.811237526 +0100
/nix/store/xffbf2qlbm8qphxgzmyx7wd8yy473qb7-nixos-system-nixos-fdm-24.05.20240223.b13bb49
/nix/var/nix/profiles/system-1-link 2023-11-06 00:45:21.366797861 +0100
/nix/store/5vsn4piyg55jkf3c8yx133rrg0pa4b1g-nixos-system-nixos-23.05.3103.841889913dfd
/nix/var/nix/profiles/system-20-link 2025-11-28 00:53:33.079939744 +0100
/nix/store/2hlk7yni6pna92vd7a9gpcdpnryw0jfk-nixos-system-nixos-fdm-26.05.20251127.ff335ce
/nix/var/nix/profiles/system-21-link 2025-11-29 14:26:23.390982891 +0100
/nix/store/yhczh27iwxqsbikj51c4lkb4gpwzzmwh-nixos-system-nixos-vps-26.05.20251129.59b6c96
/nix/var/nix/profiles/system-2-link 2023-11-06 00:50:32.057270976 +0100
/nix/store/wy24pnlmdbfbds3q3wbnabkqv16x7l6q-nixos-system-nixos-23.05.3103.841889913dfd
/nix/var/nix/profiles/system-3-link 2023-11-06 11:26:45.334789989 +0100
/nix/store/ippgqfpjrip8q3lg30rvxnhi3d54xmg0-nixos-system-nixos-23.05.3103.841889913dfd
/nix/var/nix/profiles/system-4-link 2023-11-06 11:37:48.871315072 +0100
/nix/store/ppvp31isnj91nhbc9rrvcffjdra92q79-nixos-system-nixos-23.05.3103.841889913dfd
/nix/var/nix/profiles/system-5-link 2023-11-06 11:50:28.041762874 +0100
/nix/store/jib6k4lnzqm5mp6rqg36ncd189f30i1f-nixos-system-nixos-23.05.3103.841889913dfd
/nix/var/nix/profiles/system-6-link 2023-11-06 16:12:13.249994907 +0100
/nix/store/r4c38wzf5z6bmvd3l6sii1ry8sd5b05z-nixos-system-nixos-23.11.20230814.87c5a6a
/nix/var/nix/profiles/system-7-link 2023-11-06 16:18:00.698129450 +0100
/nix/store/5vk4m936if6a5lm6sbdaha4qnpgd08c5-nixos-system-nixos-23.11.20230814.87c5a6a
/nix/var/nix/profiles/system-8-link 2023-11-07 11:13:09.429522473 +0100
/nix/store/8xvid0z1rr9pfhcimfn85jx6srsdjbkd-nixos-system-nixos-23.11.20230814.87c5a6a
/nix/var/nix/profiles/system-9-link 2023-11-07 11:23:38.523444264 +0100
/nix/store/5nzifjvsyn4r3j12wvfkdpcs6gq62liy-nixos-system-nixos-23.11.20230814.87c5a6a
[exit 0]

$ nix-channel --list
nixos https://nixos.org/channels/nixos-23.05
[exit 0]

$ sudo -n nix-channel --list
nixos https://nixos.org/channels/nixos-23.05
[exit 0]

$ bash -c for\ p\ in\ /etc/nixos/flake.nix\ /etc/nixos/flake.lock\ /etc/nixos/configuration.nix\ /etc/nix/nix.conf\ /etc/nixos/.git\ /run/current-system/configuration.nix\;\ do\ if\ \[\ -e\ \"\$p\"\ \]\;\ then\ ls\ -ld\ \"\$p\"\;\ fi\;\ done
-rw-r--r-- 1 root root 1306 27. Feb 2024  /etc/nixos/flake.nix
-rw-r--r-- 1 root root 4022 27. Feb 2024  /etc/nixos/flake.lock
-rw-r--r-- 1 root root 3736 27. Feb 2024  /etc/nixos/configuration.nix
lrwxrwxrwx 1 root root 24 13. Jul 14:54 /etc/nix/nix.conf -> /etc/static/nix/nix.conf
[exit 0]

$ systemctl is-active nix-daemon.service
active
[exit 0]

$ systemctl --failed --no-pager --plain
UNIT LOAD ACTIVE SUB DESCRIPTION

0 loaded units listed.
[exit 0]

$ df -h / /nix/store
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda1        24G   13G  9,4G  59% /
/dev/vda1        24G   13G  9,4G  59% /nix/store
[exit 0]

$ sudo -n du -sh /nix/store
9,1G	/nix/store
[exit 0]

$ uptime
 19:48:00  up 74 days  4:53,  2 users,  load average: 0,71, 0,23, 0,08
[exit 0]

$ uptime -s
uptime: invalid option -- 's'
Try 'uptime --help' for more information.
[exit 1]

$ who -b
         system boot  2026-07-13 14:54
[exit 0]

$ last -x reboot -n 3
reboot   system boot  6.12.59          Mon Jul 13 14:54   still running
reboot   system boot  6.12.59          Sat Nov 29 14:27   still running
reboot   system boot  6.12.59          Fri Nov 28 00:56 - 14:26 (1+13:30)

wtmp begins Mon Nov  6 00:51:38 2023
[exit 0]

$ systemctl list-unit-files --state=enabled --type=service --no-pager
UNIT FILE                                STATE   PRESET
acme-mail.maurerf.com.service            enabled ignored
activate-virtual-mail-users.service      enabled ignored
dovecot.service                          enabled ignored
firewall.service                         enabled ignored
generate-shutdown-ramfs.service          enabled ignored
home-manager-fdm.service                 enabled ignored
kmod-static-nodes.service                enabled ignored
lastlog2-import.service                  enabled ignored
linger-users.service                     enabled ignored
logrotate-checkconf.service              enabled ignored
ModemManager.service                     enabled ignored
network-setup.service                    enabled ignored
NetworkManager-dispatcher.service        enabled ignored
NetworkManager-wait-online.service       enabled ignored
NetworkManager.service                   enabled ignored
nginx-config-reload.service              enabled ignored
nginx.service                            enabled ignored
nscd.service                             enabled ignored
postfix-tlspol.service                   enabled ignored
postfix.service                         enabled ignored
pre-sleep.service                        enabled ignored
prepare-kexec.service                    enabled ignored
redis-rspamd.service                    enabled ignored
reload-systemd-vconsole-setup.service    enabled ignored
resolvconf.service                       enabled ignored
rspamd.service                          enabled ignored
save-hwclock.service                    enabled ignored
sshd.service                            enabled ignored
suid-sgid-wrappers.service               enabled ignored
systemd-boot-random-seed.service         enabled ignored
systemd-hibernate-clear.service         enabled ignored
systemd-journal-catalog-update.service   enabled ignored
systemd-journal-flush.service            enabled ignored
systemd-journald.service                 enabled ignored
systemd-logind.service                   enabled ignored
systemd-machine-id-commit.service        enabled ignored
systemd-modules-load.service             enabled ignored
systemd-oomd.service                     enabled ignored
systemd-pstore.service                   enabled ignored
systemd-random-seed.service              enabled ignored
systemd-sysctl.service                   enabled ignored
systemd-timesyncd.service                enabled ignored
systemd-tmpfiles-resetup.service         enabled ignored
systemd-tmpfiles-setup-dev-early.service enabled ignored
systemd-tmpfiles-setup-dev.service       enabled ignored
systemd-tmpfiles-setup.service           enabled ignored
systemd-tpm2-setup-early.service         enabled ignored
systemd-tpm2-setup.service               enabled ignored
systemd-udev-trigger.service             enabled ignored
systemd-udevd.service                    enabled ignored
systemd-update-done.service              enabled ignored
systemd-update-utmp.service              enabled ignored
systemd-user-sessions.service            enabled ignored

53 unit files listed.
[exit 0]

$ systemctl list-units --state=running --type=service --no-pager
  UNIT                      LOAD   ACTIVE SUB     DESCRIPTION
  dbus.service              loaded active running D-Bus System Message Bus
  dovecot.service           loaded active running Dovecot IMAP/POP3 server
  getty@tty1.service         loaded active running Getty on tty1
  kres-cache-gc.service     loaded active running Knot Resolver Garbage Collector daemon
  kresd@1.service           loaded active running Knot Resolver daemon
  NetworkManager.service    loaded active running Network Manager
  nginx.service             loaded active running Nginx Web Server
  nix-daemon.service        loaded active running Nix Daemon
  nscd.service              loaded active running Name Service Cache Daemon (nsncd)
  postfix-tlspol.service    loaded active running Postfix DANE/MTA-STS TLS policy socketmap service
  postfix.service           loaded active running Postfix mail server
  redis-rspamd.service      loaded active running Redis Server - redis-rspamd
  rspamd.service            loaded active running Rspamd Service
  sshd.service              loaded active running SSH Daemon
  systemd-journald.service  loaded active running Journal Service
  systemd-logind.service   loaded active running User Login Management
  systemd-oomd.service      loaded active running Userspace Out-Of-Memory (OOM) Killer
  systemd-timesyncd.service loaded active running Network Time Synchronization
  systemd-udevd.service     loaded active running Rule-based Manager for Device Events and Files
  user@1000.service        loaded active running User Manager for UID 1000

Legend: LOAD   → Reflects whether the unit definition was properly loaded.
        ACTIVE → The high-level unit activation state, i.e. generalization of SUB.
        SUB    → The low-level unit activation state, values depend on unit type.

20 loaded units listed.
[exit 0]

$ ss -lntu
Netid                                      State                                       Recv-Q                                      Send-Q                                                                           Local Address:Port                                                                             Peer Address:Port
udp                                        UNCONN                                      0                                           0                                                                                    127.0.0.1:53                                                                                    0.0.0.0:*
udp                                        UNCONN                                      0                                           0                                                                                        [::1]:53                                                                                       [::]:*
tcp                                        LISTEN                                      0                                           511                                                                                    0.0.0.0:80                                                                                    0.0.0.0:*
tcp                                        LISTEN                                      0                                           100                                                                                    0.0.0.0:12340                                                                                 0.0.0.0:*
tcp                                        LISTEN                                      0                                           128                                                                                    0.0.0.0:22                                                                                    0.0.0.0:*
tcp                                        LISTEN                                      0                                           100                                                                                    0.0.0.0:25                                                                                    0.0.0.0:*
tcp                                        LISTEN                                      0                                           128                                                                                  127.0.0.1:53                                                                                    0.0.0.0:*
tcp                                        LISTEN                                      0                                           100                                                                                    0.0.0.0:993                                                                                   0.0.0.0:*
tcp                                        LISTEN                                      0                                           100                                                                                    0.0.0.0:465                                                                                      0.0.0.0:*
tcp                                        LISTEN                                      0                                           511                                                                                    0.0.0.0:443                                                                                    0.0.0.0:*
tcp                                        LISTEN                                      0                                           511                                                                                       [::]:80                                                                                       [::]:*
tcp                                        LISTEN                                      0                                           100                                                                                       [::]:12340                                                                                    [::]:*
tcp                                        LISTEN                                      0                                           128                                                                                       [::]:22                                                                                       [::]:*
tcp                                        LISTEN                                      0                                           100                                                                                       [::]:25                                                                                       [::]:*
tcp                                        LISTEN                                      0                                           100                                                                                       [::]:993                                                                                      [::]:*
tcp                                        LISTEN                                      0                                           100                                                                                       [::]:465                                                                                      [::]:*
tcp                                        LISTEN                                      0                                           511                                                                                       [::]:443                                                                                      [::]:*
tcp                                        LISTEN                                      0                                           128                                                                                      [::1]:53                                                                                       [::]:*
[exit 0]

$ systemctl show firewall.service --property=LoadState\,ActiveState\,SubState\,Result
LoadState=loaded
ActiveState=active
SubState=exited
Result=success
[exit 0]

$ sudo -n nft list ruleset
sudo: nft: command not found
[exit 1]

$ sudo -n iptables -S
-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
-N nixos-fw
-N nixos-fw-accept
-N nixos-fw-log-refuse
-N nixos-fw-refuse
-A INPUT -j nixos-fw
-A nixos-fw -i lo -j nixos-fw-accept
-A nixos-fw -m conntrack --ctstate RELATED,ESTABLISHED -j nixos-fw-accept
-A nixos-fw -p tcp -m tcp --dport 22 -j nixos-fw-accept
-A nixos-fw -p tcp -m tcp --dport 25 -j nixos-fw-accept
-A nixos-fw -p tcp -m tcp --dport 80 -j nixos-fw-accept
-A nixos-fw -p tcp -m tcp --dport 465 -j nixos-fw-accept
-A nixos-fw -p tcp -m tcp --dport 993 -j nixos-fw-accept
-A nixos-fw -p icmp -m icmp --icmp-type 8 -j nixos-fw-accept
-A nixos-fw -j nixos-fw-log-refuse
-A nixos-fw-accept -j ACCEPT
-A nixos-fw-log-refuse -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j LOG --log-prefix "refused connection: " --log-level 6
-A nixos-fw-log-refuse -m pkttype ! --pkt-type unicast -j nixos-fw-refuse
-A nixos-fw-log-refuse -j nixos-fw-refuse
-A nixos-fw-refuse -j DROP
[exit 0]

$ sudo -n ip6tables -S
-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
-N nixos-fw
-N nixos-fw-accept
-N nixos-fw-log-refuse
-N nixos-fw-refuse
-A INPUT -j nixos-fw
-A nixos-fw -i lo -j nixos-fw-accept
-A nixos-fw -m conntrack --ctstate RELATED,ESTABLISHED -j nixos-fw-accept
-A nixos-fw -p tcp -m tcp --dport 22 -j nixos-fw-accept
-A nixos-fw -p tcp -m tcp --dport 25 -j nixos-fw-accept
-A nixos-fw -p tcp -m tcp --dport 80 -j nixos-fw-accept
-A nixos-fw -p tcp -m tcp --dport 465 -j nixos-fw-accept
-A nixos-fw -p tcp -m tcp --dport 993 -j nixos-fw-accept
-A nixos-fw -p ipv6-icmp -m icmp6 --icmpv6-type 137 -j DROP
-A nixos-fw -p ipv6-icmp -m icmp6 --icmpv6-type 139 -j DROP
-A nixos-fw -p ipv6-icmp -j nixos-fw-accept
-A nixos-fw -d fe80::/64 -p udp -m udp --dport 546 -j nixos-fw-accept
-A nixos-fw -j nixos-fw-log-refuse
-A nixos-fw-accept -j ACCEPT
-A nixos-fw-log-refuse -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j LOG --log-prefix "refused connection: " --log-level 6
-A nixos-fw-log-refuse -m pkttype ! --pkt-type unicast -j nixos-fw-refuse
-A nixos-fw-log-refuse -j nixos-fw-refuse
-A nixos-fw-refuse -j DROP
[exit 0]

$ systemctl list-timers --all --no-pager
NEXT                           LEFT LAST                               PASSED UNIT                              ACTIVATES
Fri 2026-09-25 20:00:00 CEST  11min Fri 2026-09-25 19:00:02 CEST    47min ago logrotate.timer                   logrotate.service
Sat 2026-09-26 15:11:46 CEST    19h Fri 2026-09-25 15:11:46 CEST 4h 36min ago systemd-tmpfiles-clean.timer      systemd-tmpfiles-clean.service
Sat 2026-09-26 17:06:20 CEST    21h Fri 2026-09-25 17:06:22 CEST 2h 41min ago acme-renew-mail.maurerf.com.timer acme-order-renew-mail.maurerf.com.service
Mon 2026-09-28 01:02:51 CEST 2 days Mon 2026-09-21 00:55:28 CEST   4 days ago fstrim.timer                      fstrim.service

4 timers listed.
[exit 0]

$ backup unit status (selected metadata only)

Backup jobs do not prove recoverability. Separately report provider backups, protected data, latest successful backup and restore test, retention, downtime allowance, and console access. Do not paste credentials.
fdm@nixos-vps:~/ >
````

### evidence-web-releases.json

````text
"NixOS 26.05 released | Blog | Nix & NixOS (https://nixos.org/blog/announcements/2026/nixos-2605/)\nciteturn0search0 [wordlim: 200] Published: 3 months ago; Crawled: today; # NixOS 26.05 released ... We are looking forward to the next release, NixOS 26.11 “Zokor”.\n\n# NixOS 26.05 released\n\nPublished on Sat May 30 2026\n\nHey everyone, we are yayayayaka and jopejoe1, the release managers of the newest release of NixOS. We are very proud to announce the public availability of NixOS 26.05 “Yarara”.\n\nNixOS is a Linux distribution. Its underlying package repository Nixpkgs can also be used on other Linux systems and macOS with the Nix package manager.\n\nThis release will receive bugfixes and security updates for seven months (up until 2026-12-31). The old release 25.11 “Xantusia” is now officially deprecated and will reach its end-of-life and stop receiving security updates after 2026-06-30.\n\n  * NixOS Release Notes\n    * Highlights\n    * New Modules\n    * Backward Incompatibilities\n    * Other Notable Changes\n  * Nixpkgs Release Notes\n    * Highlights\n    * Backward Incompatibilities\n    * Other Notable Changes\n    * Nixpkgs Library\n--------------------------------------------------------------------------------\nStandalone installation - Home Manager Manual (https://nix-community.github.io/home-manager/installation/standalone.html)\nciteturn0search1 [wordlim: 200] Crawled: today;     `$ nix-channel --add https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz home-manager\n--------------------------------------------------------------------------------\nGitHub - nix-community/home-manager: Manage a user environment using Nix [maintainer=@khaneliman, @rycee] · GitHub (https://github.com/nix-community/home-manager)\nciteturn0search2 [wordlim: 200] Crawled: today; To avoid breaking users' configurations, Home Manager is released in branches corresponding to NixOS releases (e.g. `release-26.05`). ... nix-community.github.io/home-manager/\n--------------------------------------------------------------------------------\nStandalone setup - Home Manager Manual (https://nix-community.github.io/home-manager/nix-flakes/standalone.html)\nciteturn0search3 [wordlim: 200] Crawled: today;     `$ nix run home-manager/release-26.05 -- init --switch ...         home-manager.url = \"github:nix-community/home-manager\";\n--------------------------------------------------------------------------------\nhome-manager/MAINTAINING.md at master · nix-community/home-manager · GitHub (https://github.com/nix-community/home-manager/blob/master/MAINTAINING.md)\nciteturn0search4 [wordlim: 200] Crawled: last month;         inputs.nixpkgs.url = \"github:NixOS/nixpkgs/nixos-25.11\"; ...      * Commit the flake.nix and flake.lock changes ...      * Update `release` field to next version (e.g., `\"25.11\"` → `\"26.05\"`) ... Each release may introduce state version changes that affect the default behavior of Home Manager for users who set `home.stateVersion` to that version.\n--------------------------------------------------------------------------------\nnixpkgs/nixos/doc/manual/release-notes/rl-2605.section.md at master · NixOS/nixpkgs · GitHub (https://github.com/NixOS/nixpkgs/blob/master/nixos/doc/manual/release-notes/rl-2605.section.md)\nciteturn0search5 [wordlim: 200] Published: 3 months ago; Crawled: last month; # Release 26.05 (\"Yarara\", 2026.05/30) {#sec-release-26.05} ...       # Use `curl -I https://channels.nixos.org/nixos-26.05` to get the ... To keep the old behavior for a site `example.com`, set `services.caddy.virtualHosts.\"example.com\".hostName = \"http://example.com\"`.\n--------------------------------------------------------------------------------\nnixos-26.05 release nixos-26.05.5092.4382ed2b7a68 (https://releases.nixos.org/nixos/26.05/nixos-26.05.5092.4382ed2b7a68)\nciteturn0search6 [wordlim: 200] Published: 2 months ago; Crawled: 2 months ago; # nixos-26.05 release nixos-26.05.5092.4382ed2b7a68 ... nixos-minimal-26.05.5092.4382ed2b7a68-x86_64-linux.iso  | 1692844032  | `478d7c27f503662cd5bc98cdbeff8e0f6963ff33f8b8668bad5bfd86df4d7dc9`\n--------------------------------------------------------------------------------\nLet's have a great 26.05 release cycle! - Announcements - NixOS Discourse (https://discourse.nixos.org/t/lets-have-a-great-26-05-release-cycle/76588)\nciteturn0search7 [wordlim: 200] Published: 6 months ago; Crawled: 6 months ago; we are @yayayayaka and @jopejoe1, the current release managers for NixOS 26.05 (“Yarara”), together with @NotAShelf and @bjth as release editors. ...   * Release Management Matrix Room: https://matrix.to/#/#nixos-release-management:nixos.org\n--------------------------------------------------------------------------------\nOfficial NixOS Wiki:News - Official NixOS Wiki (https://wiki.nixos.org/wiki/NixOS_Wiki%3ANews)\nciteturn0search8 [wordlim: 200] Crawled: today; #### 2026-05-30 — NixOS 26.05 releasedRelease Notes: https://nixos.org/blog/announcements/2026/nixos-2605/\n--------------------------------------------------------------------------------\n26.05 Feature Freeze & Release Blockers - Announcements - NixOS Discourse (https://discourse.nixos.org/t/26-05-feature-freeze-release-blockers/76704)\nciteturn0search9 [wordlim: 200] Published: 5 months ago; Crawled: 5 months ago; Whether you were pinged or not, we encourage everyone to create issues for release blockers and add them to the [26.05 Blockers project](https://github.com/orgs/NixOS/projects/110).\n--------------------------------------------------------------------------------\nhome-manager: prepare 26.05 - home-manager - Manage a user environment using Nix [maintainer=@rycee] (https://git.jeffas.net/home-manager/commits/8433591183c2200d1964988049c5e852201ac3ed.html)\nciteturn0search10 [wordlim: 200] Published: 10 months ago; Crawled: 2 months ago; Manage a user environment using Nix [maintainer=@rycee] ... home-manager: prepare 26.05 ...     +  \"release\": \"26.05\",\n--------------------------------------------------------------------------------\nnix-community/home-manager | DeepWiki (https://deepwiki.com/nix-community/home-manager)\nciteturn0search11 [wordlim: 200] Crawled: last month;   * .github/PULL_REQUEST_TEMPLATE.md ...   * Profile Migration: Home Manager automatically migrates profiles to follow Nix 2.14+ standards (e.g., moving to `$XDG_STATE_HOME/nix/profiles`) modules/lib-bash/activation-init.sh4-32 ...   * Release Tracking: Release information (e.g., `26.05`) is defined in `release.json` and consumed by the documentation and version modules release.json1-5 flake.nix66-73\n--------------------------------------------------------------------------------\nIf you ever updated your system.stateversion or home.stateversion (in home manager), what made you do it? (https://www.reddit.com/r/NixOS/comments/1t64rcm/if_you_ever_updated_your_systemstateversion_or/)\nciteturn0reddit12 [wordlim: 200] Published: 4 months ago;     You are currently using the legacy default (`\".mozilla/firefox\"`) because `home.stateVersion` is less than \"26.05\". ...         same with home-manager btw: https://nix-community.github.io/home-manager/release-notes.xhtml\n--------------------------------------------------------------------------------\nNixOS be like (https://www.reddit.com/r/NixOS/comments/1uu9o0l/nixos_be_like/)\nciteturn0reddit13 [wordlim: 200] Published: 2 months ago;   im running on 26.05, my home manager config is in .config/home-manager/home.nix ...       yeah, the concept of a fully replicable distro is crazy good, and for that reason i installed it on an USB so i can replicate it even more easily, but, the thing with nixOS is, why would you useit elsewere, i mean, the nix package manager is aviable even for android, why would you bother using a distro that its hard when that main concept is one you can have on anotherone, my main distro nowadays is one i actually recommend begginers even if its a weird choice for that, opensuse tumbleweed, lots of docs, rpm packages, YaST (even if you dont like gui tools, i do, i usually use terminal, but sometimes i preffer gui tools), really stable for a rolling release, actually good performance for gaming, companies that use it value experience with it for some jobs, you can install nix, and, my only issue, really, really corporate focused, works really well for individuals, but its not made for us\n--------------------------------------------------------------------------------\nVersion mismatch in my flake: Home Manager 26.05 & Nixpkgs 25.11 (https://www.reddit.com/r/NixOS/comments/1pjhzf6/version_mismatch_in_my_flake_home_manager_2605/)\nciteturn0reddit14 [wordlim: 200] Published: 9 months ago; Crawled: 9 months ago; I get this message when I do `nixos-rebuild`: `You are using Home Manager version 26.05 and Nixpkgs version 25.11. ...           url = \"github:nix-community/home-manager\";\n--------------------------------------------------------------------------------\nNixOS (https://en.wikipedia.org/wiki/NixOS)\nciteturn0search15 [wordlim: 200] Crawled: 4 months ago; - Community - nixos.org. ... NixOS 26.05 - Release schedule · Issue #503391 · NixOS/nixpkgs.\n--------------------------------------------------------------------------------\nNixOS 26.05 channel seems to be out for testing (https://www.reddit.com/r/NixOS/comments/1tniqf3/nixos_2605_channel_seems_to_be_out_for_testing/)\nciteturn0reddit16 [wordlim: 200] Published: 4 months ago; Looks like the first evaluation of release-26.05 is done cooking in Hydra: https://hydra.nixos.org/project/nixos\n--------------------------------------------------------------------------------\nApp updates in NixOS? (https://www.reddit.com/r/NixOS/comments/1slhv9n/app_updates_in_nixos/)\nciteturn0reddit17 [wordlim: 200] Published: 5 months ago;     https://nix-community.github.io/home-manager/\n--------------------------------------------------------------------------------\nNixOS 26.05 released (https://www.reddit.com/r/NixOS/comments/1trzym8/nixos_2605_released/)\nciteturn0reddit18 [wordlim: 200] Published: 3 months ago;       \\# To replace your current NixOS channel with the latest stable release (currently 26.05, as the next stable release occurs in May 2026), ...       \\# sudo nix-channel --add https://nixos.org/channels/nixos-26.05 nixos\n--------------------------------------------------------------------------------\nfinally switched to nix :) :) :) (https://www.reddit.com/r/NixOS/comments/1sd3qns/finally_switched_to_nix/)\nciteturn0reddit19 [wordlim: 200] Published: 5 months ago; [Sunday April 05 2026] [+32 votes] ... * https://nix-community.github.io/home-manager/ \\~ Home Manager\n--------------------------------------------------------------------------------\n25.05 Posted (https://www.reddit.com/r/NixOS/comments/1ktpnbq)\nciteturn0reddit20 [wordlim: 200] Published: 1.3 years ago; Crawled: 1.3 years ago; https://releases.nixos.org/? ... Here is the link to the announcement where you can see the 25.05 release notes for NixOS and Nixpkgs.\n--------------------------------------------------------------------------------\nI can't upgrade to 24.05 (https://www.reddit.com/r/NixOS/comments/1d9w9yr)\nciteturn0reddit21 [wordlim: 200] Published: 2.3 years ago; Crawled: 2.3 years ago;   home-manager https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz  nixos https://nixos.org/channels/nixos-24.05\n--------------------------------------------------------------------------------\nWhat is your experience with Nix-Darwin? (https://www.reddit.com/r/NixOS/comments/1v6plpo/what_is_your_experience_with_nixdarwin/)\nciteturn0reddit22 [wordlim: 200] Published: 2 months ago; I don't use any flakes on Nix-Darwin, I don't like waiting to rebuild hoping that whatever random package or library that failed to build finally got fixed, I have to gamble every time I use the `nh darwin` / rebuild command. ... I set the system nixpkgs source to darwin-26.05 branch.\n--------------------------------------------------------------------------------\nHome manager and nixpkgs mismatch. Is it okay??? (https://www.reddit.com/r/NixOS/comments/1go9icq)\nciteturn0reddit23 [wordlim: 200] Published: 1.9 years ago; Crawled: 1.9 years ago;     `github:nix-community/home-manager/release-24.05`\n--------------------------------------------------------------------------------\nUpdating to 26.05 (https://www.reddit.com/r/NixOS/comments/1ugfrna/updating_to_2605/)\nciteturn0reddit24 [wordlim: 200] Published: 3 months ago; Hello, I am updating nixos to it's 26.05 since 25.11 is getting discontinued soon.\n--------------------------------------------------------------------------------\nNix Package Manager Guide (https://releases.nixos.org/nix/nix-1.11.5/manual.pdf)\nciteturn0search25 [wordlim: 200] Published: 56.8 years ago; This release has contributions from Anders Claesson, Anthony Cowley, Bjørn Forsman, Brian McKenna, Danny Wilson, davidak, ... binary-cache-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=\n--------------------------------------------------------------------------------\nnix.dev (https://nix.dev/nix-dev.pdf)\nciteturn0search26 [wordlim: 200] Published: 1.7 years ago; `nixos-23.05` and `nixpkgs-23.05-darwin` are both based on `release-23.05`. ... 430 https://search.nixos.org/options?\n--------------------------------------------------------------------------------\nHOME MANAGER (https://luga.de/static/LIT-2025/assets/talks/WieErWill_-_Nix_kanns_besser__Der_n%C3%A4chste_Schritt_.pdf)\nciteturn0search27 [wordlim: 200] Published: 1.4 years ago; Crawled: 7 months ago;   https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz \\\n--------------------------------------------------------------------------------\nNixOS (https://fr.wikipedia.org/wiki/NixOS)\nciteturn0search28 [wordlim: 200] Crawled: 5 months ago; Site Web: https://nixos.org/ ... Version Suivante: 26.05 (Yarara) ... - NixOS - Release-Notes.\n--------------------------------------------------------------------------------\nMore Resources (https://mregirouard.com/RCOS_NixOS_Workshop.pdf)\nciteturn0search29 [wordlim: 200] Published: 1.9 years ago; https://nix-community.github.io/home-manager/\n--------------------------------------------------------------------------------\nCurriculum Vitae (https://s0ands0.github.io/curriculum-vitae/curriculum-vitae.pdf)\nciteturn0search30 [wordlim: 200] Published: last year; 4.2.15 **Nix Community home-manager** source code ... Implemented significant quality of life improvements for web clients, including a new feature for site authors, and resolved image presentation issues in the Minima Jekyll theme, resulting in an enhanced\n"
````

## Integrity baseline

Hashes include the pre-existing Darwin profile edit.

### baseline-sha256.json

````json
{
  "README.md": "37933349d5a2bdef6719a6230d63425723aa35a4541fb81ac43026736ac9e125",
  "flake.lock": "588bbd7ec23a66acf237ee4859f1794958d1233a964e63c1d25c06bad4886224",
  "flake.nix": "d13bf91d98069c413d65f31498ab20822013a2d987912d8f218ebd639dde3def",
  "hardware/vultr-vps.nix": "11d0ba301d9cbc11887091f7e26cbd429defd9d5ce5737e94f6e705b3609f21a",
  "machines/m2-macbook-air.nix": "38d392e3793e684cc2d08fc32eeda7577f8568323c43af5da0838b8e91f41aa0",
  "machines/vps.nix": "af4c0b134c22518c7135ad6fcf368ac9168cfd385664b6925b7899cb9f16d37f",
  "modules/git.nix": "ba2a7a788a0c84f9e12cc4ce549b9a259229781573481be81cefae778b0b5b91",
  "modules/nixos-base.nix": "ba8a0b363422c0c0bf1580d6f6a8f22ac2e063a2229b697ae449a071f5d74976",
  "modules/zsh.nix": "ee314c1fcf8ca8b7a32d059033c462d02cae3edc28325c2604397ee976ed67c3",
  "profiles/home-darwin.nix": "7e2c7960f5b54ec476e26ef09fce28ac7d6a573b018462eef9eb485e29694557",
  "profiles/home-vps.nix": "cbea8fc9deee1a4587a06796ec9cbda6b3f2e6e14bdec88b7e94555ed7d4f00c"
}
````

## Collection methods

Archived for provenance only. These are not maintained tools or instructions to rerun discovery.

### collect-eval.py

````python
import subprocess,pathlib,os
out=pathlib.Path('docs/goals/01-checkup')
commands=[
['cat','/run/current-system/darwin-version.json'],
['nix','--help'],
['darwin-version','--help'],
]
for i,cmd in enumerate(commands):
 p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,env={**os.environ,'PAGER':'cat'})
 data='$ '+' '.join(cmd)+'\n'+p.stdout+f'\n[exit {p.returncode}]\n'
 (out/f'evidence-provenance-{i}.txt').write_text(data); print(data)
````

### collect-local.py

````python
import subprocess, pathlib, datetime, json, hashlib
root=pathlib.Path.cwd()
out=root/'docs/goals/01-checkup'
commands=[
('repo','date -u; git status --short; git rev-parse HEAD; git log -8 --format="%H %cI %s"; git log -1 --format="%H %cI %s" -- machines/m2-macbook-air.nix profiles/home-darwin.nix; git log -1 --format="%H %cI %s" -- machines/vps.nix profiles/home-vps.nix; rg --files --hidden -g "!.git/**" -g "!docs/goals/01-checkup/**"; cat AGENTS.md README.md flake.nix flake.lock; git diff -- profiles/home-darwin.nix'),
('mac','sw_vers; uname -m; nix --version; command -v nix darwin-version darwin-rebuild home-manager brew; darwin-version; readlink /run/current-system; darwin-rebuild --list-generations; nix-channel --list; sudo -n nix-channel --list; home-manager generations; launchctl print system/org.nixos.nix-daemon; launchctl print system/systems.determinate.nix-daemon; dscl . -list /Users UniqueID | rg "nixbld"; ls -ld /nix/var/nix/profiles/system* /nix/var/nix/profiles/per-user/root/channels* /nix/var/nix/profiles/per-user/fdm/* /etc/nix/* /etc/static /etc/nix-darwin /etc/nixos /nix/receipt.json /usr/local/bin/determinate-nixd 2>/dev/null'),
('brew','HOMEBREW_NO_AUTO_UPDATE=1 brew --version; HOMEBREW_NO_AUTO_UPDATE=1 brew list --versions; HOMEBREW_NO_AUTO_UPDATE=1 brew tap'),
]
for name,cmd in commands:
    p=subprocess.run(['/bin/zsh','-c',cmd],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    data=f'$ {cmd}\n{p.stdout}\n[exit {p.returncode}]\n'
    (out/f'evidence-{name}.txt').write_text(data)
    print(data)
# Record integrity baseline without displaying configuration contents.
paths=subprocess.check_output(['git','ls-files'],text=True).splitlines()
baseline={p:hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest() for p in paths if pathlib.Path(p).is_file()}
(out/'baseline-sha256.json').write_text(json.dumps(baseline,indent=2)+'\n')
````

### collect-provenance.py

````python
from pathlib import Path
import json,subprocess,datetime
out=Path('docs/goals/01-checkup/evidence-provenance-extra.txt')
lines=['$ python3 docs/goals/01-checkup/collect-provenance.py']
def emit(s): lines.append(str(s))
p=Path('/nix/receipt.json')
try:
 data=json.loads(p.read_text()); emit('Installer receipt top-level keys: '+str(list(data)))
 for k in ['version','planner']:
  v=data.get(k)
  if isinstance(v,dict): emit(f'{k} keys: {list(v)}'); emit(f'{k}.planner: {v.get("planner")}')
  elif isinstance(v,str): emit(f'{k}: {v}')
except Exception as e: emit(e)
for p in [Path('/nix/var/nix/profiles/system-34-link'),Path('/nix/var/nix/profiles/system-33-link')]:
 emit(f'{p}: link_mtime={datetime.datetime.fromtimestamp(p.lstat().st_mtime,datetime.timezone.utc).isoformat()} target={p.readlink()}')
for base in [Path.home()/'.local/state/nix/profiles',Path.home()/'.local/state/home-manager',Path('/run/current-system/user')]:
 emit(f'DIRECTORY {base}')
 try:
  for p in base.iterdir(): emit(f'{p.name} -> {p.readlink() if p.is_symlink() else "[entry]"}')
 except Exception as e: emit(e)
for cmd in [['git','log','-1','--format=%H %cI %s','--','machines/m2-macbook-air.nix'],['git','log','-1','--format=%H %cI %s','--','machines/vps.nix'],['git','log','-1','--format=%H %cI %s','--','modules/nixos-base.nix'],['git','ls-files','.github','.gitlab-ci.yml','.buildkite','secrets','.sops.yaml'],['rg','-l','-i','agenix|sops|password|secret|backup|restic|borg','--glob','*.nix','.']]:
 p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True); emit('$ '+' '.join(cmd)); emit(p.stdout); emit(f'[exit {p.returncode}]')
out.write_text('\n'.join(lines)+'\n'); print(out.read_text())
````

### compare-history.py

````python
from pathlib import Path
import subprocess,json,datetime,hashlib
lines=['$ python3 docs/goals/01-checkup/compare-history.py']
def command(args):
 p=subprocess.run(args,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 lines.extend(['$ '+' '.join(args),p.stdout,f'[exit {p.returncode}]'])
 return p.stdout
command(['git','status','--short'])
command(['git','log','--all','--format=%H %cI %s','--','flake.lock'])
revisions=subprocess.check_output(['git','rev-list','HEAD','--','flake.lock'],text=True).splitlines()
target='59b6c96beacc898566c9be1052ae806f3835f87d'
for rev in revisions:
 raw=subprocess.check_output(['git','show',f'{rev}:flake.lock'],text=True)
 data=json.loads(raw)
 for name,node in data.get('nodes',{}).items():
  locked=node.get('locked',{})
  if locked.get('rev')==target:
   lines.append('MATCH: '+rev+' node '+name)
   command(['git','show',f'{rev}:flake.lock'])
   command(['git','log','--format=%H %cI %s',rev+'..HEAD'])
   dt=datetime.datetime.fromtimestamp(locked['lastModified'],datetime.timezone.utc)
   lines.append('Matched nixpkgs locked timestamp: '+dt.isoformat())
   lines.append('Deployed nixpkgs age in whole days on 2026-09-25T17:47:22Z: '+str((datetime.datetime(2026,9,25,17,47,22,tzinfo=datetime.timezone.utc)-dt).days))
p=Path('docs/goals/01-checkup/evidence-history-match.txt'); p.write_text('\n'.join(lines)+'\n'); print(p.read_text())
````

### evaluate.py

````python
import subprocess,pathlib,os,shlex
out=pathlib.Path('docs/goals/01-checkup')
env={**os.environ,'XDG_CACHE_HOME':str(out.resolve()/'cache'),'http_proxy':'http://127.0.0.1:9','https_proxy':'http://127.0.0.1:9','ALL_PROXY':'http://127.0.0.1:9','NO_PROXY':''}
base=['nix','--extra-experimental-features','read-only-local-store','--offline','--store','local?read-only=true','--option','allow-import-from-derivation','false','--option','eval-cache','false','--option','max-jobs','0','--option','builders','']
commands=[('metadata',['flake','metadata','--no-write-lock-file','.']),('show',['flake','show','--no-write-lock-file','.']),('eval-darwin',['eval','--no-write-lock-file','--raw','.#darwinConfigurations.m2-macbook-air.system.drvPath']),('eval-vps',['eval','--no-write-lock-file','--raw','.#nixosConfigurations.vps.config.system.build.toplevel.drvPath'])]
for name,args in commands:
 cmd=base+args
 p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,env=env)
 data='$ '+shlex.join(cmd)+'\n'+p.stdout+f'\n[exit {p.returncode}]\n'

 with (out/f'evidence-{name}.txt').open('a') as f: f.write(data); print(data,flush=True)
````

### inspect-static.py

````python
from pathlib import Path
import json,datetime,re,subprocess
out=Path('docs/goals/01-checkup/evidence-static.txt')
lines=[]
def emit(s): lines.append(str(s))
emit('$ python3 docs/goals/01-checkup/inspect-static.py')
for p in sorted(Path('.').rglob('*.nix')):
 if '.git' in p.parts: continue
 emit(f'FILE {p}')
 for n,line in enumerate(p.read_text().splitlines(),1):
  if re.search(r'password|secret|token|private.?key',line,re.I):
   emit(f'{n}: [credential-related line present; value omitted]')
  else: emit(f'{n}: {line}')
for name,node in json.loads(Path('flake.lock').read_text())['nodes'].items():
 if 'locked' in node:
  x=node['locked']; d=datetime.datetime.fromtimestamp(x['lastModified'],datetime.timezone.utc)
  emit(f'PIN {name}: {x["rev"]} {d.isoformat()} age_days={(datetime.datetime.now(datetime.timezone.utc)-d).days} ref={node.get("original",{}).get("ref","unspecified")}')
for p in [Path('/etc/nix/nix.conf'),Path('/etc/nix/nix.custom.conf'),Path.home()/'.config/nix/nix.conf']:
 emit(f'CONFIG {p}: exists={p.exists()} symlink={p.is_symlink()}')
 if p.exists():
  for line in p.read_text().splitlines():
   if re.match(r'^\s*(experimental-features|extra-experimental-features|build-users-group|sandbox|auto-optimise-store|trusted-users|allowed-users|include|!include|upgrade-nix-store-path|nix-path)\s*[= ]',line): emit(line)
   elif line.strip() and not line.lstrip().startswith('#'): emit('[other setting omitted to avoid exposing credentials]')
for directory in ['/nix/var/nix/profiles','/nix/var/nix/profiles/per-user/fdm','/nix/var/nix/profiles/per-user/root','/etc/nix','/run/current-system','/opt/homebrew/Caskroom']:
 p=Path(directory); emit(f'DIRECTORY {p}')
 try:
  for f in sorted(p.iterdir()): emit(f'{f.name} -> {f.readlink() if f.is_symlink() else "[entry]"}')
 except Exception as e: emit(e)
for p in ['/nix/receipt.json','/usr/local/bin/determinate-nixd','/nix/var/determinate','/etc/nix-darwin','/etc/nixos',str(Path.home()/'.nix-channels'),'/var/root/.nix-channels']:
 emit(f'EXISTS {p}: {Path(p).exists()}')
out.write_text('\n'.join(lines)+'\n'); print(out.read_text())
````


## Story-planning decisions (2026-09-25)

- The user resolved the conflict between the “should” priorities and SC-11: R-REPO-06, R-REPO-07, R-VPS-11 and R-VPS-12 are **mandatory for completion**. The original PRD priority labels remain unchanged; stories and final validation use this clarification.
- The user explicitly requested `stories.md` and `validation.md`, superseding the previous session’s exclusion of detailed stories and executable validation plans. Commands in these documents specify future authorized work; none is authorization to execute during planning.
- Initial working-tree status already included modified `profiles/home-darwin.nix`, untracked `AGENTS.md`, and untracked `PRD.md`, `EVIDENCE.md`, and `vps-discovery.sh` in this directory. Preserve these. The requested status condition is assessed as no **new changes from this planning session** outside this directory; a globally clean status outside it would require changing unrelated user work.

Initial-version planning validation (superseded by the consolidation below): `stories.md` contained 16 stories (repo 6, Mac 3, VPS 6, cross-system 1). A read-only structural audit verified all eight required fields and six validation layers per story, bidirectional coverage of all 25 PRD IDs (including all 20 must requirements), valid story dependencies with no cycles, and local document-link targets. `git diff --check` passed. SHA-256 comparison of all repository files outside this goal directory against this session's baseline found no changes. Existing outside-directory Git status entries remain preserved. This session added only `stories.md` and `validation.md` and appended planning decisions/verification here; it did not alter PRD.md or the existing discovery script. No Nix evaluation/build/activation, SSH, commit, push, lockfile/configuration edit or secret disclosure was performed. Command references were checked against the installed darwin-rebuild script and official Nix/NixOS documentation; future target-version and provider-specific procedures remain implementation gates.

The user requested consolidation to 5–8 stories. The plan now has seven outcomes: shared baselines, repo source preparation, shared native build/capacity proof, Mac upgrade, isolated VPS recovery, VPS upgrade, and maintenance/cross-system closure. Detailed protocol, recovery and CI checks remain validation work inside these outcomes. All story references in validation.md and the traceability table were updated; requirement priorities, the Mac-before-VPS sequence, high-risk backup/access gates and planning-only restrictions remain unchanged.

Consolidated-plan validation passed: seven stories (one repo, one Mac, two VPS and three cross-system), all required fields and six validation layers, all 25 requirement IDs including 20 must requirements, matching traceability, valid checklist references and acyclic dependencies. `git diff --check` passed. Hash comparison confirmed every file except stories.md, validation.md and EVIDENCE.md remained unchanged, including PRD.md, the existing discovery script, all Nix files, flake.lock and unrelated user changes. No implementation commands were executed.
