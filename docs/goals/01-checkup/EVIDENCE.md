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

## US-01 implementation evidence (2026-09-26, incomplete)

Status: in progress; Layer 1 has blocking gaps. No later layer has started. No build, flake evaluation/materialization, activation, package update, generation deletion or garbage collection was requested.

### Authorization and source

- Initial working tree clean; branch `checkup/US-01` created from `80656bee2ba0ea7a31da9912e9952213248eb446`. [verified: `git status --short --untracked-files=all`, `git rev-parse HEAD`, `git branch --show-current`]
- Lock SHA-256: `588bbd7ec23a66acf237ee4859f1794958d1233a964e63c1d25c06bad4886224`. [verified: `shasum -a 256 flake.lock`]
- User explicitly approved inclusion of the existing `targets.darwin.linkApps.enable` setting and `AGENTS.md`; both already tracked, neither changed here. User prefers Nix apps, Homebrew fallback, and agrees to perform privileged/provider checks. Essential app/workflow choices remain pending.
- User authorized read-only SSH to configured alias `maurerf.com` (`fdm`, port 22). After existing RSA authentication failed, user explicitly requested and performed SSH key setup outside this story's discovery: generated a dedicated Ed25519 key locally, appended its public key remotely, loaded it into the local agent. User reported key-only `id -un` returned `fdm`; independent agent connection also returned `fdm`. No key contents retained. Password access was not disabled.

### Current baseline and gaps

| Item | Observation / evidence |
| --- | --- |
| Mac active and selected | `/nix/store/5vylcskg3kzqc55b9nb71x9hxkhnnx63-darwin-system-26.05.56c666e`; both `realpath` commands exit 0 |
| Mac selected generation | `system -> system-34-link` from `ls -ld /nix/var/nix/profiles/system`; privileged full generation listing pending |
| Mac revisions | nix-darwin `56c666e108467d87d13508936aade6d567f2a501`, nixpkgs `a0991c886dc83e6e9de01d5266e4842985b1850e`, from deployed `darwin-version.json`; both match current lock. Configuration commit unknown (`darwin-version --configuration-revision`, exit 1); deployed Home Manager revision unknown |
| Mac runtime | arm64; Nix 2.34.7+1; command resolves to `/run/current-system/sw/bin/nix`; root/system launch daemon running (PID 383); daemon ping exit 0 outside sandbox. Installer lineage remains unknown |
| Mac build users | `_nixbld1` through `_nixbld32`, UIDs 351 through 382 respectively; `dscl . -list /Users UniqueID` exit 0 outside sandbox |
| Mac channels | User list empty, exit 0; root list blocked by interactive sudo requirement |
| Mac Nix inventory | `nix profile list`: `home-manager-path` at `/nix/store/9a5dmxglkahgxnci1922pifwvmvgzq8v-home-manager-path`; `nix-env -q`: `home-manager-path`; system requisite listing exit 0, 411 paths (below). Store membership does not establish declarative ownership |
| Home Manager ownership | User profile 14 selected, timestamp May 23; separate HM generation 20 link timestamp November 28, 2025 points to `/nix/store/j6pm1y261zs5d3bhcilpfvlxfii4jl90-home-manager-generation`. Standalone/integrated ownership relationship unresolved; blocks cleanup |
| Homebrew | Formula inventory exits 0 on authorized retry; cask inventory fails on installed Chromium definition. Directory metadata below is supplemental, not proof of a complete working cask inventory. No-cleanup/no-upgrade/no-auto-update repo policy unchanged |
| VPS architecture/version | x86_64; `nixos-version --json` exit 0: NixOS `26.05.20251129.59b6c96`, nixpkgs `59b6c96beacc898566c9be1052ae806f3835f87d`; configuration revision unknown (command exit 1); other deployed input revisions unknown |
| VPS active and selected | `/nix/store/yhczh27iwxqsbikj51c4lkb4gpwzzmwh-nixos-system-nixos-vps-26.05.20251129.59b6c96`; both `realpath` commands exit 0 at 08:46 UTC |
| VPS retained roots | `nix-store --query --roots /run/current-system` exit 0 lists `/run/booted-system`, `/run/current-system`, and `/nix/var/nix/profiles/system-21-link` pointing to baseline |
| VPS mounts | `findmnt -o TARGET,SOURCE,FSTYPE`, `lsblk -o NAME,TYPE,FSTYPE,MOUNTPOINTS` exit 0: `/dev/vda1` ext4 mounted at `/` and `/nix/store`; `/dev/vda2` swap. Full hardware/source comparison pending Layer 3 |
| VPS channels | Login user `nix-channel --list` and `sudo -n -iu fdm nix-channel --list` both empty, exit 0; root pending |
| VPS privileged metadata | Generation list, legacy-file stat and root channel commands each exit 1: `sudo: a password is required`; user-run commands required |
| VPS state/backup | Actual state-path metadata and complete backup coverage matrix still pending; provider backup identity/time/consistency/retention and console test not verified |

Unexpected command side effect: the story-prescribed roots query reported `removing stale link from '/nix/var/nix/gcroots/auto/rqf12cms9pmns2c7w381w51w7q9fs6y7' to '/home/fdm/.local/state/home-manager/gcroots/new-home'`. No GC or generation deletion was requested. This contradicts a strictly mutation-free discovery assumption; the query will not be repeated. The retained baseline generation was listed afterward. No live service/network change was made by the agent.

Caskroom directory metadata (`/opt/homebrew/Caskroom`, Python directory listing, exit 0): chromium `latest`; claude `0.14.10,fe3f5688c1c2a4b648d1bf6d9784d62ef9fc336a`; claude-code `2.0.69`; element `1.12.7`; google-chrome `143.0.7499.170`; monero-wallet `0.18.4.5`; openscad `2021.01`; steam `4.0`; tor-browser `15.0.3`; x2goclient `4.1.2.2`.

Rollback for documentation only: `git restore --source=80656bee2ba0ea7a31da9912e9952213248eb446 -- docs/goals/01-checkup/stories.md docs/goals/01-checkup/EVIDENCE.md`. No host activation to undo. Future Mac generation parameter is 34 and VPS baseline parameter is 21; full recovery readiness is not yet verified and no generation switch is authorized by US-01.

### Mac collection outputs

Initial sandbox errors are retained; authorized retries below supersede only checks that passed. Homebrew cask and sudo failures remain open. Daemon output is reduced to state metadata.

<details><summary>Initial Mac metadata and inventories</summary>

```text

$ git status --short --untracked-files=all
[exit 0]

$ git rev-parse HEAD
80656bee2ba0ea7a31da9912e9952213248eb446
[exit 0]

$ git diff --check
[exit 0]

$ shasum -a 256 flake.lock
588bbd7ec23a66acf237ee4859f1794958d1233a964e63c1d25c06bad4886224  flake.lock
[exit 0]

$ date -u
Sat Sep 26 08:45:43 UTC 2026
[exit 0]

$ uname -m
arm64
[exit 0]

$ nix --version
nix (Nix) 2.34.7+1
[exit 0]

$ command -v nix
/run/current-system/sw/bin/nix
[exit 0]

$ realpath /run/current-system
/nix/store/5vylcskg3kzqc55b9nb71x9hxkhnnx63-darwin-system-26.05.56c666e
[exit 0]

$ realpath /nix/var/nix/profiles/system
/nix/store/5vylcskg3kzqc55b9nb71x9hxkhnnx63-darwin-system-26.05.56c666e
[exit 0]

$ darwin-version --configuration-revision
/run/current-system/sw/bin/darwin-version: configuration commit hash is unknown
[exit 1]

$ cat /run/current-system/darwin-version.json
{
  "darwinLabel": "26.05.56c666e",
  "darwinRevision": "56c666e108467d87d13508936aade6d567f2a501",
  "nixpkgsRevision": "a0991c886dc83e6e9de01d5266e4842985b1850e"
}
[exit 0]

$ sudo -n nix-env -p /nix/var/nix/profiles/system --list-generations
/bin/sh: /usr/bin/sudo: Operation not permitted
[exit 126]

$ dscl . -list /Users UniqueID
Operation failed with error: eServerError
[exit 70]

$ nix-channel --list
[exit 0]

$ sudo -n nix-channel --list
/bin/sh: /usr/bin/sudo: Operation not permitted
[exit 126]

$ nix profile list
error: cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted
[exit 1]

$ nix-env -q
home-manager-path
[exit 0]

$ nix-store --query --requisites /run/current-system
error: cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted
[exit 1]

$ HOMEBREW_NO_AUTO_UPDATE=1 brew list --formula --versions
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
[exit 1]

$ HOMEBREW_NO_AUTO_UPDATE=1 brew list --cask --versions
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
[exit 1]

$ ls -ld /nix/var/nix/profiles/per-user/*/*
lrwxr-xr-x  1 root  wheel  14 Mar 27  2025 /nix/var/nix/profiles/per-user/root/profile -> profile-2-link
lrwxr-xr-x  1 root  wheel  60 Mar 27  2025 /nix/var/nix/profiles/per-user/root/profile-1-link -> /nix/store/3z38jxq9s7916yalrq3q5h75h7b99ivn-user-environment
lrwxr-xr-x  1 root  wheel  60 Mar 27  2025 /nix/var/nix/profiles/per-user/root/profile-2-link -> /nix/store/qmw5hflz7jrnsfhfw024b4744g0jnnj0-user-environment
[exit 0]

$ launchctl print system/org.nixos.nix-daemon (selected metadata)
state = running; pid = 383; domain = system
[exit 0]

$ nix store ping --store daemon
warning: 'ping' is a deprecated alias for 'info'
Store URL: daemon
error: cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted
[exit 1]
```

</details>

<details><summary>Authorized Mac inventory retries</summary>

