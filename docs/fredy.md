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
generation. Compare live active and selected closures before future changes.

## 2026-11-14 pagination and Immowelt browser candidate

The repository now builds a local image archive with pagination and browser fixes over
Fredy 29.2.1. [The image recipe](../modules/fredy-pagination/default.nix) pins the
original Linux amd64 manifest, its Nix archive hash and the matching upstream
source commit. The two modified provider files and browser launcher were compared
byte-for-byte with the original image's source layer. No dependencies, database
migrations, settings, filters or notification adapters change. The base
environment and tini entrypoint are retained. Nix loads the archive with
`imageFile`. A tag derived from the Nix output hash and
`pull = "never"` avoid a mutable registry tag or separate publishing step.

The browser launcher adds `--fingerprint-platform=linux` on Linux, matching
[Fredy 30.1.1's Immowelt fix](https://github.com/orangecoding/fredy/releases/tag/30.1.1).
Upstream traced repeated Immowelt HTTP 403 searches to the browser presenting a
Windows identity without matching fonts in its Linux container. This patch
keeps the pinned Fredy 29.2.1 and CloakBrowser 0.5.11 dependencies.

At 2026-11-14 16:45 UTC, a private, bounded diagnostic using the existing VPS
container and this one browser argument confirmed a Linux user agent, a
DataDome cookie, and HTTP 200 from the saved Immowelt search: 222 results,
100 on the first page. The homepage returned HTTP 403, but Fredy's warm-up
continues to the search using that cookie. The result supports the launcher
fix for this request; it does not validate cards, later pages or notifications.

Both providers fetch sequential pages of 100, starting at page 1, with a
three-minute pagination budget per provider: at most five pages for ImmoScout
and one for Immowelt. Immowelt refused the session during its second page in
every run of the two-page candidate on 2026-11-14 and 15 (see
[activation and recovery](#activation-and-recovery)), and each refusal also
suppressed that run's remaining Immowelt requests. One page is the request
volume of unpatched Fredy; with the newest-first order it is the 100 newest
listings, and a larger result is logged as incomplete at the page limit. ImmoScout requests
have a 20-second timeout. Immowelt retains card batches of at most 30, with a
20-second request timeout bounded by the remaining budget. Pages are spaced by
one second and consecutive card batches by half a second. Listing IDs are
deduplicated. A repeated page, premature empty response, timeout, refusal or cap
stops fetching and logs incomplete coverage while retaining successful results.
A 403/429 also suppresses subsequent provider detail requests in that run.
An Immowelt card that the search listed but its card request no longer returns
is counted and logged as a warning; fetching continues. A card batch of more
than one listing that returns nothing is treated as a soft block: it stops
fetching as incomplete and, since the follow-up image of
[issue #94](https://github.com/maurerf/nixos/issues/94), also suppresses that
run's Immowelt detail requests like a 403/429. The image tested on
2026-11-14 instead stopped the provider at the first such card. Immowelt
refusals are logged as `search HTTP` or `cards HTTP` by the failing request;
in that earlier image both read `search HTTP`. The
time budget covers pagination/card fetching, not the entire job's
subsequent enrichment and notification pipeline. A cap is a deliberate limit,
not a promise to retrieve every result for arbitrarily broad searches.

The follow-up image restores two upstream logs that the first patch had
dropped. ImmoScout logs the body of a non-OK search response again, the only
way to tell a rejected (412) search from an empty one. A failed Immowelt search
or card request goes through upstream's `reportFailure` again: a 403/429 logs
the bot warning and its `DETECTED_AS_BOT` tracking event (inert while
[usage reporting](#2026-11-15-provider-urls-and-usage-reporting) is off), any
other status logs the response body, where the portal names an invalid
criterion. Errors without an HTTP status (timeouts, invalid or empty
responses) are not passed to `reportFailure`, unlike upstream; their reason
appears only in the `search incomplete` warning. The image declares no health
check of its own; the service's Podman flags are the only one.

Build-time offline tests exercise the pagination helper and the actual patched
provider functions with mocked HTTP/browser responses. They cover additional
pages, duplicate IDs, request errors, partial, short and empty card batches
(including the one-card boundary), blocking responses and the resulting
detail suppression, the logged bodies of rejected searches, time/page limits
and preservation of search parameters. The tests never open the
live database or send notifications. To build the native VPS candidate:

```sh
nix build .#nixosConfigurations.vps.config.system.build.toplevel --no-update-lock-file --no-write-lock-file
nix build .#nixosConfigurations.vps-fredy-bootstrap.config.system.build.toplevel --no-update-lock-file --no-write-lock-file
```

### Accepted pagination gaps

Accepted without change ([issue #94](https://github.com/maurerf/nixos/issues/94),
decided 2026-11-15):
- The three-minute budget does not cover `resolveSearchAreas`,
  `acquireWarmPage` or a hung `page.evaluate`. The last is bounded only by
  Puppeteer's protocol timeout.
- An empty one-card Immowelt batch cannot be told apart from a delisted card.
  It is counted as missing, and the page can still be reported complete. In
  batches of 30, a one-card batch only arises when the page's unique listing
  count leaves a remainder of one (1, 31, 61 or 91).
- ImmoScout counts only `EXPOSE_RESULT` items against `totalResults`. In the
  14:50 UTC run on 2026-11-15 the two agreed (58 of 58, complete), so the fix was
  not needed.
- `AbortSignal.timeout`, the in-page deadline and request pacing have no
  offline test.

### Evidence and proposed job settings

Operator-run read-only diagnostics on 2026-11-13 found that about 38.2% of the
saved Fredy polygon lies outside the provider searches' 5 km radius (grid estimate;
not a percentage of listings missed). With 2.5–4 rooms and €1,500 warm rent fixed,
ImmoScout's complete polygon search had 15 title-blacklist survivors at 40–80 m²,
and 22 at 40–90 m². Seven of the latter were beyond the first 50 raw results.
The 40–90 m² polygon search returned 73 raw listings; 50 had swap terms in their
titles. Explicitly adding or removing `exclusioncriteria=swapflat` returned the
same 73 IDs. The deployed translator already supplied that exclusion, so relying
on it did not solve the page coverage gap.

Immowelt's original search returned 227 raw cards and 14 blacklist survivors;
two survivors were beyond its first 100 results. The polygon plus 40–90 m²
probe fetched only 300 of 344 results and found at least 15 survivors, eight
beyond the first page. Those polygon counts are lower bounds. Counts are dated
available candidates, not daily arrivals, guaranteed new rows or unique flats
across both portals. Provider polygon membership can differ from Fredy's
address-based geocoding.

After accepting the patched service, preview and save provider URLs using the
existing polygon directly, 40–90 m², 2.5–4 rooms and €1,500 warm rent, sorted newest
first. Keep Fredy's existing blacklist and area filter; keep job-level minimum
rooms 2.5, minimum size 40 and maximum price 1500. Two-room flats are explicitly
outside the user's requirements. Exact polygon URLs belong in private job state,
not Git. Listings previously stored and hidden remain known; changing the search
does not automatically reconsider them or resend notifications. Review those
separately, without clearing deduplication history. The URLs were saved on
2026-11-15, with drawn portal polygons instead of the saved one; see
[provider URLs and usage reporting](#2026-11-15-provider-urls-and-usage-reporting).

### Activation and recovery

The pagination-only image was temporarily activated with explicit approval on
2026-11-14 after a consistent Fredy backup. The public UI and mail checks
passed. The persistent selected NixOS system remained the older version; a
reboot would select it. The first two Immowelt searches after test activation
returned HTTP 403. Retained debug logs show 48 Immowelt search refusals
during the prior 48 hours, before pagination was deployed. Those failures
explain why live Immowelt pagination has not yet been accepted.

As of the 16:45 UTC diagnostic, the browser fix had not been activated. It was
temporarily activated with explicit approval at about 17:11 UTC the same day,
after a new protected Fredy backup; the selected persistent system again
remained the older version (source: operator record in
[PR #72](https://github.com/maurerf/nixos/pull/72)). The first saved-job run
fetched ImmoScout 48/48 and 200 unique Immowelt cards of a reported 222: the
third Immowelt search request returned HTTP 403, so coverage was logged as
incomplete and the first 200 cards were retained. Fredy reached its 448 MiB
memory limit and used about 122 MiB of the 128 MiB swap allowance without an
OOM kill; no mail-service outage was observed. This restored Immowelt ingress
but is not acceptance: full pagination, memory headroom over later scheduled
runs and a permanent switch remain open, and the temporary test grants no
approval for one.

The next scheduled run of that image, at 18:10 UTC (sampled read-only every ten
seconds), repeated the result: 200 Immowelt cards kept, then HTTP 403 on the
third page. That image logs a refused search and a refused card request alike
as `search HTTP`, so which request was refused is not established. During the
roughly 40 seconds of browser activity the container stayed at its 448 MiB
memory limit and 128 MiB swap allowance, with 118 of 256 PIDs, about 51,000
further memory-limit events and no OOM kill; the host kept about 1.5 GiB
available, with no failed units and an empty mail queue. The two error-level
rows of the 17:11 run were `Overpass API error: 502 Bad Gateway`. In response
the candidate raises the container limit to 640 MiB memory, keeping 128 MiB
swap (`--memory-swap=768m`); the 448 MiB figures in the sections below are the
earlier trial budget. The raised limit and the changed card handling are
untested in production until a further approved test activation.

That candidate (commit `2c67060`) was test-activated with approval at 19:19 UTC
after a further protected backup; the selected persistent system stayed the
older version. Its startup run again kept 200 Immowelt cards and logged
`search HTTP 403`, which with the new labels identifies the third search
request, not a card request, as the refused one. No missing-card warning was
logged. Within the first minute the container reached the 640 MiB limit and the
full swap allowance with about 9,000 memory-limit events (against 41,000 to
51,000 per run before), a PID peak of 213 of 256 and no OOM kill.

The refusal was not tied to the third page. The two scheduled runs of that
image kept 100 listings at 20:20 UTC (`Execution context was destroyed`) and
130 at 21:20 UTC (`cards HTTP 403`). A two-page candidate (commit `25a040d`)
was test-activated with approval at 22:05 UTC after a further protected
backup. Its startup run and all eleven scheduled runs up to 2026-11-15
09:07 UTC, with no restart in between, were refused during the second page:
nine at the second search request and three at a card request, keeping 100
or 130 listings (source: operator-supplied container log, 2026-11-15). Each
refusal skipped that run's remaining Immowelt requests, so no run of either
candidate reached Immowelt detail requests unrefused. The limit therefore
looks like a per-session request allowance of about one search page with its
card batches; it neither recovered nor tightened overnight. Across the
`2c67060` container's three runs the 640 MiB limit was hit about 11,700 times
in total, with no OOM kill. In response the candidate limits Immowelt to one
page.

That candidate (commit `4edb8ea`) was test-activated with approval at
09:50 UTC on 2026-11-15 after a further protected backup
(`fredy-preonepage-*`); the selected persistent system stayed the older
version. Its startup run and the scheduled runs at 11:50, 12:50 and 13:50 UTC
each logged only `search incomplete: page limit; keeping 100 listings`, with
no refusal and no skipped Immowelt requests (the 10:50 UTC run fell outside
the supplied log window). At 13:59 UTC the container had no OOM kill and no
restart, no unit had failed and the mail services were active (sources:
operator-supplied container log and a read-only check). Whether the detail
requests returned data, and how many listings were stored, was not examined.
This meets the agreed bar for the test; a permanent switch still needs its
own approval.

With approval, the operator switched permanently on 2026-11-15 to `main` at
`89517b5a936fa510330182b729600b39efc85f3a`, built natively on `desktop-pc`
and on the VPS to
`/nix/store/nzjn3c3r1yx4q5sn6j2gg8vj5135w2w1-nixos-system-nixos-vps-26.05.20260925.f5c082a`.
A read-only check at 14:07 UTC found the active and selected closures equal to
that path, selected generation 26 and configuration revision `89517b5`. The switch did
not restart Fredy (running since 09:50:25 UTC, no restart). No unit had
failed; `postfix`, `dovecot`, `rspamd`, `redis-rspamd`, `nginx`, `sshd`,
`kresd@1` and `podman-fredy` were active; the UI returned HTTP 200, the mail
queue was empty and 24 GB of disk were free.
Generation 25, the system before PR #72, is retained for
[generation recovery](deployment.md#generation-recovery). The operator had
taken a new full Vultr snapshot first (see
[snapshot recovery](vps-recovery.md#snapshot-recovery)). Not done at the
switch: a reboot into the new generation, external IPv6 and TLS/DNS checks,
and examining stored listings and Immowelt detail data (source: operator
record in [PR #72](https://github.com/maurerf/nixos/pull/72)).

The Fredy backups retained after this switch are listed under
[Fredy backup and recovery](vps-recovery.md#fredy-backup-and-recovery).

Before any further activation, follow
[deployment](deployment.md#deployment)
and [backup preparation](vps-recovery.md#fredy-backup-and-recovery), build both VPS
outputs on Linux, and obtain approval for the concrete committed candidate.
Allow disk space for the Nix base/derived archives and Podman's loaded image; this
uses more disk than a registry-only declaration. Build outside the mail VPS where
possible. Check free bytes/inodes before transferring or loading it.

After activation, confirm the loaded image tag, health and tini; observe one
normal job with the saved searches, then the proposed URLs. Record unique fetched
counts, reported totals, completeness warnings, stored/hidden rows and actual
Telegram receipts. Check parent/child cgroup memory, swap, PIDs and mail services
across that run. The first wider search can notify about older unseen flats.
Do not infer failure from fewer posts than fetched listings.

The patch changes no schema. Recovery is the retained pre-change generation and
original image, followed by health/mail/search checks. If job URLs were also
changed, restoring the generation does not restore them: keep their original
values privately and restore them separately if desired. New listing history
remains in the database; do not restore an old database merely to undo this code
patch.

## 2026-11-15 provider URLs and usage reporting

The operator edited the saved job and a setting in the UI on 2026-11-15, without
a restart, after an online database backup (`fredy-prejobedit-20261115T142925Z`;
see [job and setting edits](vps-recovery.md#job-and-setting-edits)). The
previous provider URLs are kept in a root-only file next to that backup. Sources:
operator-run read-only queries and container log, an operator browser check of
both URLs, and an offline agent check of their parameters against Fredy 29.2.1's
translators, unless noted.

Before the edit the database held 78 ImmoScout rows (40 deleted by the
operator) and 59 Immowelt rows (48 deleted); neither provider had stored a row
since the one-page test activation at 09:50 UTC, because every listing it found
was already known. 3 of the 11 Immowelt rows stored on 2026-11-14 had
descriptions longer than the 500-character card limit, so their exposé requests
had succeeded.

**Usage reporting** is off: the operator set `analyticsEnabled` to false in
the UI's admin system settings. In Fredy 29.2.1 (`lib/services/tracking/Tracker.js`,
`lib/services/crons/tracker-cron.js`) it gated an 8-hourly report to the upstream project (device ID,
platform, version, providers, adapters) and a per-job price report (median
€/m² of stored listings, sample size, price band). It had logged
`Error sending tracking data to /main. Status: 500`. It also gates the
`DETECTED_AS_BOT` events of Immowelt's `reportFailure`. The setting reads
false in the database; the first report time after the change, 16:00 UTC, had
not yet been checked in the log when this was written.

**Provider URLs.** The one job, with ImmoScout and Immowelt, now searches a polygon
drawn on each portal, with 2.5–4 rooms, 40–90 m² and at most €1,500 warm rent
(ImmoScout's `calculatedtotalrent`, Immowelt's `Warmrent`), flats only. Fredy's
ImmoScout provider forces the newest-first order itself (`sortByDateParam`); the
Immowelt URL carries it. Both browser drafts lacked the four-room maximum,
the Immowelt draft included houses, and the ImmoScout draft carried `bbox`
(which Fredy would have dropped with a warning on every run) and
`enteredFrom`; all were fixed before saving. The two portal
polygons were drawn separately. Neither covers the job's own area filter:
judged by bounding boxes, both miss roughly the eastern 1.2 km and ImmoScout also
about 2 km in the north. The operator accepted that gap (border flats are not the
focus). Fredy's area filter, blacklist and
[job-level filters](#evidence-and-proposed-job-settings) are unchanged.

The first scheduled run with the new URLs (14:50 UTC) logged no refusal; Immowelt
logged its expected page-limit warning:

| Provider | Reported total | Fetched | After provider filters | New stored | Details |
| --- | ---: | ---: | ---: | ---: | --- |
| ImmoScout | 58 | 58, one page, complete | 11 | 4 | 4 of 4 with full description |
| Immowelt | 382 | 100, page limit | 5 | 2 | 1 of 2; the other exposé failed with `Execution context was destroyed` |

So Immowelt detail requests do work at one page, though not reliably. The
ImmoScout website showed 352 results for the same search. A read-only
`search/total` request from `desktop-pc`, built as Fredy builds it, returned
`totalResults` 60 and `comingSoonTotalResults` 271, with or without
`exclusioncriteria=swapflat`. Fredy fetches only the regular result list, so
ImmoScout's "coming soon" listings are not searched. The operator accepted
that. The run also logged three `Overpass API error: 502 Bad Gateway` lines and
one Telegram `sendPhoto` failure for which Fredy logged that it used its fallback; the
container had no OOM kill and no restart.

## Current resource budget

As of the permanent switch of 2026-11-15, and in its test activations from
2026-11-14, the [module](../modules/fredy.nix) declares 640 MiB memory plus 128 MiB swap (`--memory-swap=768m`) and 256 PIDs.
The [original trial budget](#original-2520-candidate-and-measured-budget)
of 448 MiB, and its headroom reasoning for the 964 MiB host, are kept below as a
record. The operator has since upgraded the VPS to the provider's 2048 MB plan
(operator-reported 2026-11-15; done after the 2026-09-29 baseline and, given
the last boot, by 2026-10-04; exact date not recorded). Read-only samples on
2026-11-14 and 15 showed 1970 MiB RAM and 1023 MiB swap. The declared 640 MiB
leaves a nominal 1330 MiB of physical RAM for mail and the host, against
516 MiB under the original budget. Observed during and between Fredy runs:
about 1.5 GiB available, 440 to 530 MiB of host swap in use, no failed units
and an empty mail queue. These are samples over one day, not a measured budget
under mail load.

## Original 25.2.0 candidate and measured budget

The candidate uses Fredy [25.2.0](https://github.com/orangecoding/fredy/releases/tag/25.2.0),
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

The trial caps the whole Fredy container, including browser children, at
448 MiB memory plus at most 128 MiB swap (`--memory-swap=576m`), half of the
single CPU and 128 PIDs. This leaves a nominal 516 MiB of physical RAM for
mail and the host; Rspamd's observed unit peak was about 208 MiB. The peak
could coincide with Fredy's peak, so this budget may still cause host swap or
Fredy browser failures. Three failures within ten minutes stop systemd retries.
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
do not run a heavy build on the 1 GiB mail host to satisfy a build check.

## 2026-10-08 search and notification investigation

The VPS was running Fredy 29.2.1 at GHCR index digest
`sha256:45fc1d36f8c79151f66c981c1aacde0f9d19409ffac0d9d084dcd2acecc9ea18`,
activated on 2026-10-04 from source revision
`8ca2b36774066a64362084179c94227eb3400424`. The container was healthy,
with zero systemd restarts and no observed PID exhaustion or OOM kill. Its limits
were 256 PIDs, 448 MiB RAM and 128 MiB swap. This PR restores the deployed
image digest and PID limit to `modules/fredy.nix`; `main` still declared 25.2.0
and 128 PIDs when this investigation began. The original 25.2.0-to-29.2.1
activation applied database migrations, so reverting only the image or NixOS
generation would not restore the earlier database schema. The operator made a
protected copy of both Fredy state directories before the October 4 upgrade;
follow [Fredy recovery](vps-recovery.md#fredy-backup-and-recovery) and obtain
fresh deployment approval before any further VPS activation.

The operator reported roughly one to three Telegram posts daily. Read-only
diagnostics found one enabled job, an attached Telegram channel and hourly
searches. Its Fredy spec filter required at least 2.5 rooms and 40 m², at most
€1,300, plus a blacklist and an area polygon. On 2026-10-07 UTC, debug logs
recorded the following **repeated per-run observations**, not unique listings:

| Provider | Observations after initial provider filtering | Spec rejects | Already known | New stored |
| --- | ---: | ---: | ---: | ---: |
| ImmoScout | 944 | 745 | 199 | 0 |
| Immowelt | 319 | 195 | — | 1 |
| Kleinanzeigen | 49 | 22 | — | 6 |

Five of the six new Kleinanzeigen rows on October 7 were outside the saved
polygon and did not become visible notifications. The operator's local-day
Telegram counts were one on October 6, three on October 7 and one by the
October 8 check. Those counts were consistent with stored, area-eligible rows
after accounting for the Berlin/UTC day boundary. The operator had also hidden
some other listings manually; the hidden flag alone cannot identify why every
historical row was hidden. No recent Telegram send error explained the low
volume; three Telegram 429 errors were confined to October 3–4. Search results
and notifications are distinct counts.

Kleinanzeigen failed to render a page in 15 of 23 October 7 runs, timing out
while waiting for the `body` element and returning zero results. ImmoScout and
Immowelt search requests were functioning in the retained logs. During an
October 8 scheduled search, the container reached roughly 448 MiB RAM and
128 MiB swap with high memory pressure; a Kleinanzeigen `body` timeout followed.
The same resource pressure recurred in two manual runs. The timing is a strong
correlation, not proof that memory pressure caused the browser timeout. No OOM
kill or mail-service outage was observed.

The saved ImmoScout search had no upstream price or size restriction and only a
four-room maximum. Fredy 29.2.1 fetches one ImmoScout mobile API page, sorted
newest first, with no pagination. Controlled read-only requests returned exactly
50 raw listings on page 1 and another 50 on page 2. Among 35 novel page-1
listings after the provider blacklist, none passed the Fredy spec filter;
rooms and price caused most rejections. Two of 28 novel page-2 listings passed
the spec filter, although their area eligibility was not checked. This shows a
first-page coverage gap; it does not mean all portal results were eligible or
that those two would have produced notifications.

The operator reported saving narrower provider URLs with 2.5–4 rooms, 40–80 m²
and €1,300 maximum where the portals support those terms, then selecting
newest-first sorting. The final saved URLs were not independently re-read.
The provider price semantics differ: the tested ImmoScout URL uses calculated
total rent, the Immowelt URL uses warm rent, and Kleinanzeigen's price field is
basic rent. Fredy's own spec and area filters still apply. In the 17:07 CEST
manual run, Fredy stored two ImmoScout and two Immowelt listings, and all four
arrived in Telegram; Kleinanzeigen timed out. A 17:11 repeat stored no new
listings. After the operator removed Kleinanzeigen in the UI, an apparent 17:22
scheduled run still used the old three-provider job, apparently loaded around
the edit.
The 17:26 manual run used only ImmoScout and Immowelt, checked three already
known listings from each, logged no provider errors and finished in about 22
seconds. No new Telegram posts were expected from that final run. This verifies
the saved two-provider configuration. No live resource sample was taken during
that short run, so its peak memory pressure remains unknown.

Debug ZIP download worked in Safari. The reported Firefox download failure was
not reproduced with a status/console trace and remains unexplained. Keep debug
ZIPs and database extracts outside Git because logs and settings can contain
private search details or credentials. The debug log has a 5 MiB rolling cap;
the rootful Podman log has a 10 MiB cap. The unprivileged `fdm` SSH account
cannot read the rootful Podman log or database; the operator ran the narrowly
scoped read-only diagnostics with sudo in their own terminal and kept the
password private. If the issue recurs, collect a current ZIP and compare
per-provider runs, filter rejects, new rows, Telegram receipts,
and the live container cgroup's memory/swap/pressure. Recheck the job's saved
provider list before attributing a run near an edit to the new configuration.

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
