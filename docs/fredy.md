# Fredy on the VPS

[Knowledge index](README.md) · [Hosting plan](fredy-hosting-plan.md) ·
[Deployment](deployment.md) · [Recovery](vps-recovery.md)

The NixOS outputs `vps-fredy-bootstrap` and `vps` are two stages of the same
reviewed source. The bootstrap output's nginx locations deny external requests
while the upstream `admin` / `admin` account exists. Activate the public `vps`
output only after changing the password through an SSH tunnel and verifying the
bootstrap gate. Both stages start the same pinned container and mount the same
state. Any `nixos-rebuild test` activates services and requires the production
[approval and recovery preparation](deployment.md#deployment). Both stages were
activated in sequence on 2026-09-30 from source revision
`68c6cc671415117d7b06569ff125da6dbfaca7b2`. At the post-switch check,
the public `vps` closure
`/nix/store/85lhgp48pks17dl5fhi85755pywsnkzr-nixos-system-nixos-vps-26.05.20260925.f5c082a`
was active and selected; the booted closure was the retained pre-Fredy
generation. After the 2026-10-03 VPS plan change and filesystem expansion,
the same public `vps` closure was active, selected and booted. Compare live
paths again before future changes.

## Deployed 25.2.0 baseline and measured budget

The original deployment uses Fredy [25.2.0](https://github.com/orangecoding/fredy/releases/tag/25.2.0),
`ghcr.io/orangecoding/fredy@sha256:74e075c34a38223faaef7705c4f7de637d1dafc683bd61dfa46bb391980c665b`.
On 2026-09-29, the registry index resolved to Linux amd64 manifest
`sha256:cbbac45ade2428c36e6abedeccae25635c0b3a37fcfd597c46fa6f088dde8d5d`;
its 18 layers total 695,655,747 compressed bytes. The index, amd64 manifest,
config and all 18 blobs were streamed and checksum-verified on 2026-09-29
outside the VPS. This confirms registry retrieval, not a successful Podman
startup. The tagged source
[Dockerfile](https://github.com/orangecoding/fredy/blob/25.2.0/Dockerfile)
runs as root, exposes port 9998, and mounts `/conf` and `/db`. The tagged
[entrypoint](https://github.com/orangecoding/fredy/blob/25.2.0/index.js)
creates a missing `/conf/config.json` with `/db` as its SQLite directory before
database startup. Keep `/var/lib/fredy/conf` and `/var/lib/fredy/db` together;
both are root owned with mode 0700 on the host. Password hashes, session keys,
Telegram tokens, jobs and listings live in the database. Treat copies as secrets.

During the 2026-09-30 bootstrap `test`, Podman 5.8.7 reported no health check
on either the pulled OCI image or the running container, although the registry
config contains one. The revised candidate supplies the HTTP health command
explicitly at container creation. Verify Podman reports `healthy` before
accepting the revised bootstrap stage; a healthy UI still does not prove a
provider search works.

Read-only VPS observations at 2026-09-29 21:30 UTC: 964 MiB RAM, 601 MiB
reported available, 174 MiB of 1 GiB swap used, 6.9 GiB free and 750,215
inodes free on the root filesystem, and a 2.3 GiB journal. Memory pressure
averages were zero; the seven named mail/access services were active and no
units failed. Port 9998 and public 443 were not listening. These are a dated
baseline, not a Fredy load measurement. Recheck before deployment.

The original trial capped the whole Fredy container, including browser
children, at 448 MiB memory plus at most 128 MiB swap
(`--memory-swap=576m`), half of the single CPU and 128 PIDs. On the original
1 GiB VPS this left a nominal
516 MiB of physical RAM for mail and the host; Rspamd's observed unit peak
was about 208 MiB. Its peak could coincide with Fredy's peak, so this budget
may still cause host swap or Fredy browser failures. Three failures within
ten minutes stop systemd retries.
Container application logs use Podman's 10 MiB capped file driver under
`/var/log/fredy/container.log`, readable with `sudo podman logs fredy` while
the container is running; systemd unit logs remain in the journal with a unit
rate limit. This protects existing mail journal retention from Fredy noise.
Neither the UI health check nor these limits proves that a browser based
provider works within the budget. Do not raise limits automatically.

At the 2026-09-30 post-switch check, Fredy, nginx and the named mail/access
units were active with no failed units. The host reported 616 MiB available
RAM, 237 MiB swap used and 4.1 GiB free disk. HTTPS returned the UI with a
valid certificate, unauthenticated `/api/jobs/events` returned 401, and port
9998 listened only on loopback. The operator confirmed HTTPS login on a
computer and phone, a search that returned listings, and working inbound and
authenticated outbound mail. Direct inspection of the authenticated event
stream remains pending. These are initial trial observations, not a sustained
load measurement.

At a later 2026-09-30 trial sample after a search run, the operator confirmed
actual listing notifications arrived in the private Telegram group. A read-only
VPS check found Fredy active with zero systemd restarts, nginx and mail services
active, no failed units, 584 MiB available RAM, 312 MiB swap used and 4.1 GiB
free disk. This single sample does not establish sustained resource safety;
continue the trial observations below. The authenticated event stream has not
yet been inspected directly.

The image and Podman state consume the same root disk as mail and Nix. Check
free bytes/inodes before pulling the image or building on the VPS, and keep
at least 3 GiB free after preparation. Prefer an independent Linux builder;
do not run a heavy build on the mail host to satisfy a build check.

## Search failure observed on 2026-10-03

The operator reported that Telegram listing notifications stopped after roughly
one day and jobs returned zero listings. The locally supplied
`2026-10-03-FredyDebug-25.2.0.zip` contains 174 browser startup errors between
2026-10-01 12:46:10 and 2026-10-03 19:56:45 (timestamps as written in the log).
Every error reports that Chromium could not spawn `chrome_crashpad_handler`:
`Resource temporarily unavailable (11)`. Keep the raw archive out of Git.

A read-only SSH inspection on 2026-10-03 at 20:41:50 UTC confirmed PID exhaustion:
the container had 115 zombie Chromium processes parented to Node, which was PID 1
inside the container. Its 11 threads plus those zombies accounted for
`pids.current=126`, with `pids.max=128` and `pids.events max=362`.
The service remained active with zero systemd restarts. This explains how its UI
could remain available while browser searches failed. Telegram delivery itself
was not tested during this inspection.

The container also had recorded memory/swap pressure: `memory.events max=600`,
zero OOM/OOM-kill events, and `memory.swap.events max=19040 fail=19040`.
The root filesystem had 3,215,826,944 bytes available, slightly below the 3 GiB
preparation floor. All seven named mail/access services were active and no units
were failed; these status checks do not establish end-to-end mail delivery.

The [recovery and upgrade handoff](fredy-upgrade-plan.md) records the remaining
measurements and implementation steps. Fredy 29.2.1's tagged Dockerfile includes
`tini` specifically to reap orphaned Chromium children; verify the published
image and sustained behavior before accepting the repair. This inspection did
not restart, upgrade or otherwise modify the running service.

## Prepared 29.2.1 repair and upgrade

The proposed Nix configuration pins Fredy
[29.2.1](https://github.com/orangecoding/fredy/releases/tag/29.2.1) to the GHCR
index digest
`sha256:45fc1d36f8c79151f66c981c1aacde0f9d19409ffac0d9d084dcd2acecc9ea18`.
On 2026-10-03, the release API identified it as the latest stable release,
from source commit `9f6551ee74249924c57e671a36658e890c52d9f2`.
The published Linux amd64 manifest is
`sha256:1be69e57027924abba16a0d06f37697ae883322002e0fd2d2325f8ef459612cc`;
its config has `/usr/bin/tini -g --` as entrypoint and `node index.js` as command.
This makes `tini` PID 1 to reap orphaned Chromium children. The image still
exposes 9998 and declares `/conf` and `/db`. Nix preserves the loopback binding,
HTTPS proxy, state mounts, explicit Podman health command, memory and CPU limits,
and log cap. The revised candidate raises only the PID cap from 128 to 256;
verify the actual image, PID tree and health after approved activation.

The tagged [migration runner](https://github.com/orangecoding/fredy/blob/29.2.1/lib/services/storage/migrations/migrate.js)
runs unapplied migrations in order at startup, each in a transaction, and aborts
startup if one fails. The direct 25.2.0 upgrade applies migrations 32–47.
[Migration 32](https://github.com/orangecoding/fredy/blob/29.2.1/lib/services/storage/migrations/sql/32.configured-adapters.js)
converts each job's inline notification adapters into owner-private channels,
deduplicated per owner and configuration, and rewrites the job to reference them.
Check existing jobs, channel ownership, Telegram fields and job links after
upgrade. Migration 34 pins existing working hours to the container's current
timezone; check the resulting hours. Later migrations add listing columns,
indexes, settings and tables, including attachments stored in SQLite; migration
41 backfills price per square metre and migration 45 requeues unanswered
connectivity checks. Startup also initializes connectivity work. Inspect
resource use and disk growth during acceptance. A 25.2.0 binary must not be
run against migrated state without establishing compatibility; recovery may
require the matching pre-upgrade copy of both `/conf` and `/db`.

The 2026-10-03 21:02 UTC read-only VPS check found 3,201,622,016 free bytes and
648,878 free inodes, about 20 MiB below the 3 GiB preparation floor on the
old 25 GB root filesystem. The operator upgraded the Vultr plan, took a fresh
snapshot, then expanded the ext4 root partition from a SystemRescue ISO and
recreated the 1 GiB swap partition with its original UUID. At the 2026-10-03
22:40 UTC post-reboot check, `/dev/vda` was 55 GiB, root was 54 GiB with
33,699,082,240 bytes and 2,636,568 inodes available, and swap was active.
The VPS had 2 GiB RAM and the expected active, selected and booted closure.
Fredy 25.2.0 returned HTTP 200 and Podman subsequently reported `healthy`;
all required services were active with no failed units and the mail queue was
empty. The operator confirmed primary and alias inbound delivery plus
authenticated outbound receipt around 2026-10-04 00:44 CEST. The snapshot has
not been restore-tested. Recheck free space and recovery readiness before the
Fredy activation.

The new image has 694,075,620 compressed bytes across 19 layers; unpacked
layers, writable layer, backup, Nix closure and mail growth need additional
space. Preserve the old image and recovery generations. Do not delete mail,
logs, images or retained generations as an incidental capacity measure.

During the approved 2026-10-04 `test` of the first 29.2.1 candidate, one
browser search reached 124 of 128 allowed PIDs, then fell to 12 after
Chromium exited. No Chromium zombies or PID-limit events were observed; `tini`
was PID 1. The small four-PID margin could reject overlapping browser work,
so the revised candidate allows 256 PIDs. The 448 MiB memory cap, total
memory-plus-swap setting and CPU limit stay unchanged.
The container was near its memory cap, but most charged memory was reclaimable
file cache and no OOM kill occurred. Continue monitoring memory pressure and
mail rather than raising that cap on this sample alone.

The existing account has already passed first login. For this upgrade, use only
the public `#vps` activation route; build the bootstrap output because it shares
the module, but do not reactivate bootstrap or reset credentials. After an
approved Fredy stop, make and verify a protected, consistent archive of both
state directories, including SQLite WAL/SHM, before the first new-image start.
`nixos-rebuild test` will recreate the container and run the migrations. Accept
login, saved jobs and schedule, channel links, a representative provider search,
and an authorized Telegram delivery check before `switch`. Track the payload
cgroup's PID count, `pids.events max`, memory and swap events through normal
searches, and verify HTTPS plus mail using [VPS acceptance](deployment.md#vps-acceptance).
Observe for at least 24 hours, preferably 48, because the original failure
developed after roughly a day. See the [recovery guide](vps-recovery.md#fredy-backup-and-recovery)
before any state restore.

## DNS and HTTPS preparation

On 2026-09-29, `ns3.epik.com` and `ns4.epik.com` were authoritative for
`maurerf.com`, and the live VPS interface and `mail.maurerf.com` A record both
used `108.61.190.159`. Authoritative DNS returned the same address for
`fredy.maurerf.com` **and** a random subdomain, indicating a wildcard A record;
it does not establish whether a dedicated `fredy` record exists. The current
CAA set permits Let's Encrypt. Recheck the interface IP, nameservers, CAA and
existing Fredy A/CNAME/AAAA records before editing DNS.

On 2026-09-30, the operator added a dedicated `fredy` A record in Epik with
`108.61.190.159` and TTL 300. Both Epik nameservers and a public resolver
returned that address; mail A and MX answers matched the earlier baseline.
The steps below apply if the record must be recreated later.

In Epik, open **My Account → My Domains → Registrar → maurerf.com → DNS & WHOIS
→ SET DNS HOST RECORD → A RECORDS**. The exact labels are based on a
[recent Epik UI guide](https://www.datahash.com/docs/signals/reference/subdomain/epik/);
use the equivalent host-record editor if they differ. If there is no explicit
Fredy record, add only this record and save the individual change:

| Field | Value |
| --- | --- |
| Type | `A` |
| Host/name | `fredy` (or the full name if Epik requires it) |
| Address | `108.61.190.159`, after rechecking it against the VPS |
| TTL | 300 seconds, if offered; otherwise the default |

Do not replace the zone or change nameservers, MX, mail A/AAAA or TXT records.
Epik's [bulk host-record API](https://registrar.epik.com/docs/epik-API.pdf)
replaces the whole set; do not use it for this addition. Do not add a Fredy AAAA
record until IPv6 HTTPS has been checked end to end. After saving, query both
authoritative servers and a public resolver for Fredy A, verify mail DNS still
matches the baseline, and confirm HTTP-01 on port 80. The bootstrap nginx host
can obtain its certificate while its application locations deny public access.
Before bootstrap acceptance, allow TCP 443 in any applicable Vultr firewall so
the external 403 and TLS checks are meaningful. The NixOS host firewall rule
alone does not change provider policy.

## First login and public switch

1. Complete the [VPS recovery preparation](vps-recovery.md#maintenance-and-preparation),
   mail/access baseline, native Linux builds of both outputs and image pull
   preparation. Record the old generation and closure. Obtain approval for this
   two-stage activation. Keep an existing SSH session, a second session and the
   independent Vultr console available.
2. Activate and accept `#vps-fredy-bootstrap` using the pinned candidate and
   the repository's `test` then `switch` sequence. Verify `fredy.maurerf.com`
   returns HTTP 403 from an external client, its certificate is valid, and
   public port 9998 is unreachable. Verify the container is healthy, mounts
   `/var/lib/fredy/conf` and `/var/lib/fredy/db`, and its actual cgroup limits
   match Nix. Recheck mail and host pressure after each activation.
3. From the operator's trusted computer, open a private SSH tunnel:
   `ssh -N -L 9998:127.0.0.1:9998 fdm@mail.maurerf.com`. On that computer only,
   browse to `http://127.0.0.1:9998`, sign in with `admin` / `admin`, then use
   **Administration → Users → admin** to replace the password with a unique
   strong shared password. Optionally rename the account there. No signup
   endpoint exists in the selected release; only an admin can create users.
   Close the browser session, sign in through the tunnel with the new password,
   and verify `admin` / `admin` fails. Keep one shared account unless the
   operator later decides otherwise.
4. In **Administration → System**, set Base URL to
   `https://fredy.maurerf.com` and save. This supplies notification links.
   Then restart `podman-fredy.service` while bootstrap remains active and check
   its health, mounts, limits and the external 403 gate. Fredy reads Base URL
   when starting its session plugin, so this restart is required for Secure
   cookies. The HTTP tunnel cannot receive those cookies afterward; perform
   the remaining login check through public HTTPS in step 5.
5. Activate `#vps` from the **same full source commit**, first `test`, then
   mail/Fredy acceptance, then `switch` if successful. Check HTTPS login with
   the new password from both intended devices and confirm old credentials
   fail. Check that a supplied `X-Forwarded-For` cannot spoof the client IP;
   nginx replaces it with `$remote_addr` for Fredy's login rate limiter.
   Check the event stream (`/api/jobs/events`) during a job run. Both outputs
   report the same source revision, so compare the active closure path to the
   expected stage as well. Only now is the Fredy UI public behind its own login.

There is no external registration flow in 25.2.0; the admin API creates users.
The selected release defaults `trustProxy` to true, so the nginx proxy discards
incoming forwarded IP chains and sends the real peer address. The Base URL
setting controls Secure session cookies and links; do not leave it at the
auto-detected HTTP address after opening HTTPS. Review unauthenticated `/api`
routes during acceptance and do not enable demo mode.

## Telegram and trial acceptance

Create a new bot with the official [@BotFather](https://core.telegram.org/bots/tutorial)
using `/newbot`; keep the issued token in private local state. Create a private
group with both users, add the bot with permission to post, and leave privacy
mode enabled. Administrator rights are unnecessary. Send a group command such as
`/start@YourBotUsername` so a privacy-enabled bot receives an update. Follow the
selected release's [Telegram adapter instructions](https://github.com/orangecoding/fredy/blob/25.2.0/lib/notification/adapter/telegram.md)
to read `message.chat.id` from `getUpdates`. The signed group ID may begin
`-100`; preserve the full number. A forum topic also needs its optional
`message_thread_id`. Avoid third-party chat-ID bots and URL strings containing
the token in shell history, browser history, transcripts or logs; use a private
local client that reads the token from a protected file or prompt. Delete any
temporary response files after use. For a prompt-only lookup on a trusted
computer, this prints group IDs without putting the token into a command line
or shell history:

```sh
python3 - <<'PY'
import getpass
import json
import urllib.request

token = getpass.getpass("Telegram bot token: ")
try:
    with urllib.request.urlopen(
        "https://api.telegram.org/bot" + token + "/getUpdates", timeout=15
    ) as response:
        updates = json.load(response).get("result", [])
    for update in updates:
        message = update.get("message", {})
        chat = message.get("chat", {})
        if chat.get("type") in ("group", "supergroup"):
            print(chat.get("id"))
except Exception:
    print("Telegram lookup failed; check the bot and retry privately.")
PY
```

Use the full negative group ID returned as `message.chat.id` by the bot API;
Fredy's positive-number examples are for individual recipients. A Telegram Web
URL is not a substitute for checking what this bot receives. Several updates
from the same group can print the same ID. Do not remove its minus sign.

Fredy sends outbound to Telegram;
no inbound webhook is needed.

In Fredy's UI, add the Telegram notification adapter to the first search with
its token and signed Chat Id. The token is stored in Fredy's database, so backups
and exports need secret handling. In the pinned 25.2.0 release, the
[Try route](https://github.com/orangecoding/fredy/blob/25.2.0/lib/api/routes/notificationAdapterRouter.js)
invokes a sample send, but the
[Telegram adapter](https://github.com/orangecoding/fredy/blob/25.2.0/lib/notification/adapter/telegram.js)
can log a failed message send and still let Try display success. Confirm that
the test message actually appears in the intended group. If it does not,
validate the token and exact signed group ID with a private Bot API `sendMessage`
call before changing Fredy or running another search; `chat not found` means the
bot cannot reach that ID. On a trusted computer, use this prompt-only check;
report only its status, never the token or raw request:

```sh
python3 - <<'PY'
import getpass
import json
import urllib.error
import urllib.request

token = getpass.getpass("Telegram bot token: ")
chat_id_text = getpass.getpass("Group Chat Id (entire negative number): ").strip()
if not chat_id_text.startswith("-") or not chat_id_text[1:].isdigit():
    raise SystemExit("Group Chat Id must be a negative number")
chat_id = int(chat_id_text)
request = urllib.request.Request(
    "https://api.telegram.org/bot" + token + "/sendMessage",
    data=json.dumps({"chat_id": chat_id, "text": "Fredy Telegram delivery check"}).encode(),
    headers={"Content-Type": "application/json"},
)
try:
    with urllib.request.urlopen(request, timeout=15) as response:
        print("Telegram accepted:", json.load(response).get("ok"))
except urllib.error.HTTPError as error:
    try:
        description = json.loads(error.read()).get("description", "")
    except Exception:
        description = ""
    safe_description = description.replace(token, "[redacted]").replace(chat_id_text, "[redacted]")
    print("Telegram HTTP", error.code, safe_description)
except Exception as error:
    print("Request failed:", type(error).__name__)
PY
```

Never paste the token into a browser URL or shell history. Then run a
representative Hamburg rental search and verify a genuinely new listing arrives
in the shared group. Normal soft deletion leaves known listing hashes in place,
so deleting displayed results does not make them new again; do not delete
listings to force a notification test. Start with one provider and conservative
scheduling; leave price tracking off. Observe several cycles, ideally a day,
with mail health, `podman stats`, `podman inspect`, `memory.events`, swap and disk
checks.
Stop Fredy if it OOMs repeatedly, swaps heavily, loops on restart, fills disk,
or affects mail. A working UI alone does not prove provider access from a Vultr
IP. Record blocked portals separately from resource failures and discuss any
reduced provider scope with the operator.

## Retirement

When the search ends, remove the Fredy container declaration and nginx host in
a reviewed, approved VPS change. Review whether TCP 443 is still needed before
closing it. Remove only the dedicated Fredy DNS record, if present, and revoke
the Telegram bot token with BotFather. Decide explicitly whether to retain or
delete `/var/lib/fredy`, its backups and the image; do not remove them as an
incidental effect of disabling the service.