```text

$ sudo -n nix-env -p /nix/var/nix/profiles/system --list-generations
sudo: a password is required
[exit 1]

$ dscl . -list /Users UniqueID
_accessoryupdater        278
_amavisd                 83
_analyticsd              263
_aonsensed               300
_appinstalld             273
_appleevents             55
_applepay                260
_appowner                87
_appserver               79
_appstore                33
_ard                     67
_assetcache              235
_astris                  245
_atsserver               97
_audiomxd                294
_avbdeviced              229
_avphidbridge            288
_backgroundassets        291
_biome                   289
_calendar                93
_captiveagent            258
_ces                     32
_clamav                  82
_cmiodalassistants       262
_coreaudiod              202
_coremediaiod            236
_coreml                  280
_corespeechd             306
_ctkd                    259
_cvmsroot                212
_cvs                     72
_cyrus                   77
_darwindaemon            284
_datadetectors           257
_demod                   275
_devdocs                 59
_devicemgr               220
_diagnosticservicesd     307
_diskimagesiod           271
_displaypolicyd          244
_distnote                241
_dovecot                 214
_dovenull                227
_dpaudio                 215
_driverkit               270
_eligibilityd            297
_eppc                    71
_findmydevice            254
_fpsd                    265
_ftp                     98
_gamecontrollerd         247
_geod                    56
_hidd                    261
_iconservices            240
_installassistant        25
_installcoordinationd    274
_installer               96
_jabber                  84
_kadmin_admin            218
_kadmin_changepw         219
_knowledgegraphd         279
_krb_anonymous           234
_krb_changepw            232
_krb_kadmin              231
_krb_kerberos            233
_krb_krbtgt              230
_krbfast                 246
_krbtgt                  217
_launchservicesd         239
_lda                     211
_locationd               205
_logd                    272
_lp                      26
_mailman                 78
_mbsetupuser             248
_mcxalr                  54
_mdnsresponder           65
_mds_stores              308
_mmaintenanced           283
_mobileasset             253
_mobilegestalthelper     293
_modelmanagerd           301
_mysql                   74
_naturallanguaged        304
_nearbyd                 268
_netbios                 222
_netstatistics           228
_networkd                24
_neuralengine            296
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
_notification_proxy      285
_nsurlsessiond           242
_oahd                    441
_ondemand                249
_postfix                 27
_postgres                216
_qtss                    76
_reportmemoryexception   269
_reportsystemmemory      302
_rmd                     277
_sandbox                 60
_screensaver             203
_scsd                    31
_securityagent           92
_sntpd                   281
_softwareupdate          200
_spinandd                305
_spotlight               89
_sshd                    75
_svn                     73
_swtransparencyd         303
_systemstatusd           298
_taskgated               13
_teamsserver             94
_terminusd               295
_timed                   266
_timezone                210
_tokend                  91
_trustd                  282
_trustevaluationagent    208
_unknown                 99
_update_sharing          95
_usbmuxd                 213
_uucp                    4
_warmd                   224
_webauthserver           221
_windowserver            88
_www                     70
_wwwproxy                252
_xserverdocs             251
daemon                   1
fdm                      501
nobody                   -2
root                     0
[exit 0]

$ sudo -n nix-channel --list
sudo: a password is required
[exit 1]

$ nix profile list
Name:               home-manager-path
Store paths:        /nix/store/9a5dmxglkahgxnci1922pifwvmvgzq8v-home-manager-path
[exit 0]

$ nix-store --query --requisites /run/current-system
/nix/store/wjb6smwmv8cynnr776j01kjjzdks1863-libiconv-113
/nix/store/006xa3d3jpk1zfgra659c03ycf2mjgvf-libxml2-2.15.2
/nix/store/55976waa157aqb1ncbwm6b8sa64b6m3h-bash-5.3p9
/nix/store/b7rf7jfkadwjajzfb5430l5k60gwfqa8-gzip-1.14
/nix/store/k4wdywbxc30a2zkcqb001ynk2nrn7hxc-libpipeline-1.5.8
/nix/store/w80mvsvnh5i0c0kaj021fkip8jwxx59x-pcre2-10.46
/nix/store/209wkryzwczs2nlvwfzkwf4fm8mpr922-gnugrep-3.12
/nix/store/ym2h5axmyxqkwmrrrz570gmkbmdlwvbv-zstd-1.5.7
/nix/store/lj773k1dkd7rrnrf0f05v43kwwbzlv4j-zstd-1.5.7-bin
/nix/store/vl3ks60vd1cz4qikf6lsisgxfw7vk944-gdbm-1.26-lib
/nix/store/wk31bzyqagz4v80pfxd991rny5xs08b8-groff-1.24.1
/nix/store/yq024wygl044gnrl60hgdjarssr2s05n-libiconv-1.19
/nix/store/057cy9ar5m89d9z4bkmli0nj0gf0cc2a-man-db-2.13.1
/nix/store/w2p4mqmibyga0ky3vc3gnc3cx8h1z71b-libjpeg-turbo-3.1.4
/nix/store/2g9rnpa6zwbdakyir4q6dymmh3yy9cq5-libjpeg-turbo-3.1.4-bin
/nix/store/0a7s99l4wvk54r4fr1fglcb3qdg4nd4s-libjpeg-turbo-3.1.4-dev
/nix/store/7fd0wqc1740i2aarz17d32q27df3kzz4-zlib-1.3.2
/nix/store/a3hhkd5vzw97issax60xx47qfnkl6ddf-openssl-3.6.2
/nix/store/0g9lxmqdacn32rdwdylq9wpvlnncha4y-libssh-0.12.0
/nix/store/jzqnwkdgnjbrc93dc5a64j1b3vihq3qd-libevent-2.1.12
/nix/store/0gxq3y4v4zv57by93ck0gpnfqh5g0237-unbound-1.25.0-lib
/nix/store/0hsah34vpvbryrswd0jyc62fnl5qpmhb-openmp-21.1.8
/nix/store/dv84ssvw208w1h2qmak900apymwggm5f-sqlite-3.51.2
/nix/store/0hzmsbn5h50x7iyz1h5svbr68hppyicy-sqlite-3.51.2-bin
/nix/store/ln0v5nw4npw0sfbirlrqlcsh1if985ks-hm-modules-messages
/nix/store/zhrjg6wxrxmdlpn6iapzpp2z2vylpvw5-home-manager.sh
/nix/store/0i8brkmklg13vmlpa23nla4baxi78jdc-cleanup
/nix/store/0mg83n6ffj8s1ds2v51f04fkjy95v19h-db-5.3.28
/nix/store/1grha530b89vf9kvy4h7iq0vw3nc7kn3-libxdmcp-1.1.5
/nix/store/jlk1bkniydvdp2pbzz1immjg2nng97c6-libxau-1.0.12
/nix/store/imxl64gn7zk3brsafc93m8pdq1yjnr8w-libxcb-1.17.0
/nix/store/qlf957gf9kxppc0g1jy1c8i5zb0in4sb-libx11-1.8.13
/nix/store/0nvjznq3lwj4khjlmx8viflkdvwvjdjw-dbus-1.16.2-lib
/nix/store/34vh5z9xzgb1ryjdhv0pgrrcpxkywa6r-cups-headers-2.4.19
/nix/store/3r9in20wx4a44zsl9w4zrj0bvhbaylk8-libsbuf-14.1.0
/nix/store/395mclyn4inz8fip5ziajhbn3x9kp41i-libsbuf-14.1.0-dev
/nix/store/6k0xx9g14x2v1z2fszlgmy8w1apdva82-xcbuild-0.1.1-unstable-2019-11-20
/nix/store/3kxj3awllmqgh4fl2rvpx142wm9h8xvm-xcbuild-0.1.1-unstable-2019-11-20-xcrun
/nix/store/3w2mfy2cfwlzavyd8pp64wxhpz3rz7la-xz-5.8.3
/nix/store/hkbvhgk3nn4r29lj87b8yw1iw5f619zb-bzip2-1.0.8
/nix/store/4vk8m4smngx0sidrx42dg8y310lwdkz0-xar-minimal-501-lib
/nix/store/gw804vbc81v9zvmpldcjwq65fbmd4lz8-ld64-956.6-lib
/nix/store/f0afx0r5bzvk3gdf8bdh4fssl0p75m1k-libffi-40
/nix/store/mwmz2rvjjmhckhpis9il7qzphns6cqnj-llvm-21.1.8-lib
/nix/store/8sab9m2g06nd3bqklxxg3ndfdgs83ij6-ld64-956.6
/nix/store/albld8nis2gsip1yf4girprwssc3r7aj-cctools-1010.6-libtool
/nix/store/7r160i3gca967vnnsx9qkazinqhsqrxp-ncurses-6.6
/nix/store/s154z0gs3vbrgzc4yib68jqwxdsk1wpf-ncurses-6.6-man
/nix/store/mf726axqd5br0x4q9b0h0ycab29s8fmy-ncurses-6.6-dev
/nix/store/rc9xga34lhavrc95lfbpmcvln61z2s7v-libutil-73
/nix/store/p4lp3xq4imd1qzqh08x8vcq2zfhi7rca-libresolv-93
/nix/store/vcac1sln6n4qsf7a96758kr1y9r5nzf7-libresolv-93-dev
/nix/store/329vgmwkd4vp36lfih4l0l6z6n43q3fr-llvm-21.1.8
/nix/store/9gcfdl3yd942z2v6aszaqdkc5zq3fc5p-clang-21.1.8-lib
/nix/store/cbsa0j0sqa44ls1wr2bgvbcx87k50j8h-clang-21.1.8
/nix/store/zfqw29ad23h86p8242ma5jp26z5nk00a-cctools-1010.6
/nix/store/z61v8rpy6ammvikrpcihn3ij8rrqk0bz-cctools-binutils-darwin-1010.6
/nix/store/zy85gk6dd29slqgs1i7xclvkgvhydgxg-libiconv-113-dev
/nix/store/0p9q77zfnr32pmql2j2qb1had4wkq06m-apple-sdk-14.4
/nix/store/0qgp1hw5dk9q0vjgcb1idpg91gcpjx6z-libcbor-0.13.0
/nix/store/0qs8qciszgr7zzdq3zvanxcax1ml5qd0-icu4c-76.1
/nix/store/0sqfgkfrjl7fhaibswkj7cy5fmkz7za4-darwin-manpages
/nix/store/5cfjgwf285nif079v2aisf7k642g98kd-libunistring-1.4.2
/nix/store/fk38lw91gqqr7vz1yjnqhasyis1c44hm-publicsuffix-list-0-unstable-2026-03-26
/nix/store/i5aw4v15lklq5r5w5clvcy8dxc2igjck-gettext-1.0
/nix/store/qzsfr7xjxisnglc5iwgmq3a8q8zy95xm-libidn2-2.3.8
/nix/store/0wk4mrmpas5dhpqz06f4gx4jfys4aib6-libpsl-0.21.5
/nix/store/11jbxpaa20x8kgsf4hjw2xdvj1ss6npb-hm_fontconfigconf.d52hmdefaultfonts.conf
/nix/store/af7n5cc4bzd9c6mwsgh7sfmcbasjr5kd-gawk-5.4.0
/nix/store/gijqk3cnja6k2r41519j9hbjxr14q9pf-libxcrypt-4.5.2
/nix/store/i37q3dpd0wqclijpx1wspig9nf8waj4x-libcxx-21.1.6+apple-sdk-26.4
/nix/store/yxlbgn6b68633wi1y36gflf0qr5naz0v-compiler-rt-libc-21.1.8
/nix/store/qg5wnjpr27gvwwpcv5bi7ssc38p2nrf2-compiler-rt-libc-21.1.8-dev
/nix/store/vbfjrppkj89nzlb861xsr5k5zfsq60xp-gmp-with-cxx-6.3.0
/nix/store/y0ha8v4gh5vnwwmp2r0msfbdlvgwv2np-coreutils-9.11
/nix/store/js13ri9fvm0ajk1fpd3acigys2a9whdv-perl-5.42.0
/nix/store/11z79l6269mwnhzjycv4wwsm2lpcnz92-texinfo-interactive-7.2
/nix/store/1a25w360ypg3p45670nxssrf6k2rnw4c-launchd
/nix/store/1bpx2sy9wmjr7v16g4s2afvlw7fvgigd-perl5.42.0-HTML-TagCloud-0.38
/nix/store/1fcpj9592jbfmprbrlq7smkavinsgx6l-libtool-2.5.4-lib
/nix/store/rhxwbyjjx1g6smisvmji280j1asjcszx-sdl3-3.4.8-lib
/nix/store/1frhnmg2aak3f4msx0zc2zx1mirhzb2i-sdl2-compat-2.32.68
/nix/store/ffz616wjbidqjfx5azbslfapzj8f0hc7-glib-2.88.1
/nix/store/c2sl2xgzjv2d6n2j0d2v7wadsnxf2s48-zlib-1.3.2-static
/nix/store/db7jzr61wj1xnflacfcnfhzk3ci1gwrx-brotli-1.2.0-lib
/nix/store/v3ikgn81d6y9rfbwh7d8zrhiydqzwcr1-libpng-apng-1.6.56
/nix/store/fj3p5vnkw69gv9x2321xgzplpr2dlirn-freetype-2.14.2
/nix/store/2qvv3xdpnpfhzjf69lnjds95qjdwmnd7-graphite2-1.3.14
/nix/store/qlnyhi8j8p0ks4hd8dlaxbjzx03mrq2n-harfbuzz-13.2.1
/nix/store/8ixzxd06y0q26svdjgfcxqa3mbc2w05z-qtbase-5.15.18
/nix/store/1gysjzxxb2b7m17s2pwwmdzcrrlnp1hy-qtmacextras-5.15.18
/nix/store/lpk0d57z5jnsqszvr1pxbhflz0pfvqrq-hidapi-0.15.0
/nix/store/1j9qh1d0avxcc3n7223gbn6nfqmc8hd7-libfido2-1.17.0
/nix/store/3z3ksp4dkl7klq5dyz691vi3ykc7s438-nghttp3-1.15.0
/nix/store/ahv7ryg45y6n6yx7l0602684gx2w110m-krb5-1.22.1-lib
/nix/store/cazd7ilkx7m793lp6x4jbwb667khfr03-ngtcp2-1.22.1
/nix/store/mm86qwzdnjlj2lkghh7x7jnpmn3wwnxq-nghttp2-1.69.0-lib
/nix/store/zkn7s55w769vg1zj0x1j9xa8af16cfi9-libssh2-1.11.1
/nix/store/5ksfjgx970dszhbjn6kcbcf07yn52s1i-curl-8.20.0
/nix/store/nyy4cjg260pg208qn4y0kz0ajjrgnwn1-aws-c-common-0.12.4
/nix/store/bpmqjdb53390ivkmq9yg25gcvcpza4hw-aws-c-sdkutils-0.2.4
/nix/store/j0jib3bb1cc0l0pdsx2wmcqs37hbyjf4-aws-c-compression-0.3.1
/nix/store/l9rd17y8g89ypsnrq2kk0k6ljmx7k901-aws-c-cal-0.9.2
/nix/store/zc4xf43vkibnmrqa5fkf1hmbampisbh6-aws-c-io-0.22.0
/nix/store/z91fg66qzmmak2v7n56x97hp721r4gjp-aws-c-http-0.10.4
/nix/store/d5vbzsysamw0pbcrv57q8zp3rv5dsfg8-aws-c-auth-0.9.1
/nix/store/i0w90sjzyk5g7rfqa0vgjdhhd4c7mjyj-aws-c-mqtt-0.13.3
/nix/store/r2f3dcyigx0xk9mlcwcm5nwxr6npf3l2-aws-checksums-0.2.7
/nix/store/kj7g0s4lfba73q2n1g8mwk8z6y70a3qa-aws-c-s3-0.8.7
/nix/store/m13raswmd913npf321mm017pdn679pnp-aws-c-event-stream-0.7.0
/nix/store/g5z5sw4s3k00cra1wx9v90igarawnb4f-aws-crt-cpp-0.34.3
/nix/store/jv1w62hn202j08lv1qhkfzvjzan5f0g8-boost-1.89.0
/nix/store/5gy08jxdar6a1babgz4bvh4n5rqj4iyc-libarchive-3.8.7-lib
/nix/store/kqa4cn2vvgkwpg95iy87xp1l9703nmxm-hwloc-2.13.0-lib
/nix/store/hbz5vlnnj7jxkq799z5s3kxs4w6zdi63-onetbb-2022.3.0
/nix/store/ffajsd7db8rrk4dhz7frxcfs7aivybyw-libblake3-1.8.5
/nix/store/k76pj1hviqk0dskprc71l67qps5vyyq7-libsodium-1.0.22-unstable-2026-04-09
/nix/store/xy2cwwf9p2dm7jyr2p28z1x7gsfa90mc-nix-util-2.34.7+1
/nix/store/c0kfk34k51lsh6c60698jgikls68x5wz-nix-store-2.34.7+1
/nix/store/sc7xvn2c13ys6lp2kgwlh15lsas99hln-llhttp-9.4.1
/nix/store/naasyiz4rk88izrbflxj38rldbi2j4rn-libgit2-1.9.3-lib
/nix/store/1k2drl5sryf93c3qmfy4h5wpiwgd23ry-nix-fetchers-2.34.7+1
/nix/store/2v78pvk47b3m8dk8hlrm6wcwfi1zwfsy-set-environment
/nix/store/1lf275d21k18qzchyndpzp5aana1hl61-etc-zshenv
/nix/store/1qkqqfssqmc619zypmvrif303h1mfzc0-obsidian-1.12.7
/nix/store/1w6c4g5dfb6gm4ap4wws5yhvvimln6y1-find-xml-catalogs-hook
/nix/store/dzfbmsdl1lpifqxdvzmrhmhws3d3hccb-dejavu-fonts-minimal-2.37
/nix/store/4ikv2swz7jrgmxvfk4qgvqapfxhi6l49-fontconfig-2.17.1
/nix/store/yxxnl1wqyr8vqragaqgmaakwsd50ldic-expat-2.8.0
/nix/store/27baqcz7fz5dawq1hykr8d2m42884xxc-fontconfig-2.17.1-lib
/nix/store/zkzv2c17wg754csi4ylh7lx7vvxds4ib-fribidi-1.0.16
/nix/store/1xwxcrgc75siv8vyg03y7pz7mvd5sw26-libass-0.17.4
/nix/store/bn5al38x9rlkkzk9g3qgcc5bywfdrjvv-glib-2.88.1-bin
/nix/store/4jrqpgl7v6yvm9x8ni57gps35fgsa95l-mpdecimal-4.0.1
/nix/store/d8b0n9qmlsdj6xhv1s67k494z4x9yb91-mailcap-2.1.54
/nix/store/klc90kbqghhp57qazsqh0mkjpzvj7gb7-tzdata-2026b
/nix/store/g5cw2v1yh7ifakwwr28wl602a2qc55cs-expand-response-params
/nix/store/y7k7r9xlbp370zxvrybafsp5j2y03b7s-libSystem-B
/nix/store/apfz522rdhd9ik8chych1128l3b4qqm6-cctools-binutils-darwin-wrapper-1010.6
/nix/store/l32bv33wqwkj2l1y8dp5x6h9r3q9im77-clang-wrapper-21.1.8
/nix/store/xy5a4pba2kn5rpyf5f3nc72nygv6viad-readline-8.3p3
/nix/store/ygxqin6ydzjfawywqpp5pal8wv6sf5bh-python3-3.13.13
/nix/store/n08lmcznhdpn8h6811i7mlmy6shvj4rn-python3.13-packaging-26.1
/nix/store/qa3fdfbs0ypr76higqa87rc169fnq2gx-zlib-1.3.2-dev
/nix/store/w7dzmiqzvyi34aw6xxpa4jbwpgni41h7-libffi-40-dev
/nix/store/285c41x52g9p1bc6sljq0vhk4hr5ill8-glib-2.88.1-dev
/nix/store/sr9glsi4p7jkvi10dr2cg9l6275gnm0a-giflib-5.2.2
/nix/store/6ngw4144l9b5wh55kfdavags43jznrif-libwebp-1.6.0
/nix/store/sgyc3fabscpykhirlq7qg76xidhwbs32-lerc-4.1.0
/nix/store/vqrwlnvr1wq43nnlx6q092v0hmnvlxnf-libdeflate-1.25
/nix/store/z6bj80hy9fbrk7zchsvw23dv4z079j4n-libtiff-4.7.1
/nix/store/29422zhl8b4pldca52ynskii2zxklml3-libwebp-1.6.0
/nix/store/2k3ykxbw5ijc9inba9fpa5fac7lislk0-perl5.42.0-Encode-Locale-1.05
/nix/store/rv03agpf25pj2lvq6apvpqpva9fx63l2-perl5.42.0-URI-5.21
/nix/store/34lb1kcgk5nid7knrjfc4ilklbr5wgqs-perl5.42.0-Net-HTTP-6.23
/nix/store/5jaj741kz8q9ccvnkf4fawj6ksq8gzhn-perl5.42.0-Clone-0.46
/nix/store/5vali02qa3q3n89c6f4zixiamzgp10d9-perl5.42.0-HTML-Tagset-3.20
/nix/store/nw8136vyaz8q1cx57qy1yapb4c7qk30r-perl5.42.0-TimeDate-2.33
/nix/store/vsjb6j453nqc5k4djkrg08ms74ilq435-perl5.42.0-HTTP-Date-6.06
/nix/store/6kaj9d57r67vmx4hr060yg0adx8llhs2-perl5.42.0-HTTP-CookieJar-0.014
/nix/store/afxf6i2dqpp7rhq7xxs6my9qhlj8zx5d-perl5.42.0-IO-HTML-1.004
/nix/store/idfl32k0pijnimy1m66i82jrh0ng0ss2-perl5.42.0-LWP-MediaTypes-6.04
/nix/store/pb9pn7x9hlx1ylj3h5ra400ylsgm4w4b-perl5.42.0-HTTP-Message-6.45
/nix/store/9zyv4kyj2wkkf9mfrwdnmpfpdhxsjga0-perl5.42.0-HTML-Parser-3.81
/nix/store/cfd509nq3jvnlpgf4a6qlga7n8lh94wq-perl5.42.0-HTTP-Cookies-6.10
/nix/store/dljwghpqrz13dpg5aw7f61a1fhgy54zk-perl5.42.0-WWW-RobotRules-6.02
/nix/store/gdkkqxh3ifkf10j0a7mpradidl7703ai-perl5.42.0-HTTP-Negotiate-6.01
/nix/store/kmh4xi9vdpalvjcan1jd50i6yb73hpg4-perl5.42.0-Try-Tiny-0.31
/nix/store/mxr7fv638ik1dqsr8aw29idbjn2kwf59-perl5.42.0-File-Listing-6.16
/nix/store/2avw5z8jz9h3v5qamw4s12bv8dyy38hz-perl5.42.0-libwww-perl-6.72
/nix/store/rgj5b37yh71x9gsfg3w47gq1ff9kvx02-perl5.42.0-Digest-HMAC-1.05
/nix/store/za4mwg4zhvpqn4ycnhcirzal7vbh0mqi-perl5.42.0-Crypt-URandom-0.55
/nix/store/2q1yms42l4jcx5r2zyqcb554wfkkadbc-perl5.42.0-Authen-SASL-2.1900
/nix/store/2qc71vmmxc059bzf18l7s3apjbbd1y0y-mariadb-connector-c-3.3.5
/nix/store/470vj4qj2sblg25g0x3wagiad0fc6sds-perl5.42.0-FCGI-0.82
/nix/store/h9xrljyncl42csry11xlwjl47xxmjzfs-perl5.42.0-Net-SSLeay-1.92
/nix/store/v4v42j4d3sh07sda9m77s0v3s7k3zskr-perl5.42.0-Mozilla-CA-20230821
/nix/store/51sxxzgqnm2ckj38z8zhlnhadq6xwfw4-perl5.42.0-IO-Socket-SSL-2.083
/nix/store/al1sk8na2shd5aqafq171q5h6473ar7y-perl5.42.0-libnet-3.15
/nix/store/cm2757n02a6pdlw50hm9czf1nb3477h9-perl5.42.0-CGI-4.59
/nix/store/f3swqrfhf2afil8fyd56y9amckadkz7b-perl5.42.0-FCGI-ProcManager-0.28
/nix/store/fgzqrjb8a6cwkdkck89n94rqvqzkx2va-perl5.42.0-CGI-Fast-2.16
/nix/store/jmww9gmmd1h1wjhlw4adcfnb2xkbab1w-bash-interactive-5.3p9
/nix/store/qwwprjig6pg0ss6irqrmy6zsn9p0i76d-zlib-ng-2.3.3
/nix/store/v1lxnb2804dgaf9sf60y6najgjs3wjsi-gnused-4.9
/nix/store/wglb6qrlhmm4hvi408ic94maamydgbqj-perl5.42.0-Net-SMTP-SSL-1.04
/nix/store/ycvl55s941y5mxx0v55p0bjicbkbknyh-perl5.42.0-TermReadKey-2.38
/nix/store/zn8gmbxxf5398hxg6y6nk5jimj85qj69-git-2.54.0-doc
/nix/store/a14yxcqvv9x2l9mllgpirzhvz93pgprg-git-2.54.0
/nix/store/a990pk52n1d14ssg2mjalbcjmv99hdlx-oniguruma-6.9.10-lib
/nix/store/yj3m8xi9h48mz4i7732zcwbqbb8bl402-jq-1.8.1
/nix/store/d551vj6hjc2bqiyg8dim6lv1v1xw7841-jq-1.8.1-bin
/nix/store/2shx8z57scjs1nkfrvcla6r7rg0900qv-darwin-rebuild
/nix/store/2vlf7nw8v0vcmzg8rgrsdlg2hk2a2l35-libsamplerate-0.2.2
/nix/store/858wvy72ks6k639vgnxv5hvr5dy2irsi-libedit-20251016-3.1
/nix/store/94ad87pr73pp31982x01vc37pi0svyf3-dns-root-data-2025-04-14
/nix/store/rwk2i8sy6v6ay3irsndj6zmqj9dj0n2d-ldns-1.9.0
/nix/store/2zlngby9hapcar0gmabg5hh0j688m7ab-openssh-10.3p1
/nix/store/30qhz45nwgfyns13ijq0nwrsjp8m7ypa-relaxedsandbox.nix
/nix/store/33836q01d78llcvys44wcxx5ycl6r57k-imath-3.2.2
/nix/store/r51ad62j4z7xzqa2svcb6d1b443kphzr-openssl-3.6.2-bin
/nix/store/8g69q86jfk5rpa34gny4rh057h5yb1nw-openssl-3.6.2-dev
/nix/store/r2q3yi45c1ai1alrflb2qb463448lkag-cyrus-sasl-2.1.28
/nix/store/33z2i8lallwh1pv8z2g5dr6srmi1zw0k-openldap-2.6.13
/nix/store/37amf2x51b2zzg08bzn49xva9kqli6zc-double-conversion-3.3.1
/nix/store/37rdk8zsdbqcp73l3nrmwilwb2ixkacv-diffutils-3.12
/nix/store/38iflsm1a0yl4siqw7b1s01cvzpjdn5x-find-xml-catalogs-hook
/nix/store/3ibiw5pwyh077w9kk52gzw2vq04qicnx-pcre2-10.46-bin
/nix/store/3mbhrbx0746qsxx92sw3vdjh1wk42p35-fix-qt-builtin-paths.sh
/nix/store/3wz2j41nnr1badij6fcnip5vgrfpdd82-findutils-4.10.0
/nix/store/a8wgbklzf7x3lvfrrf7cd66nv35b96lq-libogg-1.3.6
/nix/store/r96z8k8h3q6vgz3bs5jh1pn6wa8zlwzl-libvorbis-1.3.7
/nix/store/zm3q2sk317m9b8h96plmd5yswkg3px9r-libjack2-1.9.22
/nix/store/wa7h4i6s2s6r10ag0ccwkxhcdzpzfn9y-mpg123-1.33.4
/nix/store/3yi9dk4ls679f2qb15v5cfk1kk5xyqj0-libopenmpt-0.8.6
/nix/store/41sn31qsgbb25ggs7wqswx1lfzw9hvs2-libyuv-1908
/nix/store/49cn4djjy8gfh7waaxqnxrikx8ma9611-zimg-3.0.6
/nix/store/dback85z6zkz8538dvapzb3rzvl4igw0-nerd-fonts-fira-code-3.4.0+6.2
/nix/store/r8v6zk67mns5va9gwjd2i9lpkr2j2hw6-nerd-fonts-droid-sans-mono-3.4.0+1.00-113
/nix/store/4c62byga1qjmxc02q917sh5vi5fak00c-home-manager-fonts
/nix/store/4kf56vpj5wxg3r3algvhbgqf0pqkj2y7-patches
/nix/store/4qh71a0lmshqcaq8clkgin2862krps4j-dav1d-1.5.3
/nix/store/4sx8xhfkkmi6kv1g4gncrvb5120w89b0-etc-10-nix-darwin-extra-config
/nix/store/j3zvp1x4f6wgw4ywbibm7p0q80q9kwzd-libgpg-error-1.59
/nix/store/4w72rdllb4w9gvw5klcmn3qm84nrfjf7-libgcrypt-1.11.2-lib
/nix/store/58hijkf8gpd0idfq8xpn5ccag1aniisv-etc
/nix/store/6d7k1d5f4dncnxfnlgfxmkfnygsdb0ky-fonts
/nix/store/snmlyzf2v62a2krw3yyphppkbazx5rib-xxhash-0.8.3
/nix/store/srvqxabfy558a042yvramd18ykrm1sia-lz4-1.10.0-lib
/nix/store/z48qaksa3varl47q5a7a2hn4dd6vfsvv-popt-1.19
/nix/store/b3q1xr47mfzf7qza4550mgqvdhaqmy3p-rsync-3.4.1
/nix/store/pv77bjky7xj911y9vh0yc7h96mmydprl-darwin-version.json
/nix/store/r2xqa6w26rxf61iwbqzdx09ajbya2yvj-system-applications
/nix/store/qmq73gbx84ffkb2n2p1f8wvwmrmy32fb-darwin-manual-html
/nix/store/5q0ffyc5ysmd7il5j30yldiqkwcrzpcm-darwin-help
/nix/store/9pzj0ijyb5z6lwala9zj2kljz934q1i5-darwin-manpages
/nix/store/bblxh4qk96rb8632xwarzi6rdpsch4wb-darwin-option
/nix/store/ccywkc6nkfrf0vvm8plmdly8jc3b16wc-zsh-5.9-info
/nix/store/cn9bx1247d91ng6kg5v8fm078khn83vx-zsh-5.9
/nix/store/id48aywm43d68kcw0ykj58dx4ylphn8g-bash-interactive-5.3p9-info
/nix/store/kai7hcqrrxwnbkk73svsrx045kbzygd3-nix-zsh-completions-0.5.1-unstable-2025-12-12
/nix/store/kp2l7aamacvpsiwbqa7mva5p58mm56j1-zsh-5.9-man
/nix/store/qbh13xrbhr151qf4lkhq4g00gwf51cyv-darwin-version
/nix/store/z582wbk8fi8akrn1rmdp2s2lr93nfs6d-bash-interactive-5.3p9-man
/nix/store/sp34baa3yapf1fl6yrasnprdccvyz1sb-system-path
/nix/store/97rhdg7ny0z3p9480ifyk5jizpkjlg98-darwin-system-26.05
/nix/store/5550dnnskqpdgp7amap6dd8ilwhrssmz-darwin-uninstaller
/nix/store/573q593rxiwwd5lg3j36wzgsalg6ri1f-openh264-2.6.0
/nix/store/5rvf9lavfzx3mn6x4skklv0p9y2dcnv8-qttranslations-6.11.0
/nix/store/cnnmvi2n1wy3rd0dni7vxywcc6dgyzz4-libb2-0.98.1
/nix/store/gilbwbx8lzk7c920kai68v79d6p8klxh-unixodbc-2.3.14
/nix/store/jrvgiciwfrblqmdnhcz4b6wxi1p6q9az-libpq-18.4
/nix/store/vrqsgwdqs11kvgisd9fayzwggprflnrn-md4c-0.5.2-lib
/nix/store/kn0g4nac1xmy0di63349ihiirkb4dkjx-libtasn1-4.21.0
/nix/store/by9lissjjfm8hmmj61g86pirvriz92qw-p11-kit-0.26.2
/nix/store/njlxg30r2r7cx4jl5an1wvnwb7wswarg-nettle-3.10.2
/nix/store/x2sjxkz04ib8979grmv22hx9jb3gfvcr-gnutls-3.8.13
/nix/store/zwwrvpr9yd797f7ldgz2mimi4d52qym5-cups-2.4.19-lib
/nix/store/hf3xciirv7m7j08jbxsbi0ayrarfvy1y-qtbase-6.11.0
/nix/store/5dxvpdls3qjrxwsnkw91wr8p4xlqgqis-qtsvg-6.11.0
/nix/store/z901jn2diqzq0h4y7zj61xzvi9ibhj23-boehm-gc-8.2.12
/nix/store/5yfsr270svd9g34i3a9wxwwdacnb3l95-nix-expr-2.34.7+1
/nix/store/kqf1idckrfp83clg98rqjm3fxr3n9xh4-nix-flake-2.34.7+1
/nix/store/yiffk0xznijsxxnhs0wc881jqs55y5x8-nix-main-2.34.7+1
/nix/store/9hzs2cazisrhwb80wslymyvn1vhcv209-lowdown-3.0.1-lib
/nix/store/dimix96vis8kvdwb54rkz91fxjgj6jwx-editline-1.17.1-unstable-2025-05-24
/nix/store/yqibywdjnmv8b6ml5h5m8lyvchishchs-nix-cmd-2.34.7+1
/nix/store/p90c04f4ccrkfsa9aafl0xxgw55baiv6-nix-2.34.7+1
/nix/store/65ghpdw6n9vawhzx8bzqym2zmzrz4dmc-nix-2.34.7+1
/nix/store/5fjw0jzdqs5k41cjidrryjr8brs6k1ps-activate-system-start
/nix/store/a6r9ryv9pqcvwv8ffmzi4ichd5br0vl6-bzip2-1.0.8-bin
/nix/store/ndp5g6g334a8jcy1vhic7xjbv4vbix1z-bzip2-1.0.8-dev
/nix/store/73r9mbvmqzmzpcmb66pr78lx28q697h0-brotli-1.2.0
/nix/store/qvykrmzwy61rwdhmsm1wny62ws3cjjv2-brotli-1.2.0-dev
/nix/store/sldd0cg3kzn33r0n3apl4ia03b3a1f1w-libpng-apng-1.6.56-dev
/nix/store/5kbgxv51fmaicj2xrdyqgpd2bs4hs576-freetype-2.14.2-dev
/nix/store/5nlahsfgbjkvnzcn94mdc4gk5xa37xgs-qtsvg-5.15.18
/nix/store/7nkpd8lx25bij64a02znf1qfn4i86kkz-Brewfile
/nix/store/s8f6h6j55m6wag6syz914yv8pssi0ms2-org.nixos.activate-system.plist
/nix/store/z6rvnpb3hcwas31h9hfj7f99r14f5vdv-org.nixos.nix-daemon.plist
/nix/store/dgdxqh1l2w743g72zncysddwxrhbis7c-launchd
/nix/store/6602zq9jmd3r4772ajw866nkzn6gk1j0-sandbox.nix
/nix/store/qdv28rq2xlj68lsgrar938dq38v2lh5b-multiuser.nix
/nix/store/x8y0gf0ahwbb80y3i1dixxwybda07fa7-DarwinTools-1
/nix/store/f04hvy1qylrvhpdwqwmpnshcvljf8s1j-nix-info
/nix/store/lcp32r0gy4cww9y3z10hvq4azgc5wz4v-darwin-option
/nix/store/hb8lz5j11yva8cisnw2xb619wm0cr2vl-darwin-manual-html
/nix/store/mpj39pw0hkwc94nyys3z8c1lpcnp1ql6-darwin-help
/nix/store/80pvilsfv6yvhyvy1wpk3nhww4nlxmyv-nix-manual-2.34.7+1-man
/nix/store/qj0wmmf0f4by8dkvp0nxjlv5v3cgjk7d-nix-2.34.7+1-man
/nix/store/s2z38sa807mcf8l5rqx95669ar710ds4-darwin-rebuild
/nix/store/k2rpk17mhl258ipixmsh5x6djx6ryax9-system-path
/nix/store/7lcsp5a837sxk63plwz8b371dvgp6gcf-check-link-targets.sh
/nix/store/6iw08wwxyjdkbgrlw626rrx0b9acrvdr-oh-my-zsh-2026-02-19
/nix/store/6vbkykg92w603c0sw3mkk7p7mfaawbns-vim-9.2.0389
/nix/store/797kayh6j85nk24zr5lczdjvvrdq8kyp-anki-bin-25.02.5
/nix/store/864faj6ms5yfq4d89d19qqxgd1gsf1z2-htop-3.5.1-man
/nix/store/f5q5qhflsijx1drbsanwcjx0m9l717ix-gdk-pixbuf-2.44.6
/nix/store/nf848kxdm2v531ps3jrz2zkajz3g6fvz-libvmaf-3.0.0
/nix/store/s6jmfmm2f0fv2br169rz0l25sm238ccs-libaom-3.12.1
/nix/store/6m4c41hscai2wci3slvqb6jdv8bag9z0-libavif-1.4.1
/nix/store/9hwx2zm7pmhaqndwp6d6y893v6aias56-crc32c-1.1.2
/nix/store/cgy91xdc8via319g8xc6ljbc7j172cis-rnnoise-0.2
/nix/store/m2pw5cmwl8srdygzbf83l9p5wxz98x0a-mbedtls-3.6.6
/nix/store/wm0526j7ignr80xvmkv1mliv68qq04ms-cjson-1.7.19
/nix/store/63cfsnwigrsniakgcir832rdg9bgfsjf-librist-0.2.11
/nix/store/7m427m1c6dxvdwx5n1nib02k6lmc6ziv-ocl-icd-2.3.4
/nix/store/bdrlwm1jafi97kvbn17fm5sfm4iilg14-soxr-0.1.3
/nix/store/nldfa68q97khyrkwlgvm9mb4800wp05z-openmp-21.1.8-dev
/nix/store/fwa30fbrm8bd227wqsvdns3r7vrvacnr-vid.stab-1.1.1-unstable-2025-08-21
/nix/store/xc1kx77b2gyq100cjghwr1ynm2fwpnga-lcms2-2.18
/nix/store/g7aj9r1b34ykcraiv6kczjhlgrrkfzy0-openjpeg-2.5.4
/nix/store/gln0jbncidgbp700g09s1fyvkwi19b0b-libopus-1.6.1
/nix/store/hpcq9q64y559lrrhsr7x27f1aicwfbnh-x265-4.1
/nix/store/i7l210rgsqw4gij1jnvq226ny8im8dw1-lame-3.100-lib
/nix/store/jrmkl3fmkws0lkppfyd4k2vrxn2hs0d7-libbluray-1.4.1
/nix/store/lg7wd17vdnhznivrbqkxb4ci4iay2ygr-svt-av1-3.1.2
/nix/store/lvw8dq128wf9hp2hn77ik8ky2z1i3qka-libvpx-1.16.0
/nix/store/mir932sy3zj9252sld6mf8rs3p8ghiqq-srt-1.5.4
/nix/store/mmjdqv1chfbbdw9g6gg3fag629lq2ffg-x264-0-unstable-2025-01-03-lib
/nix/store/p5c7m34w0jfp88xf5flc2glh0bd2rl37-zvbi-0.2.44
/nix/store/rjik7y10rahmyrj36vv71vzqyav87prv-libtheora-1.2.0
/nix/store/xcb7zcxmwpf5ji551wygs9fq9s5p9hz0-speex-1.2.1
/nix/store/xs7mhszpmfwfjkgsg7cyb2ymfm6g5nf7-ffmpeg-6.1.4-data
/nix/store/frkwkag8ir500bc6rfcv7f8nj82wrl6w-ffmpeg-6.1.4-lib
/nix/store/vkcwlvbwsl5jn66331vnbzh55zqqhi6w-gtest-1.17.0
/nix/store/hjq73n6sf806498jcpm7jvczmxmmn3rd-abseil-cpp-20260107.1
/nix/store/jlr3jv51k05w86jlyjz80x4lqj5ri249-openexr-3.4.10
/nix/store/lgqc7ifkgsgmfa9w2c9s1sxq9c2slska-libjxl-0.11.2
/nix/store/z628iihn2b3c9l3b0qjcwq8762pkamc2-simdutf-9.0.0
/nix/store/lz9j3hnakb105kyyk23mpiyi89z22h19-ada-3.4.4
/nix/store/s2ahqp3asz0q3jcdnj95nlm2xcrcg9hh-qtbase-6.11.0-only-plugins-qml
/nix/store/vg80xfby8f6rp3w008q67dd9q34l36w7-openal-soft-1.24.3
/nix/store/zn287m5a1dznsxn729y0mz2hnxm8g7wr-libde265-1.0.18
/nix/store/y4clw6cnlgym1w6iisvlh7z30vr9wik0-libheif-1.21.2-lib
/nix/store/k5x4b0z7nm9ajc6898ijvb2z9ghcggkv-jasper-4.2.9-lib
/nix/store/qzmbszsplqw0hpn8lkwz5yafx14g8k3z-libmng-2.0.3
/nix/store/y08y87996mjak7snv9mm6pl30q7va720-qtimageformats-6.11.0
/nix/store/8nzm2yhvhj1c7h4z5xp0aqf4dx1kpi1a-telegram-desktop-6.8.1
/nix/store/9iv8rc5y9i1xb59630q4vd9091imvrm3-vim-9.2.0389-xxd
/nix/store/bhyqhlbbsh3hb204hdqgaqfvvzl1nmls-libargon2-20190702
/nix/store/fg6bssfcfgwbaw0b5xl0n8ga1rbl8a7z-qtdeclarative-5.15.18
/nix/store/ci1154j6jidl8x2bpqwd9f5ij058pz52-qtdeclarative-5.15.18-bin
/nix/store/harbgaf7lac2vql6pbhla04j2ymh34vn-minizip-1.3.2
/nix/store/k3rfl16rj1fj02vg5gfzy772lf5j2xl6-qtbase-5.15.18-bin
/nix/store/6zj23a5azn9rkbn88p5jnjrg5yzhiv9p-lndir-1.0.5
/nix/store/a8dnk8virxxrrpzw5wdx69jqf1cvs97f-icu4c-76.1-dev
/nix/store/qmka3x5p55qqp139wp528a8q42sma87m-libxslt-1.1.45
/nix/store/hbxgbd098bpn8k960jr16wv5g9649i68-libxslt-1.1.45-bin
/nix/store/v6v41dzykxhzqd25rg1zigrx4jjvcvpv-libxml2-2.15.2-bin
/nix/store/vz3g2lkiyjwpj0xw9sm3qq5lxwqr24xq-libxml2-2.15.2-dev
/nix/store/dnyd1wpjid0mgrh086hqb4swc39s6cm2-libxslt-1.1.45-dev
/nix/store/hkyi5gi52z06hyfpcr73pc0wxdm2hx22-sqlite-3.51.2-dev
/nix/store/p9f8v9jg8k55xsh6nhdahrhgpaddpb9y-graphite2-1.3.14-dev
/nix/store/i3hsha2findbrbvyx8hl50iwvj5r4vcp-harfbuzz-13.2.1-dev
/nix/store/ncf4wav0rymr01cxhdlg9c5w46zxdk5b-pcre2-10.46-dev
/nix/store/r8z8rqsp5pnkc565njjbnilr5ipbmf3r-fix-qt-module-paths.sh
/nix/store/y8m21z94jf2m7fhwq7cgmj4i3pqxrdj4-dbus-1.16.2
/nix/store/zrmh3gp3k26jzwmqhf1ppzk67ingala6-dbus-1.16.2-dev
/nix/store/r0wgjmbrh02k7jrwzxl22p12v631m4bm-qtbase-5.15.18-dev
/nix/store/z48hy6j3isapn1vfj2561p7mzy2msax5-qtsvg-5.15.18-bin
/nix/store/pzafbaw85s090xg4zhdw9a2gawv56958-qtsvg-5.15.18-dev
/nix/store/bwlbxl31pp49psjwlfn26x0ypdmmgkjq-qtdeclarative-5.15.18-dev
/nix/store/cf7xmdzhak4716isjbf0x1mmszkl35xr-qttools-5.15.18
/nix/store/k51vyc6ncxw63qipfz988f5al1ywc9rd-qttools-5.15.18-bin
/nix/store/p00pp6cxcrfq4w0j4i0qymgq09izxw0l-qrencode-4.1.1
/nix/store/x3h39wpjbmqw88l0465sf0vdvn0jwf0w-botan-3.12.0
/nix/store/ah0ka8pkyxvjks1rg3zd27vam2dfj26q-keepassxc-2.7.12
/nix/store/hjh68hnz6qvdwlf0fgsvmyh611swkd13-hm-session-vars.sh
/nix/store/ik0j9rzwvbmbh5jql5mxvx7x7c52l3a1-vscode-1.119.0
/nix/store/kliibri558ny9dgvyik9jh956fi98wxf-home-configuration-reference-manpage
/nix/store/nysp8hqjd4rzzp5bcv4d9343c5aq5j83-rar-7.21
/nix/store/qswzqhyg945h6rxb5ffhph4s16ckhv43-htop-3.5.1
/nix/store/rg49h6bkan305kq05wcppxpdxk7lmfwl-notion-app-4.24.0
/nix/store/9a5dmxglkahgxnci1922pifwvmvgzq8v-home-manager-path
/nix/store/w9vv7nr5srgbs6ygskcr30lf1jvf4pmk-libassuan-3.0.2
/nix/store/agaasmdvs36d0kq13vjzyplivdb5w5f4-pinentry-mac-1.1.1.1
/nix/store/fkg5m8cqcdlnzql298dbpa6hhc0n2dgq-npth-1.8
/nix/store/vifpc1ws0mp6l14fnsll4jhd83nqq8ps-libksba-1.6.7
/nix/store/cgh6iwzz5jgx9z5whka4vgj210i6npc6-gnupg-2.4.9
/nix/store/ap1v1g9f7ds8vq7l35l47zj1hyn6bp0a-hm_gitconfig
/nix/store/gv9a41f3m1qn7f0xxjwj4b7gy18ji91y-hm_Usersfdm.cacheohmyzsh.keep
/nix/store/jlr77ih8sldi4xck0nak9cibgr1jxxw5-home-manager-applications
/nix/store/lz3awwwn9xq0i9gn56f7yd9y9x64h1hm-hm_Usersfdm.localstate.keep
/nix/store/m0xkfwkgnq03v3kfyfr79i09ybki9id3-hm_..zshenv
/nix/store/7lxzhigfwqvbsqls0471qim3h8iwih40-zsh-autosuggestions-0.7.1
/nix/store/nxyjnsy3bi6dz9h1aa6v6ssf6k161v45-hm_..zshrc
/nix/store/qgwdkcl0jlq9xbdswslncj1vjv9zggmz-hm_LibraryFonts.homemanagerfontsversion
/nix/store/qhi8z0lmnw3xm54628k6z70masq20zwk-hm_fontconfigconf.d10hmfonts.conf
/nix/store/xx650cn403qvr9jswzsdmfgh6haax4ba-hm_Usersfdm.cache.keep
/nix/store/bbc46l8kyi28pxr3816wwmrgfnamqpr9-home-manager-files
/nix/store/nccff9xvackswd1ipf767466wm7dk46i-home-manager-agents
/nix/store/xh0f7vf9jpy779knk5pdzzhk1xdbw3rl-link
/nix/store/fwz1lp2kn4s0qz6mypkm5n942grpkycw-home-manager-generation
/nix/store/mybh4mljwyc39y34iv4i1x9y2j6cs5wa-activation-fdm
/nix/store/nrfk0cy0cjz2x5wqfxfq08f3fisw5p0x-darwin-version.json
/nix/store/pvxwwwrcl35xz31a5vpcr9hi8vvx2frc-mas-6.0.1
/nix/store/fx64jqg9nghharjsz3gw8lcpnp0d1c52-source
/nix/store/6x5hxz6bqq90jvm58q2j3dvwkj991pln-etc-registry.json
/nix/store/afaav62w2z4h75l1d2agf62qnpbz8x8l-etc-099-host-keys.conf
/nix/store/aixsn2dxxzh1y3v964fpi2c2c2lipchh-etc-100-nix-darwin.conf
/nix/store/dl4cxkgj1ysk8msmkzhkqiqsbmd2irdj-etc-bashrc
/nix/store/fklqy23lx8y740knb85x0b16fl464kbc-ca-certificates.crt
/nix/store/i21ls7paww35r2zlrb8w1d6fh1i50z4z-etc-zprofile
/nix/store/pi6q4wl856r1wy0nrmyqgr2y2kmj4d3x-etc-101-authorized-keys.conf
/nix/store/svsjlq5ag4sflh2iw8pbk06kilynqsbf-etc-zshrc
/nix/store/sx07fr39ghfyap3gl0l3bljy652sn1ra-etc-sudo_local
/nix/store/ynbvhby00g0wjxi0pa7w1yax9lz41q16-nix.conf
/nix/store/x08v8a5mc5832ak1fwp0rig4844ky98a-etc
/nix/store/yw31is252rdj271bpghxp1612z0ky2wq-system-applications
/nix/store/5vylcskg3kzqc55b9nb71x9hxkhnnx63-darwin-system-26.05.56c666e
[exit 0]

$ HOMEBREW_NO_AUTO_UPDATE=1 brew list --formula --versions
✔︎ JSON API formula_tap_migrations.jws.json
✔︎ JSON API cask_tap_migrations.jws.json
✔︎ JSON API cask.jws.json
✔︎ JSON API formula.jws.json
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
[exit 0]

$ HOMEBREW_NO_AUTO_UPDATE=1 brew list --cask --versions
Error: Cask 'chromium' definition is invalid: undefined method 'command_wrapper' for Cask 'chromium'
[exit 1]

$ nix store ping --store daemon
warning: 'ping' is a deprecated alias for 'info'
Store URL: daemon
warning: ignoring the client-specified setting 'store', because it is a restricted setting and you are not a trusted user
Version: 2.34.7+1
Trusted: 0
[exit 0]
```

</details>

VPS retained closure content verification completed with exit 0: [verified: `ssh -o BatchMode=yes -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519_maurerf maurerf.com 'nix store verify --recursive --no-trust /run/current-system'`]. No repair flag was used. This verifies contents, not signature trust or backup recoverability.

### User confirmations received during US-01

- Approved essential apps: VS Code, KeePassXC, Telegram, Obsidian, Claude, Steam, Tor Browser, Monero Wallet. For each, the user explicitly accepts successful startup as the observable workflow. Resolution paths, ownership and duplicate-resolution checks remain pending; no apps have been launched for this discovery. This supersedes the pending app-choice note above.
- Follow-up requested by user: remove the other previously listed apps (Notion, Anki, Chrome/Chromium, Element, OpenSCAD and X2Go). Removal is outside US-01 and has not been performed. Claude Code was not explicitly resolved separately from Claude; clarify before any removal affecting it. Retain the Nix-first, Homebrew-fallback preference.
- User-supplied VPS output confirms generations 1–21 are listed, generation 21 current, dated `2025-11-29 14:26:23`. Generation 20 is dated `2025-11-28 00:53:33`; generations 1–19 span November 2023 through February 2024. [verified: user transcript of `sudo nix-env -p /nix/var/nix/profiles/system --list-generations`]. No exit code or collection timestamp was supplied. This resolves the VPS generation-list gap above; a profile listing alone does not verify every historical closure's contents. Root channels and legacy-file metadata remain pending.

### Subsequent privileged metadata supplied by user (2026-09-26)

The following user-supplied results supersede the corresponding pending gaps above. No exit codes or collection timestamps were supplied.

- VPS root channel: `nixos https://nixos.org/channels/nixos-23.05`. [verified: user `sudo nix-channel --list`]
- `/etc/nixos/flake.nix`: regular file, 1306 bytes, root:root, mode 0644; modification/change `2024-02-27 12:42:50.190007009 +0100`; birth `2023-11-07 11:23:21.994894270 +0100`.
- `/etc/nixos/configuration.nix`: regular file, 3736 bytes, root:root, mode 0644; modification/change/birth `2024-02-27 12:03:45.940017262 +0100`. [verified: user `sudo stat /etc/nixos/flake.nix /etc/nixos/configuration.nix`]
- Mac generations 1–34 listed; generation 34 current, dated `2026-05-23 19:51:27`; generation 33 dated `2026-05-23 19:28:21`. [verified: user `sudo nix-env -p /nix/var/nix/profiles/system --list-generations`]
- Mac root channel list contains no entries. Both Mac commands warn that inherited `$HOME` belongs to another user and fall back to `/var/root`; this is consistent with running as root, and is retained as a warning rather than interpreted as a channel entry. [verified: user `sudo nix-channel --list`]

Historical deployment provenance and actual legacy consumers remain unknown; all legacy entries are retained.

### VPS mail-path discovery (2026-09-26)

At 08:53 UTC, selected service metadata was read successfully. [verified: SSH `systemctl show postfix dovecot rspamd redis-rspamd --property=Id,User,Group,StateDirectory,StateDirectoryMode,ConfigurationDirectory,FragmentPath`, exit 0]

Rspamd declares `StateDirectory=rspamd`, owner/group rspamd, mode 0700. Redis declares `StateDirectory=redis-rspamd`, owner/group redis-rspamd, mode 0700. Postfix and Dovecot do not declare StateDirectory in this query; this does not mean they lack persistent state.

- Postfix queue: `/var/lib/postfix/queue`. [verified: SSH `postconf -h queue_directory`, exit 0]
- Dovecot mail location: `maildir:~/mail`; `mail_home` is empty (user-specific home resolution remains to be established); state directory `/var/lib/dovecot`. [verified: SSH `doveconf -h mail_location`, `doveconf -h mail_home`, `doveconf -h state_dir`, each exit 0]
- All candidate roots exist: `/var/vmail` and `/var/sieve` virtualMail:virtualMail 0770; `/var/dkim` rspamd:rspamd 0755; `/var/lib/acme` acme:acme 0755; `/var/lib/rspamd` rspamd:rspamd 0700; `/var/lib/redis-rspamd` redis-rspamd:redis-rspamd 0700; `/var/lib/dovecot` and `/var/lib/postfix` root:root 0755. [verified: SSH `ls -ld /var/vmail /var/sieve /var/dkim /var/lib/acme /var/lib/rspamd /var/lib/redis-rspamd /var/lib/dovecot /var/lib/postfix`, exit 0]

Existence alone does not establish active configuration use or backup coverage. Sizes, per-path filesystem mapping, account credential path metadata, and backup coverage remain pending. Layer 1 remains incomplete; later layers have not started.

### VPS state metadata supplied by user (2026-09-26)

The user ran `sudo stat -c '%n owner=%U:%G mode=%a'`, `sudo du -sk`, and `findmnt -T ... -o TARGET,SOURCE,FSTYPE` for each path below. Every path maps to `/dev/vda1`, ext4, mounted at `/`. Sizes are allocated KiB from `du -sk`, not snapshot or restoration-space estimates. No command exit codes or collection timestamp were included in the transcript.

| State root | Owner:group | Mode | Allocated KiB | Backup coverage |
| --- | --- | --- | --- | --- |
| `/var/vmail` | virtualMail:virtualMail | 0770 | 1181968 | Unverified |
| `/var/sieve` | virtualMail:virtualMail | 0770 | 4 | Unverified |
| `/var/dkim` | rspamd:rspamd | 0755 | 12 | Unverified |
| `/var/lib/acme` | acme:acme | 0755 | 172 | Unverified |
| `/var/lib/rspamd` | rspamd:rspamd | 0700 | 98668 | Unverified |
| `/var/lib/redis-rspamd` | redis-rspamd:redis-rspamd | 0700 | 1860 | Unverified |
| `/var/lib/dovecot` | root:root | 0755 | 68 | Unverified |
| `/var/lib/postfix` | root:root | 0755 | 288 | Unverified |

[verified: user transcript of the per-path stat/du/findmnt loop]. This resolves the listed roots' size and filesystem gaps, not backup coverage or every runtime-path mapping.

Additional agent SSH reads:

- `doveconf -h plugin/sieve` returned `file:/var/sieve/%{user}/scripts;active=/var/sieve/%{user}/active.sieve`; `doveconf -h plugin/sieve_default` returned `file:/var/sieve/%{user}/default.sieve`; `doveconf -h plugin/sieve_dir` returned empty. All exit 0.
- `/etc/dovecot/dovecot.conf` points to `/etc/static/dovecot/dovecot.conf`. `/etc/dovecot/passwd` is absent; the combined `ls -ld` command exits 2 for that absent candidate, not for the runtime file.
- Fixed-string, quiet checks of `/etc/dovecot/dovecot.conf` confirm references to `/run/dovecot2/passwd` and `/var/vmail`; no config contents were printed. [verified: `grep -Fq -- /run/dovecot2/passwd /etc/dovecot/dovecot.conf` and the `/var/vmail` equivalent, both successful]
- Runtime account credential metadata: `/run/dovecot2/passwd`, root:root, mode 0600, 85 bytes. Filesystem `/run`, tmpfs. [verified: `stat -c '%n owner=%U:%G mode=%a size=%s' /run/dovecot2/passwd`, `findmnt -T /run/dovecot2/passwd -o TARGET,SOURCE,FSTYPE`, exit 0]. Contents were not read. This volatile file itself is not covered by a disk snapshot; the persistent source and regeneration mechanism must be identified and included in recovery coverage before acceptance.

Mac ownership follow-up: `nix-env -q -p /Users/fdm/.nix-profile` reports `home-manager-path`; the separate HM generation 20 `home-path` points to `/nix/store/hi80xg1wb5zvryaqi2y4bv5k2m6dgkbv-home-manager-path`, different from current profile inventory. `/etc/profiles/per-user/fdm` and `~/.nix-profile/bin/home-manager` are absent. Targeted extraction found no direct `*-home-manager*` store references in current `activate`/`activate-user` scripts; this does not prove absence of indirect integration. Ownership remains unresolved and blocks cleanup.

### Mail credential regeneration traced (2026-09-26)

The user recalled a hashed-password file and requested upstream research. Official [25.11 option documentation](https://nixos-mailserver.readthedocs.io/en/nixos-25.11/options.html#mailserver-loginaccounts-name-hashedpasswordfile) distinguishes `hashedPassword` from `hashedPasswordFile`. Its [Dovecot module](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/raw/nixos-25.11/mail-server/dovecot.nix) builds `/run/dovecot2/passwd` from source hash files during service pre-start. This release branch is reference material, not proof of the exact deployed mailserver revision (still unknown).

The deployed unit/script reference chain was independently inspected over SSH with path-only extraction, without executing scripts or opening the referenced credential file:

1. `/etc/systemd/system/dovecot.service` ExecStartPre points to `/nix/store/0qxbzm2pi3cn1642c5bfgwph5ccpcjyw-unit-script-dovecot-pre-start/bin/dovecot-pre-start`.
2. That script references `/nix/store/pmafv13yknakl5iyykzdj9wblg6p8ibh-generate-password-file`.
3. The generator references `/nix/store/rbd134q1jcz4n1rr5xkgbda7prqch8ma-f84dc212f4e528b17500f14dfbf26608750d68f65b32d6974fdc276a2b209f38-password-hash` and runtime outputs `/run/dovecot2/passwd` and `/run/dovecot2/userdb`.

[verified: SSH restricted `sed` extraction of ExecStartPre, then `grep -oE` extraction of absolute paths from the two scripts, commands exit 0]. No full unit/script bodies or hash values were printed or retained.

Source file metadata: root:root, mode 0444, 60 bytes, allocated 4 KiB; `/nix/store` on `/dev/vda1[/nix/store]`, ext4. The file belongs to the active system's requisite closure. [verified: SSH `stat -c '%n owner=%U:%G mode=%a size=%s'` and `du -sk` on the exact source path, `findmnt -T` on that path, and `nix-store --query --requisites /run/current-system` matched against that exact path; successful outputs]. File contents were not read.

This resolves the persistent credential-source/regeneration-path gap. Backup coverage still requires a verified completed snapshot covering the retained system closure and its persistent state; restoration has not been tested here. The runtime tmpfs location alone is not evidence that credential recovery is missing.

Safe local source inspection also found `hashedPassword` assigned at `machines/vps.nix:27` and `initialPassword` at `modules/nixos-base.nix:31`; values were suppressed. No assertion is made that this checkout produced the deployed hash. The store source is world-readable, consistent with the documented embedded-hash behavior. Protected runtime references and exposure/rotation review remain US-02 work; no credential was rotated, copied, or changed in US-01.

### Mac ownership and cask follow-up (2026-09-26)

Targeted inspection resolves the current integrated Home Manager ownership chain:

`/run/current-system/activate` invokes `/nix/store/mybh4mljwyc39y34iv4i1x9y2j6cs5wa-activation-fdm`, which references `/nix/store/fwz1lp2kn4s0qz6mypkm5n942grpkycw-home-manager-generation`. Its `home-path` resolves to `/nix/store/9a5dmxglkahgxnci1922pifwvmvgzq8v-home-manager-path`, matching the current user profile inventory. [verified: Python path-only extraction from the deployed activation script and wrapper, then `Path.resolve()` on the referenced generation's home-path; exit 0]. The earlier search for direct home-manager references missed this intermediate wrapper. Current activation is integrated with nix-darwin; the origin/role of the separate old generation 20 remains unproved and it must be retained.

`HOMEBREW_NO_AUTO_UPDATE=1 brew list --cask --versions claude claude-code element google-chrome monero-wallet openscad steam tor-browser x2goclient` exits 0 and reports:

```text
claude 0.14.10,fe3f5688c1c2a4b648d1bf6d9784d62ef9fc336a
claude-code 2.0.69
element 1.12.7
google-chrome 143.0.7499.170
monero-wallet 0.18.4.5
openscad 2021.01
steam 4.0
tor-browser 15.0.3
x2goclient 4.1.2.2
```

Python read only source metadata from `/opt/homebrew/Caskroom/chromium/.metadata/INSTALL_RECEIPT.json`: tap `homebrew/cask`, version `latest`, source revision path `a179ae002a744347a9660cd520b396a6a77d00b0/Cask/chromium.rb`. This reconciles all ten Caskroom entries with individual list output or the installed receipt. Chromium's full inventory command still fails with `undefined method 'command_wrapper' for Cask 'chromium'`; no definition, Homebrew version or package was changed. The exact Chromium binary version is not established by `latest`.

Layer 1 disposition needs user clarification: US-01 allows explicit unresolved Mac inventory/ownership gaps that block ownership-changing work, while the implementation prompt requires the preceding layer to pass before advancing. Full cask inventory has not passed. Ask whether to carry this specific gap forward under US-01's exception, retaining Chromium and prohibiting ownership changes, before starting Layer 2/3. No later layer has started.

### Layer 1 exception accepted; Layer 2 not applicable (2026-09-26)

User explicitly approved carrying the Chromium inventory failure forward as a documented exception while continuing read-only discovery. No package or ownership changes are authorized within US-01. Layer 1 accepted with that exception and retention of the old HM generation; Layer 2 is not applicable, as prescribed by US-01. Baseline architectures remain arm64 Mac and x86_64 VPS; no build or evaluation took place. Backup/provider and console verification belongs to subsequent gates, not a claim of Layer 1 recoverability.

### Layer 3 baseline discovery (2026-09-26, incomplete)

No target closure exists for this read-only story, so no upgrade closure delta or major-version/service removal comparison is applicable. The baseline paths remain those recorded above. No production activation or package change was made.

Mac app checks: sandboxed `mdfind` returned empty for all eight apps; authorized queries outside the sandbox returned the paths below (each exit 0). `ls -ld`, Python path resolution and selected Info.plist identity/executable inspection confirmed existing bundles. No apps were launched.

| Approved app | Filesystem path | Manager / resolution observation |
| --- | --- | --- |
| VS Code | `~/Applications/Home Manager Apps/Visual Studio Code.app` | Nix vscode 1.119.0; Spotlight instead finds `~/Applications/Home Manager Trampolines/Visual Studio Code.app` |
| KeePassXC | `~/Applications/Home Manager Apps/KeePassXC.app` | Nix keepassxc 2.7.12; Spotlight instead finds corresponding Home Manager Trampolines app |
| Telegram | `~/Applications/Home Manager Apps/Telegram.app` | Nix telegram-desktop 6.8.1; Spotlight instead finds corresponding Home Manager Trampolines app |
| Obsidian | `~/Applications/Home Manager Apps/Obsidian.app` | Nix obsidian 1.12.7; Spotlight returns no match even outside sandbox |
| Claude | `/Applications/Claude.app` | Homebrew installed record `claude`; Spotlight finds this bundle |
| Steam | `/Applications/Steam.app` | Homebrew installed record `steam`; Spotlight finds this bundle |
| Tor Browser | `/Applications/Tor Browser.app` | Homebrew installed record `tor-browser`; Spotlight finds this bundle |
| Monero Wallet | `/Applications/monero-wallet-gui.app` | Homebrew installed record `monero-wallet`; Spotlight finds this bundle |

The three trampolines are fdm-owned applets dated June 30, 2025, sharing bundle identifiers with the linked Nix apps. Their actual launch destinations remain to be inspected; presence does not prove obsolete ownership or justify removal. The four Nix app links and matching user-profile links resolve to the same existing store bundles. The user's accepted workflow is successful startup, to be tested during US-04, not this discovery. Obsidian's Spotlight absence is a recorded baseline issue; no indexing/registration changes were made.

VPS observations at 09:03:51 UTC:

- Active and selected system paths still equal the recorded generation-21 closure. [verified: both `realpath` commands, exit 0]
- Zero failed-unit rows. [verified: `systemctl --failed --no-legend --plain`, exit 0]
- Postfix, Dovecot, Rspamd, nginx, sshd and redis-rspamd each report active. A query also included systemd-resolved, which reports inactive; the actual resolver is `kresd@1.service`, discovered running via `systemctl list-units --state=running --type=service --no-legend --plain`. Combined `is-active` exit 0 does not prove every listed service active. Use kresd@1 for subsequent V checks.
- `ss -lnt` shows wildcard IPv4/IPv6 TCP listeners 22, 25, 80, 443, 465, 993, 12340; DNS TCP 53 is loopback-only on IPv4/IPv6. Privileged PID mapping and both firewall queries each report `sudo: a password is required`; user output needed.
- `df -k / /nix`: root has 24593744 KiB total, 13574048 used, 9745072 available, 59% used. This is not US-03 build-capacity approval.
- `lsblk -o NAME,TYPE,FSTYPE,UUID,MOUNTPOINTS` confirms root ext4 UUID `70cbc760-a105-4f62-81a1-8ba58f5982fa` and swap UUID `148323ff-b2d9-4c11-aa06-d46d0684ce5a`, matching `hardware/vultr-vps.nix` exactly.
- `/sys/firmware/efi` absent; `/boot/grub` inspection denied to unprivileged user. Repository explicitly enables GRUB with device `nodev`; no deployed bootloader equivalence claim is made until privileged metadata is reviewed. No hardware, network or boot settings changed.

Layer 3 remains incomplete pending listener ownership, host/provider firewall reconciliation, privileged boot metadata and remaining app resolution clarification. Layers 4–6 have not started.

### Layer 3 privileged network/boot evidence (2026-09-26)

User supplied `sudo ss -lntp`, `sudo iptables -S`, `sudo ip6tables -S` and `sudo stat /boot/grub /boot/grub/grub.cfg`. No exit codes or collection timestamps accompanied the transcript.

| TCP listener | IPv4/IPv6 owner | Host firewall disposition for new external connections |
| --- | --- | --- |
| 22 | sshd, PID 864 | Allowed |
| 25 / 465 | Postfix master, PID 1433 | Allowed |
| 80 | nginx, PIDs 912 / 227884 | Allowed |
| 443 | nginx, PIDs 912 / 227884 | Dropped |
| 993 | Dovecot PID 1005 / imap-login PID 869303 | Allowed |
| 12340 | Dovecot PID 1005 | Dropped |
| 53 | kresd PID 1114, loopback only | Loopback allowed; no external TCP exception |

Both INPUT chains jump to `nixos-fw`, which permits loopback and RELATED/ESTABLISHED traffic, then TCP 22, 25, 80, 465 and 993, then logs/refuses other traffic through DROP. The top-level INPUT ACCEPT policy therefore does not imply unrestricted inbound access. IPv4 additionally permits echo requests. IPv6 drops ICMP types 137/139, permits other IPv6 ICMP and UDP destination 546 for `fe80::/64`. FORWARD/OUTPUT policies are ACCEPT in the supplied filter rules. Provider rules are still unknown; no firewall or listener changes are proposed.

`/boot/grub`: root:root, mode 0700, directory, modified `2025-11-29 14:26:24.017966114 +0100`. `/boot/grub/grub.cfg`: root:root, mode 0644, 13676 bytes, modified `2025-11-29 14:26:24.016966141 +0100`. Both on device 253,1. GRUB metadata and non-EFI boot observations are consistent with GRUB use, but do not prove the repository's `boot.loader.grub.device = "nodev"` reproduces the installed bootloader. Bootloader alterations remain blocked pending exact deployment equivalence/recovery evidence; none are part of US-01.

Agent follow-up identified purposes without full configuration dumps:

- An awk filter retaining only the enclosing service/listener names and the matching port from `/etc/dovecot/dovecot.conf` identifies TCP 12340 as `service quota-status`, `inet_listener`. It is not an extra public mail endpoint.
- `/etc/nginx/nginx.conf` is absent. Store-path extraction from `/etc/systemd/system/nginx.service` identifies `/nix/store/2xkky84z6rvisa3gjyyf616ca29ikcxm-nginx.conf`. Selected `listen`, `server_name` and `root` directives show HTTP 80 and TLS 443 virtual hosts for `mail.maurerf.com`, with `/var/lib/acme/acme-challenge` roots. This identifies a mail-host web/TLS listener with ACME challenge handling; it does not establish a requirement for public port 443. Keep 443 blocked.
- `systemctl is-active kresd@1` returned `active`, exit 0, resolving the earlier wrong resolver-name probe.

Layer 3 still awaits provider firewall reconciliation and app trampoline resolution; no Layer 4 console/backup actions have started.

### Provider rules and app launcher resolution (2026-09-26)

User reports **no Vultr firewall groups**. No provider firewall group is attached according to that report; the host rules above are the observed inbound filtering baseline. This is user-supplied provider evidence, not an independently queried API result.

`osadecompile` on the `Contents/Resources/Scripts/main.scpt` files inside the three Spotlight-discovered Home Manager Trampolines apps exited 0. Scripts were inspected, never executed. Their fixed launch destinations are:

| App | Spotlight trampoline target | Current linked Nix app |
| --- | --- | --- |
| VS Code | `/nix/store/2zqm0d9d6hqjma6l3pph3c47xfj3lcab-vscode-1.101.1/Applications/Visual Studio Code.app/` | vscode 1.119.0 |
| KeePassXC | `/nix/store/hs1mxz7fkvy7zy65bbzsf4ba5mqx7fbk-keepassxc-2.7.10/Applications/KeePassXC.app/` | keepassxc 2.7.12 |
| Telegram | `/nix/store/bai85905znflsz2a1sa3gqp6qa2012ah-telegram-desktop-5.15.4/Applications/Telegram.app/` | telegram-desktop 6.8.1 |

All three old target bundles exist. [verified: Python `Path.exists()` on each exact target, all true]. This is pre-existing application resolution drift, not a version change caused by US-01. Retain both routes here; record correction of launcher resolution and Obsidian discovery as follow-ups for source/deployment work. Future launch checks must distinguish Spotlight from the current Home Manager Apps path rather than assuming they start the same version.

Independent SSH checks: `ssh -4 -o BatchMode=yes -o ConnectTimeout=10 -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519_maurerf maurerf.com true` exited 0. The same command with `-6` exited 255: `ssh: Could not resolve hostname maurerf.com: nodename nor servname provided, or not known`. Both ran outside the sandbox. This proves IPv4 access only; it does not prove whether the VPS has a working IPv6 address. Layer 3 fails its IPv6 access check pending an authorized IPv6 target/client verification. No DNS, network, SSH or firewall setting was changed. Layers 4–6 remain unstarted.

### Direct IPv6 access check (2026-09-26)

User supplied and authorized VPS IPv6 address `2001:19f0:6c01:074c:5400:03ff:fee7:62c3`. The direct test retained strict host-key checking against the existing `maurerf.com` trust entry:

```sh
ssh -6 -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=yes -o HostKeyAlias=maurerf.com -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519_maurerf fdm@2001:19f0:6c01:074c:5400:03ff:fee7:62c3 true
```

Exit 255 after approximately 10 seconds: `ssh: connect to host 2001:19f0:6c01:74c:5400:3ff:fee7:62c3 port 22: Operation timed out`. No authentication or host-key verification was reached. This is distinct from the alias's IPv6 resolution failure.

`route -n get -inet6 2001:19f0:6c01:074c:5400:03ff:fee7:62c3` initially failed inside the sandbox with `route: socket: Operation not permitted`; the authorized retry exited 0 and showed the IPv6 default route via `fe80::1%en0`, interface en0, MTU 1500. A configured route does not prove end-to-end IPv6 connectivity. The failure's location (Mac/upstream/VPS) remains unknown. Layer 3 remains blocked; no network or SSH changes were attempted. Request VPS address/route metadata through the working IPv4 session before any proposed remediation.

### VPS IPv6 route evidence (2026-09-26)

User supplied `ip -6 route show` through the working VPS session:

```text
2001:19f0:6c01:74c::/64 dev enp1s0 proto ra metric 100 pref medium
fe80::/64 dev enp1s0 proto kernel metric 1024 pref medium
default via fe80::fc00:3ff:fee7:62c3 dev enp1s0 proto ra metric 100 pref medium
```

[verified: user-supplied `ip -6 route show`]. An on-link global prefix and RA-learned default route exist. This rules out an absent default route in this output, but does not establish gateway reachability or end-to-end connectivity. Both direct inbound SSH timeouts remain unresolved; the provider-reported address remains absent from the supplied interface addresses. Layer 3 remains blocked. No route, address, firewall or SSH configuration changed. Proposed next diagnostic, subject to the user's access-risk stop decision: read-only IPv6 connectivity checks from Mac and VPS to distinguish client-side connectivity from the VPS path.

### Authorized IPv6 connectivity diagnostics (2026-09-26)

User explicitly authorized read-only connectivity checks from both hosts. VPS commands ran through the working IPv4 SSH alias with BatchMode and the approved key; local network commands ran outside the sandbox.

- VPS `ip -6 route get 2606:4700:4700::1111`: default gateway `fe80::fc00:3ff:fee7:62c3`, enp1s0, temporary source `2001:19f0:6c01:74c:9778:788d:c9ce:ac19`.
- VPS `ping -6 -n -c 3 -W 2 fe80::fc00:3ff:fee7:62c3%enp1s0`: 3/3 replies, 0% loss. The same probe to `2606:4700:4700::1111`: 3/3 replies, 0% loss.
- VPS `curl -6 -I --connect-timeout 8 --max-time 12 https://www.cloudflare.com`: exit 0, HTTP 403 challenge. This demonstrates HTTPS transport, not application acceptance; response cookies are not retained here.
- Mac same HTTPS command: exit 28, `Failed to connect to www.cloudflare.com port 443 after 8006 ms: Timeout was reached`.
- Mac `curl --noproxy '*' -6 -sS -o /dev/null -w 'remote_ip=%{remote_ip} http_code=%{http_code}\n' --connect-timeout 8 --max-time 12 'https://[2606:4700:4700::1111]/'`: exit 28, `Failed to connect to 2606:4700:4700::1111 port 443 after 8006 ms: Timeout was reached`; remote_ip empty, http_code=000.
- VPS same direct curl command with `--interface 2001:19f0:6c01:74c:1c50:f5d0:dd3f:a62`: exit 0, remote_ip=2606:4700:4700::1111, http_code=301.

[verified: commands listed above]. VPS outbound IPv6 works, including from its non-temporary address. The Mac fails both the VPS SSH probes and an unrelated direct IPv6 HTTPS endpoint. This suggests a Mac/local-network/upstream IPv6 connectivity issue; it does not establish the exact fault or prove inbound VPS SSH works. Layer 3 remains blocked pending SSH from an independently working IPv6-capable client. No configuration or live network changes were made. Keep working IPv4 access; no VPS network repair is justified by these results.

### User-approved IPv6 deferral and current gate (2026-09-26)

User explicitly requested postponing further IPv6 investigation and retaining it as an open point. Layer 3 is accepted for continuation of read-only US-01 with this exception; IPv6 SSH has NOT passed. Earlier checkpoint statements describing Layer 3 as blocked are superseded by this decision. No additional IPv6 diagnostics or remediation are planned in US-01. Verify inbound IPv6 SSH from a proven IPv6-capable external client before VPS deployment in US-06; resolve client connectivity and the provider-address/interface mismatch as necessary through separately authorized work. Do not change VPS networking on the basis of the present evidence.

Layer 4 now awaits independent Vultr console authentication and completed off-host backup identity, timestamp, coverage, consistency and retention. No system activation or production reboot applies to this discovery story. Remaining layers must still be completed before marking US-01 done; the user's IPv6 exception does not waive the console or backup criteria.

### Layer 4 console and snapshot screenshots (2026-09-26)

User supplied screenshots of the independent Vultr noVNC console and snapshot/backup page. Console login as fdm succeeded; `date -u` returned `Sa 26. Sep 09:20:08 UTC 2026`, `sudo id -u` returned `0`, and `realpath /run/current-system` returned `/nix/store/yhczh27iwxqsbikj51c4lkb4gpwzzmwh-nixos-system-nixos-vps-26.05.20251129.59b6c96`, matching the recorded baseline. [verified: user-supplied console screenshot of these commands]. Independent privileged console access passes; no reboot or boot-menu rehearsal was performed.

Provider snapshot page observations [verified: user-supplied Vultr screenshot]:

| Snapshot | Identifier | Displayed time (timezone not shown) | Size | Status |
| --- | --- | --- | --- | --- |
| pre-coding-agent | 9832d1f4-0ee1-4e78-9046-54c8049f4c39 | 26-09-2026 10:31:09 | 25GB | Available |
| pre-dovecot-upgrade | 46fcf516-9c65-46ff-97ec-0c3ebaf73d36 | 28-11-2025 00:18:29 | 25GB | Available |

Backup history also shows entries dated 22-09-2026 11:02:05 and 15-09-2026 11:02:06. Their presence does not establish the retention policy. The screenshot's OS icon is not proof of the installed OS or restored contents.

The current snapshot's completed availability, identifier and displayed timestamp are established. Snapshot coverage of the VPS boot disk (including the inventoried state and persistent credential source), capture consistency (running/quiesced/powered off), timezone and retention still need confirmation. All inventoried persistent paths were observed on the root disk, but a size label alone does not prove snapshot coverage. `/run/dovecot2/passwd` is generated runtime state; recovery depends on the persistent source already identified. Layer 4 remains incomplete; Layers 5–6 have not started. No restoration or system activation was performed.

The preceding initial screenshot assessment is superseded by the user's explicit confirmations immediately below; the current snapshot facts are now recorded with those confirmations and the decision to defer only consistency testing.

### Layer 5 firewall confirmation and Layer 6 rollback record (2026-09-26)

User supplied the requested privileged `sudo iptables -S` and `sudo ip6tables -S` outputs. They exactly match the earlier rules recorded under “Layer 3 privileged network/boot evidence.” Inbound host rules permit TCP 22, 25, 80, 465, and 993; unsolicited external 443 and 12340 are refused/dropped. IPv6 SSH access from this Mac remains deferred. [verified: user-supplied IPv4/IPv6 firewall outputs compared with prior evidence]. No firewall changes occurred.

Layer 6 records the rollback parameters; no recovery command was run and no live state changed:

- Mac baseline generation **34**, closure `/nix/store/5vylcskg3kzqc55b9nb71x9hxkhnnx63-darwin-system-26.05.56c666e`; retained closure requisites were checked (411, exact match), and `/run/current-system/sw/bin/darwin-rebuild` is executable. The runbook's exact command is `sudo darwin-rebuild --switch-generation 34`. If needed from the old system closure, `sudo /nix/store/5vylcskg3kzqc55b9nb71x9hxkhnnx63-darwin-system-26.05.56c666e/sw/bin/darwin-rebuild --switch-generation 34`.
- VPS baseline generation **21**, closure `/nix/store/yhczh27iwxqsbikj51c4lkb4gpwzzmwh-nixos-system-nixos-vps-26.05.20251129.59b6c96`; recursive store verification passed earlier, and `/run/current-system/bin/switch-to-configuration` is executable. For a prior `test`, exact command: `sudo /nix/store/yhczh27iwxqsbikj51c4lkb4gpwzzmwh-nixos-system-nixos-vps-26.05.20251129.59b6c96/bin/switch-to-configuration test`. After a prior `switch`, select the retained old profile generation with `sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation 21`, then activate via `sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch`. For boot failure use the verified Vultr console and recorded old boot entry; no production reboot was performed to test it. These commands are configuration rollback only and are unsafe if new mail software has written incompatible state; use the US-05 isolated restore/reconciliation procedure in that case.

Mac app baseline paths/owners and the user's named checklist are recorded earlier. Launch workflows were deliberately not run under US-01's read-only discovery layer; launch confirmation belongs to US-04. Installer/configuration provenance remains explicitly unknown where historical evidence is unavailable. Old Home Manager generation 20, legacy NixOS source files/channel, and existing manual Homebrew apps were retained; cleanup/removal remains out of scope.

### US-01 completion and retained exceptions (2026-09-26)

All US-01 read-only discovery layers are complete. Explicit user-approved exceptions: full Homebrew cask inventory is unavailable because Chromium's definition errors; IPv6 SSH is deferred and must pass from a proven IPv6-capable external client before VPS deployment; the live Vultr snapshot's application-state consistency is unverified and must be tested by the isolated restore in US-05 before deployment. None of these facts is represented as a passing technical check. The independent console, snapshot identity/time/full-disk coverage/long-term retention are established. Launching the named apps is assigned to US-04; US-01 captured paths and ownership without starting apps.

No configuration, package, network, firewall, channel, secret, bootloader, or active generation changed. No builds, app launches, activation, reboot, restore, generation switch, garbage collection, or push occurred. Exact output for the residual privileged firewall recheck is supplied by the user above. [verified: evidence in this US-01 section and all preceding baseline tables; `git diff --check`].

### Snapshot coverage, retention and consistency decision (2026-09-26)

User confirmed `pre-coding-agent` was taken while the VPS was running, covers everything on this VPS, and will be retained for a long time. The provider displays CEST: the recorded snapshot time is therefore `2026-09-26 10:31:09 +02:00`, or `2026-09-26 08:31:09 UTC`. Coverage of the entire boot disk is operator-confirmed; all inventoried persistent mail paths and the credential source are on that disk. Retention is operator-managed long-term retention with no precise deletion date supplied. [verified: user confirmation accompanying the available snapshot screenshot].

No service quiescence or clean shutdown was reported. [Vultr's automatic backup guidance](https://docs.vultr.com/vps-automatic-backups) compares recovery of a running-server snapshot to a non-graceful restart and notes that additional measures may be required for consistent write-intensive data. This supports recording live capture as a consistency limitation, not proof of application-consistent mailbox, queue or Redis recovery. Snapshot contents have not been restored or checked. Independent console access, available backup identity/time, operator-confirmed coverage and retention are established; application-state consistency remains unverified. US-05 owns the isolated restore rehearsal. Advancing past Layer 4 with this gap requires an explicit user exception; do not mark the consistency criterion passed or authorize deployment from these observations.

### Layer 4 exception accepted and Layer 5 final checks (2026-09-26)

User explicitly approved deferring snapshot application-state consistency verification to US-05's isolated restore test, retaining it as a deployment blocker. Layer 4 accepted with that exception; consistency is not claimed verified. This supersedes the earlier Layer 4 stop. No activation occurred.

Final read-only checks at approximately 09:25 UTC:

- Both hosts' `realpath /run/current-system` and `realpath /nix/var/nix/profiles/system` match their recorded baseline closures. VPS selected profile remains `system-21-link`. VPS configuration revision remains unknown.
- VPS `systemctl --failed --no-legend --plain`: no rows, exit 0. `systemctl is-active postfix dovecot rspamd nginx sshd redis-rspamd kresd@1`: seven active results, exit 0. `ss -lnt`: same recorded IPv4/IPv6 listeners. `df -k / /nix`: 24593744 KiB total, 13574080 used, 9745040 available (59% used). Capacity approval remains US-03's responsibility.
- VPS `nix-env -q`: home-manager-path; login `nix-channel --list`: empty. No package mutation occurred.
- Mac `nix-env -q`: home-manager-path; `nix profile list`: unchanged `/nix/store/9a5dmxglkahgxnci1922pifwvmvgzq8v-home-manager-path`; login channels empty. All commands exit 0.
- `HOMEBREW_NO_AUTO_UPDATE=1 brew list --formula --versions`: 139 entries, exact ordered match to the earlier US-01 inventory, exit 0. Initial comparison incorrectly excluded a non-numeric version and reported 138 baseline entries; corrected extraction of the complete recorded block proves 139 versus 139, no additions/removals. This was a comparison-script issue, not package drift.
- Full cask command repeats the accepted Chromium definition error, exit 1. The individual nine-cask command recorded above exits 0 and all nine version lines match the baseline. Chromium remains an explicitly unverified inventory exception.
- Mac `nix-store --query --requisites /run/current-system`: exit 0, 411 paths, every path present in the earlier baseline. No builds, launches or source materialization occurred.
- Mac `test -x /run/current-system/sw/bin/darwin-rebuild` equivalent executable check succeeds; VPS `test -x /run/current-system/bin/switch-to-configuration` exits 0. These checks do not execute recovery.

[verified: final commands above, plus Python exact line comparison against the recorded inventory]. Final VPS `sudo -n iptables -S` and `sudo -n ip6tables -S` each exit 1 with `sudo: a password is required`. Earlier user-supplied rules remain recorded, but the repeated V check awaits fresh user output. Layer 5 is pending that privileged check; Layer 6 has not started. No further IPv6 verification is requested under the approved deferral.

### Resume checkpoint and configured IPv6 result (2026-09-26)

User provided two copies of `ip -6 addr show scope global`; no route output yet. Interface enp1s0 is UP/LOWER_UP. The provider-reported address ending `5400:3ff:fee7:62c3` is absent. The non-temporary global address is `2001:19f0:6c01:74c:1c50:f5d0:dd3f:a62/64`, with mngtmpaddr/noprefixroute and infinite preferred/valid lifetimes. Several temporary addresses are present, including one preferred and six deprecated in the supplied output. This does not establish why inbound IPv6 fails.

A direct SSH attempt to `fdm@2001:19f0:6c01:74c:1c50:f5d0:dd3f:a62` using `-6 -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=yes -o HostKeyAlias=maurerf.com -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519_maurerf` and remote `true` also exited 255 after about 10 seconds: `Operation timed out`. No authentication was reached. No network remediation attempted; further action requires the user's decision under the access-related stop condition. Next missing diagnostic is `ip -6 route show` from the existing working IPv4 session; an independent IPv6-capable client test may be needed to distinguish client/provider/server causes.

Resume state:

- Branch `checkup/US-01`, baseline commit `80656bee2ba0ea7a31da9912e9952213248eb446`. Only EVIDENCE.md and US-01's own stories.md entry modified; no commits yet. These are this task's edits, not unrelated dirt. No push permitted.
- PRD and US-01 remain the source of truth. Scope is read-only discovery plus these documentation files. User separately performed SSH key setup; agent has never activated, built, changed network/SSH settings or copied credential values. The roots query's unexpected stale-link cleanup is recorded above and must not be repeated.
- Layer 1 accepted with explicit user-approved Chromium cask-inventory exception; old HM generation retained. Layer 2 not applicable. Layer 3 blocked by IPv6 access. All app resolution, host/provider firewall (no Vultr group), filesystem UUID and listener evidence is above. GRUB installed-device equivalence remains unproven, explicitly blocking boot changes.
- After resolving/explicitly dispositioning Layer 3: stop at Layer 4 for the user's independent Vultr console login and completed snapshot identity/time/coverage/consistency/retention evidence. No production activation or reboot belongs to US-01. Layer 5 repeats permitted baselines and confirms active/selected paths; Layer 6 records exact old-generation rollback parameters without executing recovery.
- Backup and console evidence has not been supplied. Do not mark done until criteria have evidence. Finalize US-01 status/date/evidence/commit reference, commit locally with `[US-01]` prefix, and leave clean status only upon completion. No source edits, stateVersion changes, input updates, GC, channel deletion or app removal.
- Essential apps: VS Code, KeePassXC, Telegram, Obsidian, Claude, Steam, Tor Browser, Monero Wallet; user accepts successful startup, but US-01 forbids launching. User approved retaining linkApps and AGENTS.md. App removals, stale Spotlight trampolines, Obsidian discovery, and secret migration are later-story follow-ups.
